# Makefile for procimap -- era Tue Jan 10 16:48:13 2006
# $Id: GNUmakefile,v 1.2 2006-01-25 19:49:20 era Exp $
#
# Depends:
#  GNU make

.PHONY: all
all: build


ifneq '$(shell ls Makefile.conf 2>/dev/null)' ''
include Makefile.conf
endif


.PHONY: build
build: procimap.in Makefile.conf.in
	$(MAKE) -$(MAKEFLAGS) procimap procimap.1 procimaprc.ex


procimap Makefile.conf: procimap.in Makefile.conf.in
	./build.pl

procimap.1: procimap
	# Grr, fix all those stupid pod2man default values
	pod2man --center=" " \
		--date=`sed -n 's/our \$$VERSION *= *\([.0-9]*\).*/\1/p' $<` \
		--release=`perl -e '@a=(1900,1,0); @e=(5,4,3); \
			@g=gmtime((stat($$ARGV[0]))[9]); \
				printf "%04i-%02i-%02i", \
					map { $$g[$$e[$$_]]+$$a[$$_] } (0..2)'\
						$<` $< >$@

procimaprc.ex: procimap
	./pod2example $< >$@




procimap.in Makefile.conf.in:  #procimap Makefile.conf
	./build.pl --reverse

.PHONY: install
install: procimap procimap.1 procimap.rc
	test -r Makefile.conf
	install procimap    $(DESTDIR.BIN)
	install procimap.1  $(DESTDIR.MAN1)
	install procimap.rc $(DEST.WRAPPER)

######## TODO: uninstall



.PHONY: clean
clean:
	$(RM) procimap.1 procimaprc.ex
.PHONY: realclean
realclean: clean
	-git checkout procimap Makefile.conf
	./build.pl --reverse
	$(RM) procimap Makefile.conf \
		debian/files \
		debian/procimap.debhelper.log debian/procimap.substvars
	$(RM) -r debian/procimap
.PHONY: distclean
distclean: realclean
	$(RM) procimap-*.tar.gz
