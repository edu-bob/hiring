BINDIR=/usr/local/bin
SMRSHDIR=/etc/smrsh
MAILSCRIPTS=tracker-mail.pl

install:
	@if test -d ${SMRSHDIR} ;\
	then \
		for i in ${MAILSCRIPTS};do\
			install $$i ${SMRSHDIR} ;\
			echo Put this line into you /etc/aliases file: ;\
			echo "tracker:|${SMRSHDIR}/$$i";\
		done;\
	else \
		for i in ${MAILSCRIPTS};do\
			install $$i ${BINDIR} ;\
			echo Put this line into you /etc/aliases file: ;\
			echo "tracker:|${BINDIR}/$$i";\
		done;\
	fi
	@-test -n "${SCRIPTS}" && install ${SCRIPTS} ${BINDIR} || exit 0
clean:
	find . \( -name '*~' \) -o \( -name '*#' \) -exec rm -f '{}' ';'
	rm -f *~ *# tmp tst tst? core.* junk
	rm -f */*~ */*#

tarball:clean
	shopt -s nullglob;d=`pwd`;dir=`basename $$d`;\
	tar -chzf $$dir.tgz *.cgi *.pl *.pm *.html *.css maintenance/ images javascript Makefile INSTALL test scripts

compile:_FORCE
	for i in *.cgi;do perl -c -w $$i;done

watch:_FORCE
	@while true;do inotifywait -e modify -q *.pm *.cgi;sh install-test;sleep 5;done

_FORCE:
