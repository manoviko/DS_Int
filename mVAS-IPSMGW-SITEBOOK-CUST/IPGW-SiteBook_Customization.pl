#!/bin/CSPperl

use strict;
use XML::LibXML;
use Log::Log4perl;
use Getopt::Long;

my $SYSTEMNAME=$ARGV[0];
my $PRODUCTNAME=$ARGV[1];
my $unitGroup="/usr/cti/apps/omap_maint/sitebook/config/$SYSTEMNAME/UnitGroup.xml";
my $systemXML="/usr/cti/apps/omap_maint/sitebook/config/SystemList.xml";

my ($logger);
my @grArr;
my %mdHash=();
my %sysHash=();

my $groupSuffix="_Group";
my $sbCli="/usr/cti/apps/sitebook/catalinaBase/webapps/sitebook/SiteBook_CLI.sh";
my $sbDir="/var/tmp/SiteBook/$PRODUCTNAME";
my $userPass='SBAdmin Sbm1Cmv4$';
my $sbuserUserPass='sbuser Sbm1Cmv4$';
my $toprootName="";

&Usage if $ARGV[0] =~ /help|usage/;

#####  MAIN
&init_log();
&check_prereq();
&mapUtitGroup();
&mapSystems();
&controlAASLogin("false");
&topologyCreation();
&loadMDFiles();
&assighMdToTopology();
&updateCredentials();
&controlAASLogin("true");
&topologyCreation();
&restartApp();
&startScan();



##############################
sub check_prereq() {
##############################
	
	$logger->logdie("ERROR: System Name is not found, $!") unless ( $SYSTEMNAME );
	$logger->logdie("ERROR: Product Name is not found, $!") unless ( $PRODUCTNAME );
	$logger->logdie("ERROR: $unitGroup is not found, $!") unless -f $unitGroup;
	$logger->logdie("ERROR: $unitGroup is not found, $!") unless -f $systemXML;
	
}

##############################
sub loadMDFiles() {
##############################
	
	$logger->info("Starting loading MD files");
	
	foreach my $md (keys %mdHash) {
		
		my $rc;
		
		my $cmd="$sbCli delete_metadata_file $userPass $md";
		$rc=&exeCMD("$cmd");
		if ( $rc != 0 ) {
			$logger->info("$md does not exist, nothing to delete");
		}
		
		my $cmd="$sbCli upload_metadata_file $userPass $sbDir/$md";
		$rc=&exeCMD("$cmd");
		if ( $rc != 0 ) {
			&controlAASLogin("true");
			$logger->logdie("Failed upload $md file");
		}
		
	}
	
	
}

##############################
sub assighMdToTopology() {
##############################	
	
	$logger->info("Starting to assign MD files to Topology");
	
	my $parser =XML::LibXML->new();
	my $treeUnitXml   =$parser->parse_file($unitGroup) or $logger->logdie($!);
	my $rootUnitXml   =$treeUnitXml->getDocumentElement;
	our $toprootName;
	
	foreach my $md (keys %mdHash) {
		
		my ($siteName,$rootName,$rc,$cmd,$path,$unitInst);
		
		$logger->info("Trying to assign $md to $mdHash{$md}");
		
		$path="/UnitGroup/Physical[\@GroupName=\'$mdHash{$md}\']/UnitInstance[1]";
		
		($unitInst) = $rootUnitXml->findnodes($path);
		$logger->logdie("Failed to find $path in $unitGroup") if not defined $unitInst;
		
		my $hostName = $unitInst->getAttribute('Hostname');
		$hostName =~ /^(.+?)\.(.+?)\..+/;
		$siteName =$2;
		$logger->logdie("Failed to find Site System Name for $md") if not defined $siteName;
		$logger->info("site name for $md is $siteName");	
		
		foreach my $rootNames (keys %sysHash) {
			
			$rootName=$rootNames if grep(/$siteName/,@{$sysHash{$rootNames}});
			
		}
		
		$logger->logdie("Failed to find Root System Name for $siteName") if not defined $rootName;
		
		$cmd="$sbCli update_topology_metadata $userPass Layer SiteTopology/$toprootName/$rootName/$siteName/$mdHash{$md} $md";
		
		$rc=&exeCMD($cmd);
		if ($rc != 0) {
			&controlAASLogin("true");
			$logger->logdie("Failed to update topology metadata for $md");
		}
			
	}
	
}

