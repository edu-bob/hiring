DB=../scripts/db-params

all:	create-schema.sql load-tables.sql

create-schema.sql:_FORCE
	-test -f create.sql && mv create.sql create.sql.old
	mysqldump \
	--host=`${DB} -h`\
	--user=`${DB} -u` \
	--password=`${DB} -p` \
	--quick --no-data --complete-insert `${DB} -n` > create-schema.sql

load-tables.sql:_FORCE
	(mysqldump \
	--host=`${DB} -h`\
	--user=`${DB} -u` \
	--password=`${DB} -p` \
	--complete-insert \
	--no-create-info \
	`${DB} -n` param action action_category department;\
	cat ROOT-USER ) > load-tables.sql

_FORCE:
