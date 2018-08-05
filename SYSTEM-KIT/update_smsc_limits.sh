#!/bin/bash
# Written by Gregory Danenberg, the script updates limits.conf
# Used for MRE on application units 

Date=`date '+%d%m%Y%H%M'`

export APP_USER=smsc
HOSTNAME=`hostname`|tr [A-Z] [a-z]

getent passwd smsc >/dev/null
if [ $? -ne 0 ]; then
	echo "INFO: This is not a MRE server, no need to update nofile parameter"
	exit 0
fi

if [[ "$HOSTNAME" =~ "omu" ]]; then
	echo "INFO: This is OMU server, no need to update nofile parameter"
	exit 0
fi

while getopts ":f:p:h" opt; do
	case $opt in
		f) 
			NOFILE_DEF=$OPTARG; echo "INFO: nofile is set to $NOFILE_DEF";
			;;
		p) 
			#this option is depricated
			NPROC_DEF=$OPTARG; echo "INFO: nproc is set to $NPROC_DEF";
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
			echo "USAGE: $0 -f [nofile value] -p [nproc value]"; 
			exit 1
			;;
		*)
			echo "USAGE: $0 -f [nofile value] -p [nproc value]"; 
			exit 1 
			;;

	esac
done

limitFile=/etc/security/limits.conf
cp ${limitFile} ${limitFile}.${Date}
echo "INFO: ${limitFile} has been backed up to ${limitFile}.${Date}"

#set defaults
[ -z $NOFILE_DEF ] && NOFILE_DEF=4096
#[ -z $NPROC_DEF ]  && NPROC_DEF=4096

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

export NOFILE_DEF
export NPROC_DEF
	
perl -i -ne '
	BEGIN { $nofile=0;$nproc=0 };
	if ($_ !~ /^#/ and $_ =~ /.+\s+nofile\s+\d+/) { 
		if ( $nofile == 0 ) {
			print "$ENV{APP_USER}\t-\tnofile\t$ENV{NOFILE_DEF}\n";
			$nofile=1;
		}
	} elsif ($_ !~ /^#/ and $_ =~ /.+\s+.+\s+nproc\s+\d+/) {
		if ( $nproc == 0 ) {
			print "$ENV{APP_USER}\t-\tnproc\t$ENV{NPROC_DEF}\n";
			$nproc=1;
		}
	} else { 
		print 
	}' $limitFile
	#checkStatus $? "updated $limitFile with nofile=$NOFILE_DEF and nproc=$NPROC_DEF"
	checkStatus $? "updated $limitFile with nofile=$NOFILE_DEF"

	
if [ ! "`grep nofile $limitFile |grep -v "^\#"`" ]; then	
	echo -e "${APP_USER}\t-\tnofile\t$NOFILE_DEF" >> ${limitFile}
	checkStatus $? "adding nofile parameter for hdfs user in $limitFile set to $NOFILE_DEF"
fi

perl -i -pe 's/\#\s*End\s*of\s*file\s*$//' ${limitFile}
echo "# End of file" >> ${limitFile}

#if [ ! "`grep nproc $limitFile |grep -v "^\#"`" ]; then	
#	perl -i -pe 's/\#\s*End\s*of\s*file\s*$//' ${limitFile}						
#	echo -e "hdfs\t-\tnproc\t$NPROC_DEF" >> ${limitFile}
#	checkStatus $? "adding nproc parameter for hdfs user in $limitFile set to $NPROC_DEF"
#	echo -e "hbase\t-\tnproc\t$NPROC_DEF" >> ${limitFile}
#	checkStatus $? "adding nproc parameter for hbase user in $limitFile set to $NPROC_DEF"
#	echo "# End of file" >> ${limitFile}
#fi
	

