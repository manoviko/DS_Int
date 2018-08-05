#!/bin/CSPperl
# Written by Gregory Danenberg, 03/2012
# helps to set xml values

use XML::LibXML;
use File::Basename;
use File::Copy;
use Getopt::Long;
use strict;

my ($xml,$xpath,$value,$backup,$setNode,$help);

if  ( !GetOptions ('xml=s'=>\$xml, 'xpath=s'=>\$xpath, 'value=s'=>\$value, 'backup'=>\$backup, 'setNode'=>\$setNode, 'h|help|usage' => \$help ) ) {
	&Usage();
}

&Usage() if $help;

&Usage() if ! -f $xml;
&Usage() if not defined $xpath;
&Usage() if not defined $value;

my ($sec,$min,$hour,$nday,$nmonth,$nyear,$wday,$yday,$isdst) = localtime();
my $Date=sprintf( "%02d%02d%02d_%02d%02d%02d" , $nmonth+1, $nday, ($nyear+1900), $hour, $min, $sec);

my $xml_back=$xml."_".$Date;
if ($backup) {
	copy($xml,$xml_back) or die "Copy from $xml to $xml_back failed: $!";	
}


my $parser =XML::LibXML->new();
my $tree   =$parser->parse_file($xml) or die $!;
my $root   =$tree->getDocumentElement;

my ($node)=$root->findnodes($xpath);
if ( ! $node ) {
	print "ERROR: Failed to find $xpath in $xml\n";
	exit 1;	
}

if ($setNode) {
	$node->setName( $value );
} else {
	if ( $xpath !~ /\@\w+$/ ) {
		my $nodeText=$node->localname;
		my $tmp=XML::LibXML::Element->new($nodeText);
		$tmp->appendText($value);
		$node=$node->replaceNode($tmp);
	} else {
		$node->setValue($value);	
	}
}

		
open (NEWONS, "> $xml") or die "ERROR: Failed to write into $xml...";
	print NEWONS $tree->toString(1); 
close (NEWONS);


sub Usage() {

	print "\n\tUsage: $0 [--xml] [--xpath] [--value] <--setNode> <--backup>\n";
	print "\n";
	exit 1
	
}
