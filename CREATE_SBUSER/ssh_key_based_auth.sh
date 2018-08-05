#!/bin/bash

#Written by Inna Kushner, 10/08/2016

#DR-0-225-136 : Security - SSH key based authentication

Date=`date '+%d%m%Y%H%M'`

#execute on all type of servers

#!/bin/bash
#SSH key-based authentication
  
        if [ ! -d /home/sbuser/.ssh/ ]; then
                        echo "-I- This is isu unit, creating /home/sbuser/.ssh/ directory"
                        mkdir -p /home/sbuser/.ssh/
                        chmod -R 700 /home/sbuser/.ssh/
                        chown sbuser:sbuser /home/sbuser/.ssh/
        fi

            key=$(cat /var/tmp/id_rsa.pub)
            echo "public key:"
            echo $key

            if [ -f /home/sbuser/.ssh/authorized_keys ]; then
                        grep -q "$key" /home/sbuser/.ssh/authorized_keys
                        if [ $? -ne 0 ]; then
                                    echo "Adding ftm public key to list of authorized keys"
                                    echo "$key" >> /home/sbuser/.ssh/authorized_keys
                        else
                                    echo "Public key already part of authorized keys,nothing to do"
                        fi
            else
                        echo "Creating authorized_keys file and adding ftm public key to list of authorized keys"
                        touch /home/sbuser/.ssh/authorized_keys
                        echo "$key" >> /home/sbuser/.ssh/authorized_keys
                        chmod 700 /home/sbuser/.ssh/authorized_keys
                        chown sbuser:sbuser /home/sbuser/.ssh/authorized_keys
			fi
     