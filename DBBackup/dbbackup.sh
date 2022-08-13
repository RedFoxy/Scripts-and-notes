#!/bin/bash
##########################################################################################################################################
# MySQL Database Backup
# v1.1.0
# 03 sep 2021
# Writed by Massimo "RedFoxy Darrest" Cicciò
# http://www.redfoxy.it
#
# Usage:
#
# dbbackup DB_NAME {REPAIR} {TYPE} {UID} {PWD} {CONN}
#
# DB_NAME	String		Database name
# REPAIR	YES/NO		Repair & Optimize tables
# TYPE		SQL/COPY	Backup Type: SQL = mysqldump - COPY = mysqlhotcopy
# UID		String		User with priviledge: SELECT, INSERT, RELOAD, FILE, SHOW DATABASES, LOCK TABLES, SHOW VIEW
# PWD		String		Password
# CONN		String		Socket Path or Address or Address:Port
# UPLOAD	YES/NO		Upload backup on remote server
# KEEPLOCAL	YES/NO		Keep a copy local
#
#
##########################################################################################################################################

##########################################################################################################################################
# CONFIGURATION
##########################################################################################################################################

SHOWHEAD="NO";				# Show backup header
BCK_DIR="/opt/backup/";		# Backup directory

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

OPZ_TAR="zcf";				# Tar options

DEF_USER="DEFAULT_USERNAME";# Default username
DEF_PWD="DEFAULT_PASSWORD";	# Default password
DEF_CONN="/var/run/mysqld/mysqld.sock";	# Default connection
DEF_REP="NO";				# Default repair and optimize
DEF_TYPE="SQL";				# Default backup type
DEF_UPLOAD="NO";			# Keep local copy
DEF_KEEP_LOCAL="YES";		# Keep local copy

##########################################################################################################################################

DATABASE=$1;
REPAIR=${2:-$DEF_REP};
DUMP_TYPE=${3:-$DEF_TYPE};
USER=${4:-$DEF_USER};
PASS=${5:-$DEF_PWD};
DBCONN=${6:-$DEF_CONN};
UPLOAD=${7:-$DEF_UPLOAD};
KEEP_LOCAL=${8:-$DEF_KEEP_LOCAL};

DATA=`date "+%Y-%m-%d_%H-%M-%S"`;
BCK_FILE="${DATABASE}_${DATA}";

MYSQLDUMP=`which mysqldump`
MYSQLHOTCOPY=`which mysqlhotcopy`
MYSQLCHECK=`which mysqlcheck`
MYSQLADMIN=`which mysqladmin`
MYSQLSHOW=`which mysqlshow`

TAR_FILE=`which tar`;

if [ -z $TAR_FILE ]; then
  echo "Unable to find tar in PATH!";
  echo "Please install before to continue.";
  exit 2;
else
  TAR_FILE="$TAR_FILE $OPZ_TAR";
fi

if [ -z $MYSQLDUMP ]; then
  echo "Unable to find mysqldump in PATH!";
  echo "Please check your MySQL/MariaDB installation before to continue.";
  exit 2;
fi

if [ -z $MYSQLHOTCOPY ]; then
  echo "Unable to find mysqlhotcopy in PATH!";
  echo "Please check your MySQL/MariaDB installation before to continue.";
  exit 2;
fi

if [ -z $MYSQLCHECK ]; then
  echo "Unable to find mysqlcheck in PATH!";
  echo "Please check your MySQL/MariaDB installation before to continue.";
  exit 2;
fi

if [ -z $MYSQLADMIN ]; then
  echo "Unable to find mysqladmin in PATH!";
  echo "Please check your MySQL/MariaDB installation before to continue.";
  exit 2;
fi

if [ -z $MYSQLSHOW ]; then
  echo "Unable to find mysqlshow in PATH!";
  echo "Please check your MySQL/MariaDB installation before to continue.";
  exit 2;
fi

##########################################################################################################################################
me=`basename "$0"`

if [ ! $1 ]
then
  cat <<HELP_USAGE
usage: $me DATABASE";
Following parameters are optionals if you specified default value inside the script.";
 VALUE/MEANING | Description";
 YES/NO        | Repair and optimize tables or not";
 SQL/COPY      | Backup Type: SQL = mysqldump - COPY = mysqlhotcopy";
 Username      | Specify an user with following priviledge: SELECT, INSERT, RELOAD, FILE, SHOW DATABASES, LOCK TABLES, SHOW VIEW";
 Password      | User password
 Socket        | Connection string as socket path or Hostname/ip address followed by MySQL/MariaDB port: hostname:Port
 Upload URL    | Upload backup on remote server, NO or destination url ssh://user:password@host/path ftp://user:password@host/path
 YES/NO        | Keep a local copy of the backup or delete after upload

Example:
$me MyDatabase1
 Backup MyDatabase1 using all default value specified in the $me

