#!/bin/CSPperl
# Written by Gregory Danenebrg, 12/2011
# Populating /etc/hosts with all nodes in cluster and creates authorized ssh connection in cluster
# Version 1.0

$|=1;   # resync the used file without buffering

use strict;
use XML::LibXML;
use Getopt::Long;

use lib '/usr/cti/lib/CSPbase';
require 'csp_functions.pl';
require 'csp_globals.pl';

# CSP ENV VARIABLES
my $CSPBASE_DIR		='/usr/cti/apps/CSPbase';
my $NETWORK_TOOL	="$CSPBASE_DIR" . "/csp_networking.pl";
my $SSH_TOOL		="$CSPBASE_DIR" . "/csp_ssh_pkauth.pl";
my $MODULE_NAME		="SEM-SIL-SSH";
$CSP::LOGDIR		="/var/cti/logs/swp";
my $LOG				="$CSP::LOGDIR/$MODULE_NAME/$MODULE_NAME.latest.log";

my $CONF_TOOL_DIR	="/usr/cti/conf/autoconf";
my $UnitGroupFile	="UnitGroup.xml";

my $xmlName			='/var/tmp/SMSC-user.xml';

my ($help,$groupName,$UnitGroupDir,$UnitGroup,$netName,$user,$passwd);

#holds cluster nodes and their ip's
my %NodeList=();

CSP::openlog($MODULE_NAME);
&Usage(0) if ! @ARGV;

if  ( !GetOptions ( 'group=s'=>\$groupName, 'unitgr_dir:s'=>\$UnitGroupDir, 'net_name:s'=>\$netName, 'user:s'=>\$user, 'pass:s'=>\$passwd, 'h|help|usage' => \$help ) ) { 
	&Usage(1,"Missing / Wrong CLI usage");
}

&Usage(0) if $help;

$UnitGroupDir=$UnitGroupDir || $CONF_TOOL_DIR;
$UnitGroupDir =~ s/\/$//;
$UnitGroup="$UnitGroupDir" . "/" . "$UnitGroupFile";

#By default trust ssh will be created on Data network
my $net=$netName || "Data";

##############################
#   MAIN
##############################

&checkPrereq();
&fillNodeList();
&setEtcHosts();
if ( "$user" ) {
	if (! "$passwd"){
		CSP::cspabort(1,"user option should be supplied with appropriate password");
	}
	&setSilSSH();	
} else {
	CSP::cspabort(1,"cmd arguments dont include user option,therefore ssh trust between nodes will not be established");
}

CSP::closelog();
exit 0;
##############################
# END 
##############################

##############################
sub fillNodeList () {
#Getting all attributes for all nodes
##############################
 	
	my $parser =XML::LibXML->new();
	my $tree   =$parser->parse_file($UnitGroup) or CSP::cspabort(1,"Failed to open $UnitGroup, $!");
	my $root   =$tree->getDocumentElement;
	
	my $searchPath="/UnitGroup/Physical[\@GroupName=\"$groupName\"]/UnitInstance";
	
	if (! scalar($root->findnodes($searchPath)) ) {
		CSP::cspabort(1,"Failed to find $groupName group in $UnitGroup");
	}
	
	foreach my $node ($root->findnodes($searchPath) ) {
		my $UnitName =&cleanString($node->getAttribute('UnitName'));
		my $Hostname =&cleanString($node->getAttribute('Hostname'));     
		my $Mngname  =&cleanString($node->getAttribute('Mngname'));     
		my $DataIp   =&cleanString($node->getAttribute('DataIp'));     
		my $MngIp    =&cleanString($node->getAttribute('MngIp')); 
		
		($NodeList{$UnitName}{'Hostname'})=$Hostname =~ /^(.*?)\./;
		($NodeList{$UnitName}{'Mngname'}) =$Mngname  =~ /^(.*?)\./;
		$NodeList{$UnitName}{'DataIp'}    =$DataIp;
		$NodeList{$UnitName}{'MngIp'}     =$MngIp;
	}
}

##############################
sub setSilSSH () {
#creates silent ssh between nodes
#the default network is Hostname(DataIp)
##############################

	if (! -x $SSH_TOOL ) {
		CSP::cspabort(1,"Failed to find executable $SSH_TOOL");
	}
	
	my $rc=system("id $user >> /dev/null");
	if ($rc != 0) {
		CSP::cspabort(1,"$user does not exist on this server");
	}
	
	&createXMLSSH();
	
	#no need to perform ping test, csp_ssh_pkauth.pl already does it with Net::Ping	
	#&getSomeRest(); 
	my $cmd="$SSH_TOOL --enable --xml $xmlName";
	
	&exeCSPCMD($cmd);
	
}


##############################
sub setEtcHosts() {
#populate /etc/hosts with available data
##############################
	
	foreach my $node ( sort { $a cmp $b } keys %NodeList ) {
		
		my ($Mngname,$Hostname);
		
		if ( "$NodeList{$node}{'DataIp'}" ) {
			my $cmd="$NETWORK_TOOL --action=set_host --hostname=$NodeList{$node}{'Hostname'} --ip=$NodeList{$node}{'DataIp'}";
			exeCSPCMD($cmd);
		}
		
		if ( "$NodeList{$node}{'MngIp'}" ) {
			my $cmd="$NETWORK_TOOL --action=set_host --hostname=$NodeList{$node}{'Mngname'} --ip=$NodeList{$node}{'MngIp'}";
			exeCSPCMD($cmd);
		}
		
	}
}

