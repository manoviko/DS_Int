#!/usr/bin/env perl
#Written by Gregory Danenberg, 08/2008
#Updated for SEM 5, 03/2012
#Populate installed_eis based on UnitGroup.xml

use strict;

###################################################################
# LIST of Applications to update in installed_eis repository     ##
# In order tp update the list, edit APP_LIST variable below      ##
###################################################################

#my @APP_LIST=qw(MGW MGW_CONSOLE TRACE_INFO TRACE_EVENTS EMAIL SELFPROV SELFPROV_CONSOLE GFT);
my @ExcludeLixt=qw(MGW_cluster SNG SNG-PROV SNGPROV ONS ONS-PROV ONSPROV GFT OMAP MDS ABG SPL MTA RegionServer SCA SCA_Editor RCS IPA SHU RSH RackID IMPA VIMPA CMS);
my @IncludeList=qw(HLRC MAP);

my $Parser="/home/smsc/autoconfig.all/scripts/parser.pl";
my $InstallEis="/home/smsc/site/config/installed_eis";
my $UnitGroup="/usr/cti/conf/autoconf/UnitGroup.xml";
my $Monitored="/home/smsc/site/config/site.monitor.config";

die "ERROR: $InstallEis does not have sufficient permissions\n" if ! -w $InstallEis;
die "ERROR: $Parser does not have executable permissions\n" if ! -x $Parser;
die "ERROR: $UnitGroup not found \n" if ! -e $UnitGroup;

my @APP_LIST=`$Parser $UnitGroup a///UnitName`;

open (MYFILE, "> $InstallEis") || die "ERROR: can not open $InstallEis, $!";

my @monitor_monitored;
my ($inst,$host,$app);

foreach $app (@APP_LIST) {
	
	chomp($app);
	
	if (scalar @IncludeList) {
		next if (!grep (/^$app$/,@IncludeList));
	} else {
		next if (grep (/^$app$/,@ExcludeLixt));
	}
	
	my @str=`$Parser $UnitGroup l/$app//InstanceName -h`;
	if ( ! @str || grep(/ERROR/,@str) ) {
		print "INFO: $app is not part of MRE monitor\n";
		next;
	}
	
	foreach my $r (@str) {
		($inst,$host)=split ('\s+',$r);
		if ( $host=~ /smsc|SMSC/ ) {
            print "INFO: $host is not part of IPSMGW product\n";
            next;
        }
		if ( $app =~ /(TRACE|TLA_NG)/ ) {
			#if ( scalar(@monitor_monitored) >= 1 ) {
			#	push @monitor_monitored, ",";
			#}
			push @monitor_monitored, "$app%$inst%TLA-NG%%$host%0";
		} else {
			print MYFILE "$app $inst $host\n";
		}
	}
}

close MYFILE;

my $monitor_monitored=join(',', @monitor_monitored);

open (IN, "+<$Monitored");
my @file = <IN>;

seek IN,0,0;

foreach (@file){
	s/monitor.monitored=.*/monitor.monitored=$monitor_monitored/g;
	print IN $_;
}
close IN;

