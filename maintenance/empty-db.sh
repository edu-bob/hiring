#!/bin/sh
version=`mysql -s -B -e "select value from param where name = 'verion'"`
if test -z "$version";then
   echo "Warning: DB version not edefined in the param table."
   version=1
fi

mysqldump --add-drop-table hiring > create-full.sql

mysqldump --add-drop-table hiring --no-data > create-empty.sql

mysql hiring <<EOF
source create-empty.sql
INSERT INTO param (name,value) VALUES ('version',$version);
INSERT INTO user VALUES (1,'Bob Brown','VP of Product Development','root@localhost','Y',NULL,'Y','Y');
EOF
