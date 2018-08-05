#!/usr/bin/env perl
# Written by Gregory Danenberg, 11/2011
# The script replaces "Version=_VERSION-_BUILD" pattern in SWIM CAF files

use strict;
use warnings;


die "Usage: $0 COMPONENT_FOLDER VERSION STF" unless (@ARGV == 4);

my $COMP=$ARGV[0];
my $VER=$ARGV[1];
my $STF=$ARGV[2]; 
my $view=$ARGV[3];

#system ("ct lspriv | grep -v checkedout | xargs rm -rf");


if ( ! -d $COMP ) {
	print "ERROR: I cannot see $COMP directory...\n";
	exit 1;
}

#if ( $VER !~ /(\d\.){3}\d/ ) {
#	print "ERROR: VERSION parameter should be 4 digit number, e.g. 5.0.0.0\n";
#	exit 1;
#}

if ( $STF !~ /[\d\.]/ ) {
	print "ERROR: STF parameter has incorrect format...\n";
	exit 1;
}

print "INFO : Version name will be: $VER-$STF\n";

my @CAFS=`find $COMP/ -name \"*-CAF.xml\" -type f`;

foreach my $caf (@CAFS) {
	
	chomp($caf);
	print "INFO : Working on $caf\n";	
	local($^I, @ARGV) = ('.bak', $caf);
	my @checko = `cleartool co -nc $caf` ;
	while (<>) {
		
		s/Version=\"_VERSION-_BUILD\"/Version=\"$VER-$STF\"/;
		print;
	}
} 

system ("cleartool lspriv | grep -v checkedout | xargs rm -rf");

print `whoami`;
print `sudo su - root <<EOF

cd /view/$view/vob/CGM/SWIM-KIT
cp -rf $COMP /mnt/ums_cm/CM/swim_kits/.
mv /mnt/ums_cm/CM/swim_kits/$COMP /mnt/ums_cm/CM/swim_kits/$COMP\_$VER\_$STF

exit

EOF`;


system ("~/MRE-ENV/ci_unco_all.pl -unco");
