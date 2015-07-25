dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(relay, 0.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11 foreign])

AC_CONFIG_MACRO_DIR([m4])

AM_SILENT_RULES([yes])

AC_PROG_CC

GLIB_GSETTINGS


LT_INIT

dnl Check for vala
AM_PROG_VALAC([0.10.0])


PKG_CHECK_MODULES(RELAY, granite
sqlite3
gee-0.8
glib-2.0
[gtk+-3.0 ])


AC_OUTPUT([
Makefile
src/Makefile
])
