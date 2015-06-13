## Process this file with automake to produce Makefile.in

## Created by Anjuta


uidir = $(pkgdatadir)/ui
ui_DATA = ui/kyrc.ui ui/server_window.ui

assetsdir = $(pkgdatadir)/assets
assets_DATA = assets/server_run.png

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
	kyrc.vala config.vapi client.vala sqlclient.vala server_manager.vala channel_item.vala channel_tab.vala message.vala

kyrc_VALAFLAGS =  \
	--pkg gtk+-3.0 --pkg glib-2.0 --pkg gee-0.8 --pkg granite --pkg sqlite3 --target-glib 2.32  -g --save-temps --Xcc=-X --Xcc=-w


kyrc_LDFLAGS = \
	-Wl,--export-dynamic

kyrc_LDADD = $(KYRC_LIBS)
 


EXTRA_DIST = $(ui_DATA) $(assets_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(imagedir)
	-rm -r $(pkgdatadir)

