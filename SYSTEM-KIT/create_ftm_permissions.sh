#!/bin/bash

echo "Creating ftm user and ftm group and set full permissions to trace and statistics folders located under /var/cti/logs"

grep "ftm:" /etc/passwd >/dev/null 2>&1
if [ $? -eq 0 ] ; then
        # User already exist
        echo "INFO: FTM user already exist"
        # Add user ftm to group ftm
        usermod -a -G ftm ftm
else
        # There is no such user.
        echo "INFO: There is no ftm user"
        # If during previous installation some users were added to the group,
        # it would not be removed during uninstall of previous installation.
        # Hence we shall ignore the error, if the group already exists (-f flag):
        groupadd -f -g 17900 ftm 2> /dev/null
        #useradd -u 17901 -g ftm -G ftm -s /bin/bash -d /var/ftm -p '$1$qvbikiF0$UmXxxicTnAjE8eHHsTAaz/' ftm
		 useradd -u 17901 -g ftm -G ftm -s /bin/bash -d /var/ftm -p '$6$Yu20bb9Y$XDoRQyudg6CyfVDSmswPBizwssyXiNe3Cc4K9KHcwxI/dQxlJTIcPThbYhSSgiQNe/13dNvuoNdHJb7ZXYgWr0' ftm 
fi

echo "INFO: FTM user,group are created, ACL permissions for ftm user set to needed folders"
 #add ftm group full access to /var/cti/logs/ including sub directories 		
 #It would get ftm user permissions to manipulate with application trace and statisctics file located under /var/cti/logs/application

for folder in /var/cti/logs/impa /var/cti/logs/spl /var/cti/logs/ons /var/cti/logs/vimpa; do
 
	if [ -d ${folder} ]; then
		echo "INFO: Setting ACL on $folder"
		setfacl -R -m g:ftm:rwx ${folder}
		setfacl -R -d -m g:ftm:rwx ${folder}
	fi
 
 done
 