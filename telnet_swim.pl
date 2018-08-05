#!/usr/bin/perl


use Net::Telnet () ;

my ($view, $ip, $component, $version, $stf, $user, $log, $cust) = ($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4], $ARGV[5], $ARGV[6], $ARGV[7]);
my $net_dir = "/mnt/ums_cm/CM";
my $vob = "CGM/SWIM-KIT" ;
my $pack_script = "pack_sem_utils.pl";
#my $temp_rpm_dir = "$net_dir/temp_rpms";



 $t = Net::Telnet -> new (
	Timeout => 36000,
	Prompt => '/.*\% $/',
	Input_log => $log,
	Host => $ip ) || die ("Telnet problem in creating a connection");

 $t->login ($user,"com2000") || die ("Telnet problems in login") ;

 $t->max_buffer_length(104857600);


# Set the view and log file
	$output = $t->cmd ("ct setview $view"); 
	my $log = "/Users/$user/log/mw_swim_$component.log" ;

# Clean view
if ($component eq "full_clean") {
	$output = $t->cmd ("rm -rf $log");
	#$output = $t->cmd ("rm -rf $temp_rpm_dir/* ");
	$output = $t->cmd ("cd /view/$view ; ~/MRE-ENV/ci_unco_all.pl -unco; ct lspriv | grep -v checkedout | xargs rm -rf ") ;
	exit 0;

}

# Running RPMs

if ($component eq "SEM-UTILS" || $component eq "SEM-FTM-CUST" || $component eq "SEM-FTM-CUST-$cust") {
		print "Starting RPM $component\n\n";
		$output = $t->cmd ("$pack_script $view $component $version $stf >> & $log; cat $log");
		$output = $t->cmd ("sudo cp -f /kit/RPMS/x86_64/* $net_dir/temp_rpms/. ");
		print "$component RPM is ready\n\n";
		exit 0;
		}

# Running the build
	$output = $t->cmd ("swim_change_ver_for_all_comp.pl $view $version $stf >> & $log; cat $log");

	

print "\nI've finished build and rpm\n" ; 
exit 0 ; 