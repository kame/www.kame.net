#
# $Copyright$
#
# $TAHI: ct/mip6-cn-19/Makefile,v 1.1 2003/01/07 02:19:49 akisada Exp $
#
################################################################

INSTALL_DIR = $(PREFIX)/ct/mip6-cn-19
XFILES      = *.seq *.pm
FILES       = *.def *.html INDEX .footer

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 555 $(XFILES)     $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(FILES)      $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "Makefile.test"
