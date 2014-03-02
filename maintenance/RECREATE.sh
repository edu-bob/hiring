#!/bin/sh
PATH=$PATH:/usr/local/mysql/bin
DATABASE=`pwd|sed 's|.*/\([a-zA-Z0-9_]*\)/maintenance|\1|'`
(cat create-db.sh
 echo "mysql $DATABASE <<'EOF'"
 mysqldump --add-drop-table -c -l -u$DATABASE -pmodeln $DATABASE
 echo EOF) > CREATE-LOAD.sh
