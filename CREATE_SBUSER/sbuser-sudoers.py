#!/usr/bin/python

__author__ = 'Nathaniel Assis'
import subprocess
import os.path
import sys
import shutil
import datetime
import pwd
from optparse import OptionParser

_usage = ''.join("Usage: ./" + os.path.basename(__file__) + " -o <install/uninstall>")

parser = OptionParser()
parser.add_option("-o", "--option", dest="option",help="Choose option", metavar="<install/uninstall>")
(options, args) = parser.parse_args()

if not options.option:
    print "[ERROR]: Installation option was not defined, exiting!"
    print _usage
    exit(1)
else:
    print "[INFO]: Installation option is : ", options.option

sudo_user = "sbuser"
sudo_entry = sudo_user + " " + "ALL=NOPASSWD: /usr/bin/find,/bin/sh,/bin/ls,/usr/bin/cksum,/usr/local/bin/find,/bin/tar,/usr/bin/xargs,/bin/xargs,/bin/chmod,/bin/rm,/bin/cat,/bin/rpm"
sudo_file = "/etc/sudoers.d/sitebook"


def pre_requisites():
    """
    This function verifies the following:
    1. Script is running over a linux operating system
    2. Linux release is 6.0 and above
    :return:
    0 - Success
    1 - Failed operating system
    2 - Failed release level
    3 - Non existing user
    """
    command = u'/usr/cti/apps/CSPbase/csp_scanner.pl --os_type'.format()
    pipe = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    os_type = pipe.stdout.read().rstrip('\n')
    exitcode = pipe.wait()

    if os_type != 'linux':
        print "[ERROR] This is not a Linux operating system, exiting."
        return 1
    else:
        print "[INFO]: This is a Linux operating system."

    command = u'/usr/cti/apps/CSPbase/csp_scanner.pl --os_release'.format()
    pipe = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    os_release = pipe.stdout.read().rstrip('\n')
    exitcode = pipe.wait()

    if os_release < 6.0:
        print "[ERROR]: Redhat release is lower than 6.0, exiting."
        return 2
    else:
        print "[INFO]: This is Redhat Linux operating system, release ", os_release, "."

    try:
        pwd.getpwnam(sudo_user)
    except KeyError:
        # Handle non existent user
        print "[ERROR]: User ", sudo_user, " does not exist, exiting"
        return 3
    else:
        # Handle existing user
        print "[INFO]: User ", sudo_user, " exists, continue working"
        return 0

    return 0


def backup(_file):
    """
    This function back's up files to a specific folder and renames the file
    The backup format is according to integration team specs
    :return:
    0 - Success
    1 - Failed backup operation
    """
    backup_folder = "/usr/cti/conf/integration/backup/"
    file_basename = os.path.basename(_file)
    dt = datetime.datetime.now().strftime("%m-%d-%Y-%H-%M-%S")
    backup_file = backup_folder + file_basename + "-" + dt + '.backup'
    rc = os.path.exists(backup_folder)
    if rc == 1:
        print "[INFO]: Backup folder ", backup_folder, " already exists, starting backup"
        shutil.copy(sudo_file, backup_file)
    else:
        print "[WARN]: Backup folder ", backup_folder, " does not exist, creating it"
        os.makedirs(backup_folder)
        print "[INFO]: Created backup folder ", backup_folder, ", starting backup"
        shutil.copy(sudo_file, backup_file)

    print "[INFO]: Backup complete"

    return 0


def add_sudoers(_file, sudo_2_add):
    """
    This function will create add sudo entries to the sudo file which is provided by '_file'
    It will write the file to a temporary file /var/tmp/[_file basename].temp
    once writing is done, the file will be moved to /etc/sudoers.d/ folder
    """
    temp_file = "/var/tmp/" + os.path.basename(_file) + ".temp"
    f = open(temp_file, "w")
    print "[INFO]: Opening file", _file, " for write operations"
    f.write("#*********************Begin:Added by integration team ************************\n")
    f.write(sudo_2_add)
    f.write('\n')
    f.write("#*********************End:Added by integration team ************************\n")
    print "[INFO]: Finished writing sudo commands to ", _file, ", closing file"
    f.close()
    shutil.move(temp_file, _file)


def main(argv):
    """
    Main function
    """

    if options.option == 'install':
        rc = pre_requisites()
        if rc != 0:
            print "[ERROR]: Failed pre_requisites check."
            exit(1)
        rc = os.path.exists(sudo_file)
        if rc:
            print "[WARN]: File ", sudo_file, " exists, creating backup"
            backup(sudo_file)
            add_sudoers(sudo_file, sudo_entry)
        else:
            print "[INFO]: File ", sudo_file, " does not exist, creating it"
            add_sudoers(sudo_file, sudo_entry)
            print ""
    elif options.option == "uninstall":
        print "[INFO]: Removing sudoers file: ", sudo_file
        try:
            os.remove(sudo_file)
        except OSError:
            pass
    else:
        print "[ERROR]: Unsupported option <install/uninstall>, exiting"
        exit(1)
    pass


if __name__ == "__main__":
    main(sys.argv)