##############################
sub createXMLSSH () {
#Creates input xml for csp_ssh_pkauth.pl tool
##############################
 
	my ($sshNet);
	
	#currently it's hardcoded. later will be more generic
	if ($net eq "Data") {
		$sshNet='Hostname';
	} elsif ($net eq "Mng") {
		$sshNet='Mngname';
	} else {
		CSP::cspabort(1,"$net is not supported in this version");
	}
	
	my $doc = XML::LibXML::Document->new('1.0');
	my $root = $doc->createElement("xml");
	
	my $usertag = $doc->createElement("user");
	$usertag->appendTextNode($user);
	$root->appendChild($usertag);
	
	my $passtag = $doc->createElement("password");
	$passtag->appendTextNode($passwd);
	$root->appendChild($passtag);
	
	my $hostlist = $doc->createElement("hostlist");
	$root->appendChild($hostlist);
	
	foreach my $node ( sort { $a cmp $b } keys %NodeList ) {
		my $host = $doc->createElement("host");
		$host->appendTextNode($NodeList{$node}{$sshNet});
		$hostlist->appendChild($host);
	}
	
	$doc->setDocumentElement($root);
	
	open(XML, "> $xmlName") or CSP::cspabort(1,"Failed to open $xmlName, $!");
		print XML $doc->toString(1);
	close(XML);
	
}

##############################
sub exeCSPCMD () {
#execute csp tools, no need with eval
##############################
	
	my ($cmd)=@_;
	
	my $rc;
	&message_log("Executing $cmd");
	
	$rc=system($cmd);
	if ( $rc != 0) {
		CSP::cspabort(1,"Failed executing the command: $cmd");
	}
	
}

##############################
sub checkPrereq () {
#make sure we have all needed stuff for script execution
##############################

	$groupName=&cleanString($groupName);
	$netName  =&cleanString($netName);
	
	if (! "$groupName") {
		&Usage(1,"You have to provide group name from UnitGroup.xml");
	}
	
	#if (! "$netName") {
	#	print "ERROR: You have to provide network name to parse UnitGroup.xml correctly\n";
	#}

	if (! -f $NETWORK_TOOL ) {
		CSP::cspabort(1,"Failed to find $NETWORK_TOOL tool");
	}

	if (! -f $UnitGroup ) {
		CSP::cspabort(1,"Failed to find $UnitGroup");
	}
	
}

##############################
sub getSomeRest () {
# sleep a few seconds to prevent possible errors during silent ssh string	
##############################
	
	my $host=`hostname`;
	
	if ($host =~ /.*(\d)/) {
		my $tts=$1*2;
		&message_log("Sleeping for $tts seconds");
		sleep($tts);
	}
}

##############################
sub cleanString () {
##############################
	my $data=$_[0];
	chomp $data;
	$data=~s/\s$//;
	$data=~s/^\s+//;
	return $data;
}

##############################
sub message_log(){
##############################
# due to SWIM installation we want STDOUT on console

	my ($mess)=@_;
	
	CSP::csplogger('info',"$mess","console");
}

##############################
sub Usage () {
##############################

	my ($status,$mess)=@_;

	print <<"EOD";
	
	
Usage: 
--------
	$0 [--group] [--net_name] [--user] [-pass]
	
	--group		: Group name is it appears in UnitGroup.xml
	
	Silent SSH parameters
	---------------------
	--net_name	: OPTIONAL parameter.
			  Identifies on which network trust ssh should be established
			  The default is Data (meaning trust ssh will be created over DataIp addresses)
			  
			  Possible values: Data,Mng
			  
			  Hostname <-> DataIp
 			  MngName  <-> MngIp
 			  
	--unitgr_dir	 : OPTIONAL parameter.
			   The default UnitGroup.xml is taken from /usr/cti/conf/autoconf folder
			   Directory where alternative UnitGroup.xml located
			 
				
	--user		: OPTIONAL parameter. 
			  Used to identicate for which username trust ssh should be established
			  
	--pass		: OPTIONAL parameter. 
			  Used along with --user.
	
Example:
--------
	Updates /etc/hosts with all nodes listed under group in UnitGroup.xml
	$0 --group=SEM_Group
	
	Updates /etc/hosts with all nodes listed under group in /var/tmp/UnitGroup.xml
	$0 --group=SEM_Group --unitgr_dir=/var/tmp
	
	Updates /etc/hosts as above and creates trust ssh between nodes in group
	$0 --group=SEM_Group --net_name=Hostname --user=smsc -pass=test --unitgr_dir=/var/tmp
	
	
EOD

	if ( $status ) {
		CSP::cspabort(1,"$mess. Examine -help option");
	} else {
		CSP::closelog();
		exit 1;	
	}

}