##############################
sub updateCredentials() {
##############################	
	
	our $toprootName;
	$logger->info("Updating topology credentials");
	
	foreach my $rootSys (keys %sysHash) {
		foreach my $sys ( @{$sysHash{$rootSys}} ) {
			
			my $cmd="$sbCli update_topology_credentials $userPass Layer SiteTopology/$toprootName/$rootSys/$sys $sbuserUserPass sftp $sbuserUserPass ssh";
			my $rc=&exeCMD($cmd);
			if ( $rc != 0 ) {
				&controlAASLogin("true");
				$logger->logdie("Failed to update credentials for $sys");				
			}
			
		}
	}
}

##############################
sub restartApp() {
##############################
	
	$logger->info("Restarting sitebook application");
	
	my $cmd="/usr/cti/apps/sitebook/bin/restart.sh";
	my $rc=exeCMD($cmd);
	$logger->logdie("Failed to restart sitebook application") if $rc != 0;
	sleep(5);
		
}

##############################
sub startScan() {
##############################

	$logger->info("Starting scanning...");
	
	my $cmd="$sbCli force_scan";
	my $rc=exeCMD($cmd);
	
	if ( $rc != 0 ) {
		&controlAASLogin("true");
		$logger->logdie("Failed to run scanning");				
	}	 	
	
}


sub mapUtitGroup() {
	
	$logger->info("Starting mapping between MD files and UnitTypes");
	
	my $parser =XML::LibXML->new();
	my $treeUnitXml   =$parser->parse_file($unitGroup) or $logger->logdie($!);
	my $rootUnitXml   =$treeUnitXml->getDocumentElement;
	
	my $path="/UnitGroup/Physical";
	foreach my $gr ( $rootUnitXml->findnodes($path) ) {
		push(@grArr,$gr->getAttribute("GroupName"));
	}	
	
	opendir(my $dh, $sbDir) or $logger->logdie("Unable to read from $sbDir");
	
	foreach my $md (readdir $dh) {
		
		next if $md =~ /^\.{1,2}$/; 
		
		my $mdSiteName;
		
		if ( $md !~ /([\w_-]+)_MD.xml/ ) {
			$logger->warn("skipping $md as it has invalid MD file name");
			next;	
		}
		
		#my $mdGroup="$1$groupSuffix";
		my $MdFile="$sbDir/$md";
		#$logger->info("####$MdFile####");
		my $mdparser =XML::LibXML->new();
		my $treeMdXml   =$mdparser->parse_file($MdFile) or $logger->logdie($!);
	  my $rootMdXml   =$treeMdXml->getDocumentElement;
	  my $path="/UnitContent";
	  my ($tag)=$rootMdXml->findnodes($path);
    $logger->logdie("Failed to find $path in $rootMdXml") if not defined $tag;
	
    my $mdGroup=$tag->getAttribute("name");
    $logger->logdie("Failed to find Name in $rootMdXml") if not defined $mdGroup;
	  
		#$logger->info("###$mdGroup###");
		
		if ( ! grep(/$mdGroup/,@grArr) ) {
			$logger->warn("$md does not match any group in $unitGroup");
			next;
		}
		
		$logger->info("$md belongs to $mdGroup");
		$mdHash{$md}=$mdGroup;		
		
	}	
	
	
	
}

