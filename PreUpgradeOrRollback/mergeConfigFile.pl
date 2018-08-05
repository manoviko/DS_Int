#!/bin/CSPperl
# The script will merge property/value files, like middleware.config
# old values overwite default vaules in file from kit 

use File::Copy;
use strict;
$|=1; 

die " USAGE: $0 [new .config file] [old .config file]\n" if scalar @ARGV < 2;
my $newFile=$ARGV[0];
my $oldFile=$ARGV[1];

die "ERROR: Failed to find $newFile, $!" if ! -f $newFile;
die "ERROR: Failed to find $oldFile, $!" if ! -f $oldFile;

my %oldParams=();

print "INFO: Starting to build merged $newFile based on $oldFile\n";

open (OLD,"$oldFile") or die "ERROR: Failed reading $oldFile, $! \n";
	
while (my $line=<OLD>) {
	
	#$line =~ s/\s+//g;
	next if $line =~ /^\s*#/;
	next unless length $line;
	
	my ($param,$val)=split(/=/,$line);
	chomp($val);
	
	$oldParams{$param}=$val;
	 
}
close(OLD);

open(TMP,">$newFile.tmp") or die "ERROR: Failed writing to $newFile.tmp, $! \n";
open(NEW,"$newFile") or die "ERROR: Failed opening $newFile, $! \n";

while (my $line=<NEW>) {
	
	if ( $line =~ /=/ && $line !~ /^\s*#/ ) {
		chomp($line);
		my ($param,$val)=split(/=/,$line);
		#$param =~ s/^\s+//g;
		#$val =~ s/^\s+//g;
		if ( exists $oldParams{$param} ) {
			if ( $oldParams{$param} ne $val ) {
				print "INFO: $param=$val will be replaced with old value: $oldParams{$param}\n";
				print TMP "$param=$oldParams{$param}\n";	
			} else {
				print TMP "$line\n";
			}
		} else {
			print TMP "$line\n";
		}

	} else {
		print TMP "$line";
	}
	
}


close(NEW);
close(TMP);

copy("$newFile.tmp","$newFile") or die "ERROR: Failed to copy $newFile.tmp into $newFile, $!\n";
unlink("$newFile.tmp");