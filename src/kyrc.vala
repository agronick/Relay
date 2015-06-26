/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * kyrc.vala
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
 *
 * kyrc is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * kyrc is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using X;

public class Kyrc : Granite.Application {

        private MainWindow window = null;
        public string[] args;

        construct {
            program_name = "Kyrc";
            exec_name = "kyrc";

            build_data_dir = Config.PACKAGE_DATA_DIR;
            build_pkg_data_dir = Config.GETTEXT_PACKAGE;
            build_version = Config.VERSION;

            app_years = "2015";
            app_icon = "kyrc";
            app_launcher = "kyrc.desktop";
            application_id = "net.launchpad.kyrc";

            main_url = "http://poisonpacket.wordpress.com";
            bug_url = "https://bugs.launchpad.net/kyrc";
            help_url = "http://poisonpacket.wordpress.com";
            translate_url = "https://translations.launchpad.net/kyrc";

            about_authors = { "Nathan Dyer <mail@nathandyer.me>" };
            about_documenters = { "Nathan Dyer <mail@nathandyer.me>" };
            about_artists = { "Nathan Dyer (App) <mail@nathandyer.me>", "Harvey Cabaguio (Icons and Branding) <harvey@elementaryos.org", "Mashnoon Ibtesum (Artwork)" };
            about_comments = "Podcast Client for the Modern Desktop";
            about_translators = _("translator-credits");
            about_license_type = Gtk.License.GPL_3_0;

            set_options();
        }


    /* Method definitions */
    public static int main (string[] args) {
        X.init_threads ();

        
        GLib.Log.set_default_handler(handle_log);
        Gtk.init (ref args);

        Kyrc main = new Kyrc();
        main.run(args);
        Gtk.main ();


        return 0;
    }

    public override void activate () {

        // Set Vocal to use the dark theme (if available)
        var settings = Gtk.Settings.get_default();
        settings.gtk_application_prefer_dark_theme = true;

        MainWindow window = new MainWindow();
    }

    public static void handle_log (string? log_domain, LogLevelFlags log_levels, string message) {
        string prefix = "";
        string suffix = "\x1b[39;49m " ;
        switch(log_levels) {
            case LogLevelFlags.LEVEL_DEBUG:
                prefix = "\x1b[94mDebug: ";
                break;
            case LogLevelFlags.LEVEL_INFO:
                prefix = "\x1b[92mInfo: ";
                break;
            case LogLevelFlags.LEVEL_WARNING:
                prefix = "\x1b[93mWarning: ";
                break;
            case LogLevelFlags.LEVEL_ERROR:
                prefix = "\x1b[91mError: ";
                break;
            default:
                prefix = message;
                break;
        }
        GLib.stdout.printf(prefix + message + suffix + "\n");
    }
}

