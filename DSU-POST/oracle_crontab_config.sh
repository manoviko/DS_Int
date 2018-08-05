#!/bin/bash

# removing and adding correct lines to the crontab files

Date=`date '+%d%m%Y%H%M'`
echo "WARN : /var/spool/cron/oracle exists. Backup it as /var/spool/cron/oracle.${Date}"
/bin/cp -f /var/spool/cron/oracle /var/spool/cron/oracle.${Date}
/usr/cti/apps/CSPbase/csp_cronedit.pl --remove  --user=oracle  --task "Backup the database"

if [ -d /data/sem_db_data ] ; then
echo "WARN : removing and adding correct lines to the crontab file on DSU."
  /usr/cti/apps/CSPbase/csp_cronedit.pl --remove  --user=oracle  --task "RMAN_Backup_DB.sh -d sem_db"
  /usr/cti/apps/CSPbase/csp_cronedit.pl --add  --user=oracle --schedule '0 5 * * *' --task "( . /oracle/.cronenv ; /oracle/admin/backup/RMAN_Backup_DB.sh -d sem_db > /dev/null 2>&1 )"
fi
/usr/cti/apps/CSPbase/csp_cronedit.pl --remove  --user=oracle  --task "( . /oracle/.cronenv ; /oracle/dbm/bin/clean_arch_all.sh -n 2 > /dev/null 2>&1 )"
#/usr/cti/apps/CSPbase/csp_cronedit.pl --add  --user=oracle --schedule '0 3 * * *' --task "( . /oracle/.cronenv ; /oracle/dbm/bin/clean_arch_all.sh -n 2 > /dev/null 2>&1 )"