##############################
sub mapSystems() {
##############################

	$logger->info("Mapping systems from SystemList.xml");
	
		
	my $parser =XML::LibXML->new();
	
	my $treeSysXml   =$parser->parse_file($systemXML) or $logger->logdie($!);
	my $rootSysXml   =$treeSysXml->getDocumentElement;
	my $SYSTEMNAME=$ARGV[0];
	
	# Get Upper(first) Root name
	our $toprootName;
	my $path="/SystemList/SystemRoot";
	
	my ($tag)=$rootSysXml->findnodes($path);
	$logger->logdie("Failed to find $path in $systemXML") if not defined $tag;
	
	$toprootName=$tag->getAttribute("SystemName");
	$logger->logdie("Failed to find Root SystemName in $systemXML") if not defined $toprootName;
	$logger->info("Root SystemName in $systemXML is $toprootName");
	
	
	my $path="/SystemList/SystemRoot/SystemRoot";

	my ($tag)=$rootSysXml->findnodes($path);
	$logger->logdie("Failed to find $path in $systemXML") if not defined $tag;
	
	#only one Root System , like Group-Site-1 ?
	my $rootName=$tag->getAttribute("SystemName");
	$logger->logdie("Failed to find Root SystemName in $systemXML") if not defined $rootName;
	$logger->info("Root SystemName in $systemXML is $rootName");		
	
	my @subSysRoot=$tag->findnodes('./SystemRoot');
	
	foreach my $subSys (@subSysRoot) {
	
		my $subSysName=$subSys->getAttribute("SystemName");
		$logger->logdie("Failed to find Site SystemName in $systemXML") if not defined $subSysName;
		$logger->info("Found Site SystemName in $systemXML: $subSysName");
		
		if ($subSysName =~ "$SYSTEMNAME" ) {
      
      push(@{$sysHash{$rootName}},$subSysName);
      
    }
	
	}	
	
}

##############################
sub topologyCreation() {
##############################
	
	$logger->info("Starting Topology Creation");
	
	my $cmd="$sbCli reflect_topology";
	
	my $rc=&exeCMD($cmd);
	
	if ($rc !=  0 ) {
		&controlAASLogin("true");
		$logger->logdie("Reflecting topology has been failed");
	}
	
}

##############################
sub controlAASLogin() {
##############################	
	
	my ($act)=@_;
	
	$logger->logdie("EnableAASLogin action should get false/true parameter") if $act !~ /true|false/;
	
	$logger->info("Setting AASLogin to $act");
	my $cmd="$sbCli update_sitebook_parameter $userPass Application EnableAASLogin $act";
	
	my $rc=&exeCMD($cmd);
	
	$logger->logdie("Updating AASLogin failed") unless $rc == 0;


	
}

##############################
sub init_log() {
##############################
	
	my $log_conf=q(
	log4perl.category = INFO, Screen
	log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
	log4perl.appender.Screen.DatePattern = MM-dd-yyyy hh:mm:ss
	log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.Screen.layout.ConversionPattern = [%d][%p][%M][%L] %m%n
	
	#log4perl.category = INFO, Logfile
	#log4perl.appender.Logfile = Log::Log4perl::Appender::File
	#log4perl.appender.Logfile = Log::Dispatch::FileRotate
	#log4perl.appender.Logfile.DatePattern = MM-dd-yyyy hh:mm:ss
	#log4perl.appender.Logfile.filename=SEM-SiteBook_Customization.log
	#log4perl.appender.Logfile.mode = append
	#log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
	#log4perl.appender.Logfile.layout.ConversionPattern = [%d][%p][%M][%L] %m%n
	);	
	
	Log::Log4perl::init( \$log_conf );
	
	$logger = Log::Log4perl::get_logger('Screen');
	
	
}

##############################
sub exeCMD() {
##############################

	my ($cmd)=@_;
	
	my ($rc,$out);
	$logger->info("Executing: $cmd");
	
	$out=qx(sh -c '$cmd' 2>&1);
	$rc = $? >> 8;
	
	$logger->info("Command output:\n $out");
	
	return $rc;
	
}

##############################
sub Usage() {
##############################

	print "\n\tThe script need 2 parameters: \n";
	print "IPGW-SiteBook_Customization.pl <System Name> <Product Name> for Example:\n";
	print "IPGW-SiteBook_Customization.pl GRE-CosGR-IPSMGW IPGW\n";
	exit;
	
}