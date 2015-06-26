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
    -DGETTEXT_PACKAGE=\""kyrc"\"\
    $(KYRC_CFLAGS)

AM_CFLAGS =\
     -Wall\
     -g

bin_PROGRAMS = kyrc

kyrc_SOURCES = \
    config.vapi connection.vala main_window.vala sqlclient.vala server_manager.vala channel_tab.vala message.vala irc.vala kyrc.vala rich_text.vala

kyrc_VALAFLAGS =  \
    --target-glib 2.32 --pkg x11 --pkg gtk+-3.0 --pkg glib-2.0 --pkg granite --pkg sqlite3  -g --save-temps


kyrc_LDFLAGS = \
	-lX11 -lm -Wl,--export-dynamic

kyrc_LDADD = $(KYRC_LIBS)
 


EXTRA_DIST = $(ui_DATA) $(assets_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(imagedir)
	-rm -r $(pkgdatadir)

