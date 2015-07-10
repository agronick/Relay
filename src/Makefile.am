## Process this file with automake to produce Makefile.in

## Created by Anjuta


uidir = $(pkgdatadir)/ui
ui_DATA = ui/relay.ui ui/server_window.ui ui/relay.png

assetsdir = $(pkgdatadir)/assets
assets_DATA = ui/relay.png \
	assets/server_icon.png \
    assets/paste.png \
    assets/theme.css

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
    main_window.vala \
    sqlclient.vala \
    server_manager.vala \
    channel_tab.vala \
    message.vala \
    irc.vala \
    relay.vala \
    connection.vala \
    rich_text.vala \
    drag_file.vala

relay_VALAFLAGS =  \
    -X -DGETTEXT_PACKAGE="relay" --target-glib 2.32  --pkg gee-0.8 --pkg x11 --pkg gtk+-3.0 --pkg glib-2.0 --pkg granite --pkg sqlite3

relay_LDFLAGS = \
	 -lm -lX11 -lglib-2.0 -Wl,--as-needed

relay_LDADD = -lm -lX11 $(RELAY_LIBS)
 


EXTRA_DIST = $(ui_DATA) $(assets_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(imagedir)
	-rm -r $(pkgdatadir)

