## Process this file with automake to produce Makefile.in

## Created by Anjuta


uidir = $(pkgdatadir)/ui
ui_DATA = kyrc.ui


AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(KYRC_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = kyrc

kyrc_SOURCES = \
	kyrc.vala config.vapi client.vala

kyrc_VALAFLAGS =  \
	--pkg gtk+-3.0 --pkg glib-2.0 --pkg gee-0.8 -g --save-temps


kyrc_LDFLAGS = \
	-Wl,--export-dynamic

kyrc_LDADD = $(KYRC_LIBS)




EXTRA_DIST = $(ui_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(pkgdatadir)

