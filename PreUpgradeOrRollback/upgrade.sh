#!/bin/sh -x

writeToLog(){
        dateStr=[`date +"%d-%m-%Y %H:%M:%S"`]
        #write to stdout - will appear on swim audit logs
        echo "$dateStr - $1"
}

USAGE="Syntax is: ./upgrade.sh <component name> [<component version to install>] <shouldPerformInstall (1-yes/0-no)>"
EXAMPLE="Example: ./upgrade.sh NYM-INFRA 4.7.300-0, or ./upgrade.sh NYM-ROUTER, or ./upgrade.sh NYINFRA 4.7.300-0 0"

# Check syntax. Should get 2 arguments.
if [ $# -lt 1 ]; then
        echo $USAGE $EXAMPLE
        exit 1
fi

compName=$1
scratchPackageType=0
shouldPerformInstall=1
if [ $# -eq 3 ]; then
   if [ $3 -eq 0 ]; then
        shouldPerformInstall=0
        writeToLog "upgrade.sh - a request to skip install was performed"
   fi
fi

if [ $# -ge 2 ]; then
        compVer=$2
        ver=`echo $compVer|cut -d - -f 1`
        installed_pkg=`rpm -qa | grep --basic-regexp "$compName[0-9]*-$ver" | sed 's/\.Linux.x86_64//'`
        msg=",version $ver"
else
        installed_pkg=`rpm -qa | grep $compName`
        scratchPackageType=1
        msg="as scratch"
fi

removeResult=0
# If the new version is not already installed -> install from scratch
if [ -z $installed_pkg ]; then
        writeToLog "upgrade.sh - Doing installation for $compName $msg"
else
        if [  $scratchPackageType -ne 1 ]; then
                # Compare builds
                #updated by Gregory to support RH 6 packages
                echo $compVer|grep -q NYMAP
                if [ $? -eq 0 ]; then
                        new_build=`echo $compVer|perl -ne 'print $1 if /[\d\.]+\d+-(\d+)\.?/'`
                        new_stf=`echo $compVer|perl -ne 'print $1 if /[\d\.]+\d+-\d+\.?(\d*)/'`
                else
                        new_build=`echo $compVer|perl -ne 'print $1 if /[\d\.]+-(\d+)\.?/'`
                        new_stf=`echo $compVer|perl -ne 'print $1 if /[\d\.]+-\d+\.?(\d*)/'`
                        if [ -z $new_stf ]; then
                                new_stf=`echo $compVer|perl -ne 'print $1 if /[\d\.]+-(\d+)\.?/'`
                        fi
                fi

                echo $installed_pkg|grep -q NYMAP
                if [ $? -eq 0 ]; then
                        curr_build=`echo $installed_pkg|perl -ne 'print $1 if /[\d\.]+\d+-T(\d+)\.?/'`
                        curr_stf=`echo $installed_pkg|perl -ne 'print $1 if /[\d\.]+-T\d+\.?(\d*)/'`
                else
                        curr_build=`echo $installed_pkg|perl -ne 'print $1 if /[\d\.]+-(\d+)\.?/'`
                        if [ -z $curr_build ]; then
                                curr_build=`echo $installed_pkg|perl -ne 'print $1 if /[\d\.]+-T(\d+)\.?/'`
                        fi
                        curr_stf=`echo $installed_pkg|perl -ne 'print $1 if /[\d\.]+-\d+\.?(\d*)/'`
                        if [ -z $curr_stf ]; then
                                curr_stf=`echo $installed_pkg|perl -ne 'print $1 if /[\d\.]+-T(\d+)\.?/'`
                        fi
                fi
                # We try to upgrate to a build, which is less/equal to current build -> do nothing
                if [ $new_build -gt $curr_build ]; then
                        writeToLog "upgrade.sh - Upgrading $copmName from build $curr_build to build $new_build"
                elif [ $new_build -eq $curr_build ]; then
                        if [ $new_stf -gt $curr_stf ]; then
                                writeToLog "upgrade.sh - Upgrading $copmName from build $curr_build.$curr_stf to build $new_build.$new_stf"
                        else
                                 writeToLog "upgrade.sh - Nothing to upgrade. New stf is not greater than the current one."
                                 exit 1
                        fi
                else
                        writeToLog "upgrade.sh - Nothing to upgrade. New build is not greater than the current one."
                        exit 1
                fi
        fi
        # Case is scratch install, or upgrade between STFs -> need to uninstall current build and install new one  
        writeToLog "upgrade.sh - remove current installation"
		
		#updated by Inna to support RH 6 packages
		
        #rpm -e --nodeps $installed_pkg
		 rpm -e --nodeps `echo $installed_pkg | awk -F ".Linux" '{print $1}'`
		
        removeResult="$?"
        #Remove an RPM lock file
        rm -rf /var/lib/rpm/pkgadd/lock
fi

if [ "$removeResult" != "0" ]; then
        writeToLog "upgrade.sh - Failed removing old package $compName. Exiting"
        exit 4
fi

if [ $shouldPerformInstall -eq 1 ]; then
        writeToLog "upgrade.sh - install new package"
        PATH=$PATH:/usr/local/bin
        execPkg=`ls | grep $compName | grep -v "\.xml"`
        ./${execPkg}

        if [ "$?" != "0" ]; then
             writeToLog "upgrade.sh - Failed installing new package $compName. Exiting"
             exit 4
        fi
else
        writeToLog "upgrade.sh - should install new package of ${compName} in the CAF"
        exit 2
fi

writeToLog "upgrade.sh - Done successfully."

exit 0