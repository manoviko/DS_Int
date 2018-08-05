#!/bin/bash

#Written by Inna Kushner, 10/08/2016

#DR-0-225-136 : Security - SSH key based authentication

UnitType=$1

if [ -z $UnitType ]; then
	echo "ERROR: You have to supply UnitType, for example: ISU_Group,MAP_Group..."
fi

Date=`date '+%d%m%Y%H%M'`

#execute on all type of servers

#!/bin/bash
#SSH key-based authentication
  
case $UnitType in

	 ISU_Group)
       echo "INFO : key-based authentication for $UnitType"
        if [ ! -d /home/smsc/.ssh/ ]; then
                        echo "-I- This is isu unit, creating /home/smsc/.ssh/ directory"
                        mkdir -p /home/smsc/.ssh/
                        chmod -R 700 /home/smsc/.ssh/
                        chown smsc:sys /home/smsc/.ssh/
        fi
		if [ ! -d /home/ftm/.ssh/ ]; then
                        echo "-I- This is isu unit, creating /home/ftm/.ssh/ directory"
						mkdir -p /home/ftm/.ssh/						
                        chmod -R 700 /home/ftm/.ssh/
						chown ftm:ftm /home/ftm
                        chown ftm:ftm /home/ftm/.ssh/
        fi

            key_ftm=$(cat /var/tmp/id_rsa.pub.ftm)
            echo "public key:"
            echo $key_ftm

            if [ -f /home/smsc/.ssh/authorized_keys ]; then
                        grep -q "$key_ftm" /home/smsc/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding ftm public key to list of authorized keys"
                                    echo "$key_ftm" >> /home/smsc/.ssh/authorized_keys
                        else
                                    echo "FTM public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding ftm public key to list of authorized keys"
                        touch /home/smsc/.ssh/authorized_keys
                        echo "$key_ftm" >> /home/smsc/.ssh/authorized_keys
                        chmod 700 /home/smsc/.ssh/authorized_keys
                        chown smsc:sys /home/smsc/.ssh/authorized_keys
			fi
			
			# ftm public key to ftm user
            usermod -d /home/ftm ftm
            # Add user ftm to group sys
			usermod -a -G sys ftm
			if [ -f /home/ftm/.ssh/authorized_keys ]; then
                        grep -q "$key_ftm" /home/ftm/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding ftm public key to list of authorized keys"
                                    echo "$key_ftm" >> /home/ftm/.ssh/authorized_keys
                        else
                                    echo "FTM public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding ftm public key to list of authorized keys"
                        touch /home/ftm/.ssh/authorized_keys
                        echo "$key_ftm" >> /home/ftm/.ssh/authorized_keys
                        chmod 700 /home/ftm/.ssh/authorized_keys
                        chown ftm:ftm /home/ftm/.ssh/authorized_keys
			fi
			chmod -R 770 /var/cti/smsc/site/trace/stats
			chmod -R 770 /var/cti/smsc/site/trace/IPGW
			chmod -R 770 /var/cti/smsc/site/trace/cdr
			
			key_smsc=$(cat /var/tmp/id_rsa.pub.smsc)
            echo "public key:"
            echo $key_smsc

            if [ -f /home/smsc/.ssh/authorized_keys ]; then
                        grep -q "$key_smsc" /home/smsc/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding smsc public key to list of authorized keys"
                                    echo "$key_smsc" >> /home/smsc/.ssh/authorized_keys
                        else
                                    echo "SMSC public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding smsc public key to list of authorized keys"
                        touch /home/smsc/.ssh/authorized_keys
                        echo "$key_smsc" >> /home/smsc/.ssh/authorized_keys
                        chmod 700 //home/smsc/.ssh/authorized_keys
                        chown smsc:sys /home/smsc/.ssh/authorized_keys
			fi
                  ;;
	   MAP_Group) 
		echo "INFO : key-based authentication for $UnitType"
				
        if [ ! -d /home/smsc/.ssh/ ]; then
                        echo "-I- This is map unit, creating /home/smsc/.ssh/ directory"
                        mkdir -p /home/smsc/.ssh/
                        chmod -R 700 /home/smsc/.ssh/
                        chown smsc:sys /home/smsc/.ssh/
        fi
		if [ ! -d /home/ftm/.ssh/ ]; then
                        echo "-I- This is map unit, creating /home/ftm/.ssh/ directory"
                        mkdir -p /home/ftm/.ssh/
						chown ftm:ftm /home/ftm
                        chmod -R 700 /home/ftm/.ssh/
                        chown ftm:ftm /home/ftm/.ssh/
        fi

            key_ftm=$(cat /var/tmp/id_rsa.pub.ftm)
            echo "public key:"
            echo $key_ftm

            if [ -f /home/smsc/.ssh/authorized_keys ]; then
                        grep -q "$key" /home/smsc/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding ftm public key to list of authorized keys"
                                    echo "$key_ftm" >> /home/smsc/.ssh/authorized_keys
                        else
                                    echo "FTM public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding ftm public key to list of authorized keys"
                        touch /home/smsc/.ssh/authorized_keys
                        echo "$key_ftm" >> /home/smsc/.ssh/authorized_keys
                        chmod 700 //home/smsc/.ssh/authorized_keys
                        chown smsc:sys /home/smsc/.ssh/authorized_keys
			fi
			# ftm public key to ftm user
            usermod -d /home/ftm ftm
			# Add user ftm to group sys
			usermod -a -G sys ftm
            chmod -R 770 /var/cti/smsc/site/trace/MAP/stats
			
			if [ -f /home/ftm/.ssh/authorized_keys ]; then
                        grep -q "$key_ftm" /home/ftm/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding ftm public key to list of authorized keys"
                                    echo "$key_ftm" >> /home/ftm/.ssh/authorized_keys
                        else
                                    echo "FTM public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding ftm public key to list of authorized keys"
                        touch /home/ftm/.ssh/authorized_keys
                        echo "$key_ftm" >> /home/ftm/.ssh/authorized_keys
                        chmod 700 /home/ftm/.ssh/authorized_keys
                        chown ftm:ftm /home/ftm/.ssh/authorized_keys
			fi
			
			key_smsc=$(cat /var/tmp/id_rsa.pub.smsc)
            echo "public key:"
            echo $key_smsc

            if [ -f /home/smsc/.ssh/authorized_keys ]; then
                        grep -q "$key_smsc" /home/smsc/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding smsc public key to list of authorized keys"
                                    echo "$key_smsc" >> /home/smsc/.ssh/authorized_keys
                        else
                                    echo "SMSC public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding smsc public key to list of authorized keys"
                        touch /home/smsc/.ssh/authorized_keys
                        echo "$key_smsc" >> /home/smsc/.ssh/authorized_keys
                        chmod 700 //home/smsc/.ssh/authorized_keys
                        chown smsc:sys /home/smsc/.ssh/authorized_keys
			fi
			
			;;
			
			SCA_Group) 			
		    echo "INFO : key-based authentication for $UnitType"
            if [ ! -d /home/semus/.ssh/ ]; then
                        echo "-I- This is shu unit, creating /home/semus/.ssh/ directory"
                        mkdir -p /home/semus/.ssh/
                        chmod -R 700 /home/semus/.ssh/
                        chown semus:semus /home/semus/.ssh/
            fi
           	
			key_smsc=$(cat /var/tmp/id_rsa.pub.smsc)
            echo "public key:"
            echo $key_smsc

            if [ -f /home/semus/.ssh/authorized_keys ]; then
                        grep -q "$key_smsc" /home/semus/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding smsc public key to list of authorized keys"
                                    echo "$key_smsc" >> /home/semus/.ssh/authorized_keys
                        else
                                    echo "SMSC public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding smsc public key to list of authorized keys"
                        touch /home/semus/.ssh/authorized_keys
                        echo "$key_smsc" >> /home/semus/.ssh/authorized_keys
                        chmod 700 /home/semus/.ssh/authorized_keys
                        chown semus:semus /home/semus/.ssh/authorized_keys
			fi
			;;
			
			Shared_OMU_Group)
			if [ ! -d /home/smsc/.ssh/ ]; then
                        echo "-I- This is isu unit, creating /home/smsc/.ssh/ directory"
                        mkdir -p /home/smsc/.ssh/
                        chmod -R 700 /home/smsc/.ssh/
                        chown smsc:sys /home/smsc/.ssh/
            fi
			key_smsc_pub=$(cat /var/tmp/id_rsa.pub.smsc)
            echo "public key:"
            echo $key_smsc_pub

            if [ -f /home/smsc/.ssh/id_rsa.pub ]; then
                echo "smsc public key already exists,nothing.Backup it as /home/smsc/.ssh/id_rsa.pub.${Date}"
				/bin/cp -f /home/smsc/.ssh/id_rsa.pub /home/smsc/.ssh/id_rsa.pub.${Date}
			fi	
                echo "copying smsc public key to OMU"
                cp /var/tmp/id_rsa.pub.smsc /home/smsc/.ssh/id_rsa.pub
                chmod 700 /home/smsc/.ssh/id_rsa.pub
                chown smsc:sys /home/smsc/.ssh/id_rsa.pub
			
			key_smsc_private=$(cat /var/tmp/id_rsa)
            echo "private key:"
            echo $key_smsc_private

            if [ -f /home/smsc/.ssh/id_rsa ]; then
                echo "smsc private key already exists,nothing.Backup it as /home/smsc/.ssh/id_rsa.${Date}"
				/bin/cp -f /home/smsc/.ssh/id_rsa /home/smsc/.ssh/id_rsa.${Date}
			fi
                echo "copying smsc private key to OMU"
                cp /var/tmp/id_rsa /home/smsc/.ssh/id_rsa
                chmod 700 /home/smsc/.ssh/id_rsa
                chown smsc:sys /home/smsc/.ssh/id_rsa
			;; 
			
	 	   *)
			echo "WARN : Failed to find instructions for $UnitType"
			;;
esac 