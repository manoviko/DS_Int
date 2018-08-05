#!/bin/CSPperl
$|++;
use strict;
no strict 'refs';
use English;
use XML::LibXML;
use Getopt::Long;
use lib "/usr/cti/lib/CSPbase";
require "csp_globals.pl";
require "csp_functions.pl";
use Switch;
use Data::Dumper;

$CSP::LOGLEVEL="INFO";
my $MODULE_NAME="Administration-Utilities";
my $PACKAGE_NAME="CSPbase-AU-Bin";
my $LOG_PREFIX="Create NetApp MNICS:";
my $HOSTNAME=`hostname`;
chomp $HOSTNAME;

my $dtdFile="/usr/cti/conf/swp/networking.dtd";
my $HAnetAppFile;
if ( -f "/usr/cti/conf/swp/HA/ha_defaultSG.xml" ) {
	$HAnetAppFile="/usr/cti/conf/swp/HA/ha_defaultSG.xml";
} else {
	print "ERROR - Invalid paramter: ha_defaultSG.xml does not exists under /usr/cti/conf/swp/HA/ or non readble\n";
	exit 1;
}
my $newFile="${HAnetAppFile}.$$";
my $etcNetwork="/etc/sysconfig/network-scripts/";

if ( ! -f $dtdFile ) {
	print "ERROR - Invalid paramter: dtd file [ $dtdFile ]  does not exists or non readble\n";
	exit 1;
}

open (DTD,"<$dtdFile") or die "ERROR - Cant open DTD file [ $dtdFile ]";
my %devices;
my @devices;
while (<DTD>) {
	chomp;
	if ( $_ !~ /^\<\!ENTITY/ || $_ !~ /_device\s/i) {
		next;
	}
	$_=~m/\s(\w+_device)\s+"(.+)"/i;
	my $dev=$1;
	my $dev_name=$2;
	print "INFO - Found device [ $dev ] with value [ $dev_name ] . Validating that device is truely defined on the system\n";
	my $devFile="${etcNetwork}/ifcfg-${dev_name}";
	if ( ! -f $devFile ) {
		print "WARN - Device file [ $devFile ] for device [ $dev ] does not exist on the system. Skipping.\n";
		next;
	}
	$devices{$dev}="${dev_name}";
	push(@devices,$dev);
}
close DTD;

if ( ! @devices || scalar(@devices) == 0  ) {
	print "ERROR - Failed to get device from DTD file [ $dtdFile ]\n";
	exit 1;
}

print "INFO - Now that we have the devices i will try to append the MNIC nodes to the Serve Sercive Group in the XML file [ $HAnetAppFile ]\n";

my $parser = XML::LibXML->new();
my $HADoc = $parser->parse_file($HAnetAppFile);
if ( ! $HADoc ) {
	print "ERROR - Failed to parse HA NetApp document [ $HAnetAppFile ]\n";
}
my @groupNode = $HADoc->findnodes("//configuration/group[name='Server']");
my $groupNode = shift(@groupNode);

foreach my $device (keys %devices) {
	my ($devName)=split("_",$device);
	my $mnic="${devName}_MNIC";

	print "INFO - Checking if MNIC resource [ $mnic ] exists...\n";
	my $Xpath="resource[name='" . $mnic ."']";
	my @extDev=$groupNode->findnodes($Xpath);
	if ( @extDev && scalar(@extDev) != 0 ) {
		print "WARN - MNIC resource [ $mnic ]  already exists. Skipping...\n";
		next;
	}

	print "INFO - Checking if other MNIC resource with device [ $devices{$device} ] exists...\n";
	@extDev=();
	#$Xpath="resource[type='NIC']/attribute[Device='" . $devices{$device} . "']";
	$Xpath="resource[type='NIC']/attribute[Device='" . $devices{$device} . "']/../name";
	my $resName=$groupNode->findnodes($Xpath);
	if ( $resName ) {
		print "WARN - MNIC resource [ $mnic ]  already exists with resouece name [ $resName ]. Skipping...\n";
		next;
	}

	print "INFO - Adding MNIC resource [ $mnic ]\n";
	$groupNode->appendChild(XML::LibXML::Text->new("\t\t\n\t\t\t"));
	my $comment = $HADoc->createComment("MNIC resource for the $mnic device");
	$comment->appendChild(XML::LibXML::Text->new("\n\t"));
	my $resNode = $HADoc->createElement('resource');
	$resNode->appendChild(XML::LibXML::Text->new("\n"));
	$groupNode->appendChild($comment);
	$groupNode->appendChild(XML::LibXML::Text->new("\t\t\n\t\t\t"));
	$groupNode->appendChild($resNode);

	my $nameNode = $HADoc->createElement('name');
	$resNode->appendChild(XML::LibXML::Text->new("\t\t\t\t"));
	$nameNode->appendChild(XML::LibXML::Text->new("$mnic"));
	$resNode->appendChild($nameNode);
	$resNode->appendChild(XML::LibXML::Text->new("\n\t\t\t\t"));

	my $typeNode = $HADoc->createElement('type');
#	$resNode->appendChild(XML::LibXML::Text->new("\t\t"));
	$typeNode->appendChild(XML::LibXML::Text->new("NIC"));
	$resNode->appendChild($typeNode);
	$resNode->appendChild(XML::LibXML::Text->new("\n\t\t\t\t"));

	my $attrNode = $HADoc->createElement('attribute');
	$attrNode->appendChild(XML::LibXML::Text->new("\n\t\t\t\t\t"));
	my $devNode = $HADoc->createElement('Device');
	$devNode->appendText("$devices{$device}");
#	$devNode->appendText("\&" . $device . ';');
	$attrNode->appendChild($devNode);
	$attrNode->appendChild(XML::LibXML::Text->new("\n\t\t\t\t"));
	$resNode->appendChild($attrNode);
	$resNode->appendChild(XML::LibXML::Text->new("\n\t\t\t\n\t\t\t"));
	$groupNode->appendChild(XML::LibXML::Text->new("\n\t\t"));

}

if ( ! $HADoc->toFile("$newFile") ) {
	print "ERROR - Failed to save XML to file [ $newFile ] \n";
	exit 1;
}

eval
{
	my $parser1 = XML::LibXML->new();
	my $doc=$parser1->parse_file("$newFile");
	my $root=$doc->getDocumentElement;
};
if($EVAL_ERROR)
{
		print "ERROR - Failed to parse XML : $EVAL_ERROR\n";
		exit 1;
} else {
	print "INFO - New file is valid - Saving it.\n";
	if ( copy($newFile,$HAnetAppFile) ) {
		unlink($newFile);
	} else {
		print "ERROR - Failed to save changed. New file is [ $newFile ]\n";
		exit 1;
	}
}

print "Info - HA netapp default XML created at [ $HAnetAppFile ].\n";
exit 0;