$me MyDatabase2 NO SQL MyUser PaSsWoRd! /var/run/mysqld/mysqld.sock ssh://myssh:PassWord123@myhost.com/backup/database YES
 Backup MyDatabase2 as SQL dump and tarball it, without repair/optimize tables,
 using /var/run/mysqld/mysqld.sock as socket connection and MyUser PaSsWoRd! to login, than
 upload it to ssh://myssh:PassWord123@myhost.com/backup/database and keep a local copy of the backup.
HELP_USAGE

  exit 2;
fi

##########################################################################################################################################

if [[ $DBCONN == *"/"* ]]; then
  DBCONN=--socket=${DBCONN};
else
  if [[ $DBCONN == *":"* ]]; then
    DBCONN=--host=${DBCONN/:/ --port=};
  else
    DBCONN=--host=${DBCONN};
  fi
fi

if [ ! $DATABASE ]
then
  echo "Error: A database must be specified.";
  exit 2;
fi

if [ `${MYSQLADMIN} --user=$USER --password=${PASS} ${DBCONN} ping 2>/dev/null | grep -c 'alive'` != "1" ];
then
  echo "Error: Mysql server is not online or there is an error in connection informations";
  exit 2;
fi

if [ `${MYSQLSHOW} --user=$USER --password="${PASS}" ${DBCONN} ${DATABASE} 2>/dev/null | grep -c Database:\ ${DATABASE}` != "1" ];
then
  echo "Error: Database '$DATABASE' not found";
  exit 2;
fi

##########################################################################################################################################

if [ $SHOWHEAD == "YES" ]
then
  echo " ";
  echo "------------------ Database Backup "  `date "+%d/%m/%Y"` "--------------------";
  echo " ";
  echo "Backup dir                   : ${BCK_DIR}";
  echo "Keep local copy              : ${KEEP_LOCAL}";
  echo "Upload on remote server      : ${UPLOAD}";
  echo "Number of remote copy        : 1";
  echo " ";
fi

echo "############################################################################";
echo "# Database            : ${DATABASE}";
echo "# Dump Type           : ${DUMP_TYPE}";
echo "# Repair Tables       : ${REPAIR}";
echo "#";

BCK_START=`date "+%s"`;
BCK_DEST=${BCK_DIR}${DATABASE}/`date "+%Y"`/`date "+%m"`/;
echo "# Backup database starts at    :" `date "+%d/%m/%Y %H:%M:%S"`;

mkdir -p ${BCK_DEST};
cd ${BCK_DEST};

################################################################# Dump Tables
echo "#";
echo "# Database dump starts at      :" `date "+%d/%m/%Y %H:%M:%S"`;

if [ "$DUMP_TYPE" = "SQL" ]; then
  ${MYSQLDUMP} ${DBCONN} -B ${DATABASE} --user=${USER} --password=${PASS} --compress > ${BCK_FILE}.sql 2>/dev/null
else
  rm -rf ${DATABASE}
  ${MYSQLHOTCOPY} ${DATABASE} --user=${USER} --password=${PASS} --allowold --flushlog ./ 2>/dev/null
fi

################################################################# Backup compression
echo "#";
echo "# Backup compression starts at :" `date "+%d/%m/%Y %H:%M:%S"`;

if [ "$DUMP_TYPE" = "SQL" ]; then
  ${TAR_FILE} ${BCK_FILE}.tgz ${BCK_FILE}.sql
else
  ${TAR_FILE} ${BCK_FILE}.tgz ${DATABASE}
fi

################################################################# Backup copy
echo "#";
echo "# Backup name                  : ${BCK_FILE}.tgz";

if [ "$KEEP_LOCAL" = "YES" ]; then
  echo "# Local copy stored in         : ${BCK_DEST}";
fi

################################################################# Delete temp files
echo "#";
echo "# Deleting temporary files     :" `date "+%d/%m/%Y %H:%M:%S"`;
if [ "$DUMP_TYPE" = "SQL" ]; then
  rm -rf ${BCK_FILE}.sql
else
  rm -rf ${DATABASE}
fi

if [ "$KEEP_LOCAL" != "YES" ]; then
  rm -rf ${BCK_FILE}.tgz
fi

cd ..;

################################################################# Optimize & Repair Database
if [ "$REPAIR" = "YES" ]; then
  echo "#";
  echo "# Optimization tables starts at:" `date "+%d/%m/%Y %H:%M:%S"`;
  ${MYSQLCHECK} -s --auto-repair --optimize ${DBCONN} --user=${USER} --password=${PASS} --databases ${DATABASE} 2>/dev/null
fi

################################################################# Upload backup
if [ "$UPLOAD" = "YES" ]; then
  echo "#";
  echo "# Upload backup starts at:" `date "+%d/%m/%Y %H:%M:%S"`;
  ${MYSQLCHECK} -s --auto-repair --optimize ${DBCONN} --user=${USER} --password=${PASS} --databases ${DATABASE} 2>/dev/null
fi

#################################################################
echo "#";
echo "# Database backup finished at  :" `date "+%d/%m/%Y %H:%M:%S"`;

((BCK_TIME=`date "+%s"`-BCK_START));
echo "# Time elapsed                 :" `date -d@$BCK_TIME -u +%H:%M:%S`;

echo " ";
echo "############################################################################";
echo " ";
