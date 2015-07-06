## Process this file with automake to produce Makefile.in
## Created by Anjuta

SUBDIRS = src 

ACLOCAL_AMFLAGS=-I m4

dist_doc_DATA = \
	README.md \
	COPYING \
	AUTHORS \
	ChangeLog \
	INSTALL

# Remove doc directory on uninstall
uninstall-local:
	-rm -r $(docdir)
