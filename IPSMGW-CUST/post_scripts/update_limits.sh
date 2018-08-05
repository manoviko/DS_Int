#!/bin/bash
# Written by Gregory Danenberg, the script updates limits.conf (updated version)


Date=`date '+%d%m%Y%H%M'`
limitFile=/etc/security/limits.conf

while getopts ":u:f:p:h" opt; do
	case $opt in
		u)
			export APP_USER=$OPTARG; echo "INFO: user is set to $APP_USER";
			;;
		f) 
			export NOFILE_DEF=$OPTARG; echo "INFO: nofile is set to $NOFILE_DEF";
			;;
		p) 
			export NPROC_DEF=$OPTARG; echo "INFO: nproc is set to $NPROC_DEF";
			;;
	    \?)
			echo "Invalid option: -$OPTARG"
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument"
			exit 1
			;;
		h) 
			echo "USAGE: $0 -u [user] -f <nofile value> -p <nproc value>"; 
			exit 1
			;;
		*)
			echo "USAGE: $0 -u [user] -f <nofile value> -p <nproc value>"; 
			exit 1 
			;;

	esac
done

if [ -z $APP_USER ]; then
	echo "USAGE: $0 -u [user] -f <nofile value> -p <nproc value>"
	exit 1
fi
	
getent passwd $APP_USER >/dev/null
if [ $? -ne 0 ]; then
	echo "INFO: User $APP_USER does not exist on this server..."
	exit 1
fi

if [[ "`hostname`" =~ "[oO][mM][Uu]" ]] && [ $APP_USER == "smsc" ] ; then
	echo "INFO: No need to update smsc user on OMU server"
	exit 0
fi


cp ${limitFile} ${limitFile}.${Date}
echo "INFO: ${limitFile} has been backed up to ${limitFile}.${Date}"

checkStatus() {
#get status
	rc=$1
	txt=$2
	
	if [ $rc -ne 0 ]; then
		echo "ERROR: Failed $2"
		exit 1
	else
		echo "INFO: Succeeded $2"
	fi
}


##let's do it quickly in one line
perl -i -ne '
	BEGIN { $nofile=0;$nproc=0 };
	if ($_ !~ /^#/ and defined $ENV{NOFILE_DEF} and $_ =~ /$ENV{APP_USER}\s+.+\s+nofile\s+\d+/) { 
		if ( $nofile == 0 ) {
			print "$ENV{APP_USER}\t-\tnofile\t$ENV{NOFILE_DEF}\n";
			$nofile=1;
			print STDOUT "INFO: Updated nofile with a new value $ENV{NOFILE_DEF} for user $ENV{APP_USER}\n";
			#$ENV{UPD_NOFILE_DEF}=1;
		}
	} elsif ($_ !~ /^#/ and defined $ENV{NPROC_DEF} and $_ =~ /$ENV{APP_USER}\s+.+\s+nproc\s+\d+/) {
		if ( $nproc == 0 ) {
			print "$ENV{APP_USER}\t-\tnproc\t$ENV{NPROC_DEF}\n";
			$nproc=1;
			print STDOUT "INFO: Updated nproc with a new value $ENV{NPROC_DEF} for user $ENV{APP_USER}\n";
			#$ENV{UPD_NOPROC_DEF}=1;
		}
	} else { 
		print 
	}' $limitFile
	if [ $? -ne 0 ]; then
		echo "ERROR: Failed to update $limitFile for $APP_USER user"
		exit 1
	fi
 

	
if [ $NOFILE_DEF ] && [ ! "`grep $APP_USER.*nofile $limitFile |grep -v "^\#"`" ]; then	
	echo -e "${APP_USER}\t-\tnofile\t$NOFILE_DEF" >> ${limitFile}
	checkStatus $? "adding nofile parameter for $APP_USER user in $limitFile, value set to $NOFILE_DEF"
fi
if  [ $NPROC_DEF ] && [ ! "`grep $APP_USER.*nproc $limitFile |grep -v "^\#"`" ]; then	
	echo -e "${APP_USER}\t-\tnproc\t$NPROC_DEF" >> ${limitFile}
	checkStatus $? "adding nproc parameter for $APP_USER user in $limitFile, value set to $NPROC_DEF"
fi

perl -i -pe 's/\#\s*End\s*of\s*file\s*$//' ${limitFile}
echo "# End of file" >> ${limitFile}


	

