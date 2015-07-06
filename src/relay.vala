/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * relay.vala
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
 *
 * relay is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * relay is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using X;
using GLib;

public class Relay : Granite.Application {

        private MainWindow window = null;
        public string[] args;
        public static bool has_activated = false;
	    public static bool on_elementary = false;
	    public static bool on_ubuntu = false;
        public static string path;

    
        construct {
            
            program_name = "Relay";
            exec_name = "relay";

            build_data_dir = Config.PACKAGE_DATA_DIR;
            build_pkg_data_dir = Config.GETTEXT_PACKAGE;
            build_version = Config.VERSION;

            app_years = "2015";
            app_icon = "relay";
            app_launcher = "relay.desktop";
            application_id = "net.launchpad.relay";

            main_url = "https://poisonpacket.wordpress.com/relay/";
            bug_url = "https://bugs.launchpad.net/relay";
            help_url = "https://poisonpacket.wordpress.com/relay/";
            translate_url = "https://translations.launchpad.net/relay";

            about_authors = { "Kyle Agronick <agronick@gmail.com>" };
            about_documenters = { "Kyle Agronick <agronick@gmail.com>" };
            about_artists = { "Kyle Agronick (App) <agronick@gmail.com>" };
            about_comments = "IRC Client for the Modern Desktop";
            about_translators = "translator-credits";
            about_license_type = Gtk.License.GPL_3_0;

            set_options();

            Intl.setlocale(LocaleCategory.MESSAGES, "");
            Intl.textdomain(Config.GETTEXT_PACKAGE); 
            Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "utf-8"); 
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, "./locale");
            
        }


    /* Method definitions */
    public static void main (string[] args) {

        path = args[0];
        
        X.init_threads ();
        Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);
        
        GLib.Log.set_default_handler(handle_log);

        var main = new Relay();
        main.run(args);
    }

    public override void activate () {

        if (has_activated) {
            MainWindow.window.present();
            return;
        }

        has_activated = true;
        
		check_elementary();

        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
        if (on_ubuntu) {
            Gtk.Settings.get_default().gtk_icon_theme_name = "Adwaita";
        }

        window = new MainWindow(this);
        Gtk.main ();
    }

    public static string get_asset_file (string name) {
        string[] checks = {"./" + name,
                           "src/" + name,
                            "../src/" + name,
                            Config.PACKAGE_DATA_DIR + "/" + name,
                            "./*/src/" + name,};
        foreach(string check in checks) {                   
            File file = File.new_for_path (check);
            if (file.query_exists())
                return check;
        }
        error("Unable to find asset file: " + name);
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

	private void check_elementary () {
		string output;
		output = GLib.Environment.get_variable("XDG_CURRENT_DESKTOP");

		if (output != null && output.contains ("Pantheon")) {  
			on_elementary = true;
		}else if (output != null && output.contains ("Unity")) {
            on_ubuntu = true;
        }
	}
}

