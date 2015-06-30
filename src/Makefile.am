## Process this file with automake to produce Makefile.in

## Created by Anjuta


uidir = $(pkgdatadir)/ui
ui_DATA = ui/relay.ui ui/server_window.ui ui/relay.png

assetsdir = $(pkgdatadir)/assets
assets_DATA = ui/relay.png \
	assets/server_icon.png

appicondir = $(datadir)/icons/hicolor/scalable/apps
appicon_DATA = ui/relay.png

desktopdir = $(datadir)/applications
desktop_DATA = ../relay.desktop

AM_CPPFLAGS = \
    -DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
    -DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
    -DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
    -DGETTEXT_PACKAGE=\""relay"\"\
    $(RELAY_CFLAGS)

AM_CFLAGS =\
     -Wall\
     -g

bin_PROGRAMS = relay

relay_SOURCES = \
    config.vapi \
    connection.vala \
    main_window.vala \
    sqlclient.vala \
    server_manager.vala \
    channel_tab.vala \
    message.vala \
    irc.vala \
    relay.vala \
    rich_text.vala

relay_VALAFLAGS =  \
    -X -DGETTEXT_PACKAGE="relay" --target-glib 2.32 --pkg x11 --pkg gtk+-3.0 --pkg glib-2.0 --pkg granite --pkg sqlite3


relay_LDFLAGS = \
	-lX11 -lm -Wl,--export-dynamic

relay_LDADD = $(RELAY_LIBS)
 


EXTRA_DIST = $(ui_DATA) $(assets_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(imagedir)
	-rm -r $(pkgdatadir)

