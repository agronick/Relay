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
        public static bool on_kde = false;
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

        string[] files = {
            "/usr/share/themes/relay/apps.css",
            "/usr/share/themes/relay/gtk-dark.css",
            "/usr/share/themes/relay/gtk-widgets-dark.css"
        };
        Gtk.rc_set_default_files(files);

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
        
        if (on_ubuntu) {
            Gtk.Settings.get_default().gtk_theme_name = "Adwaita";
        }

        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;

        window = new MainWindow(this);
        Gtk.main ();
    }

    public static string get_asset_file (string name) {
        string[] checks = {"./" + name,
                           "src/" + name,
                            "../src/" + name,
                            "./*/src/" + name,
                            Config.PACKAGE_DATA_DIR + "/" + name,};
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
		}else if (output != null && (output.contains ("Unity") || output.contains ("XFCE"))) {
            on_ubuntu = true;
        } else if (output == "KDE") {
            on_kde = true;
        }
	}

	private static bool error_open = false;
    public static void show_error_window (string error_msg) {
		if (error_open)
			return;
        Idle.add( ()=> {
            Gtk.MessageDialog dialog = new Gtk.MessageDialog (MainWindow.window, 
                                                       Gtk.DialogFlags.MODAL, 
                                                       Gtk.MessageType.WARNING, 
                                                       Gtk.ButtonsType.OK, 
                                                       _(error_msg));
            dialog.response.connect ((response_id) => {
			    error_open = false;
                dialog.destroy();
            });
            dialog.show ();
			error_open = true;
            return false;
        });
    }

    public static double ease_out_elastic (float t,float b , float c, float d) {
	    if (t==0) return b;  if ((t/=d)==1) return b+c;  
	    float p=d*0.3f;
	    float a=c; 
	    float s=p/4;
	    double val = ((a*Math.pow(2,-16*t)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + c + b;
        return val;
    }
    
    public static float ease_in_bounce (float t,float b , float c, float d) {
	    return c - ease_out_bounce(d-t, 0, c, d) + b;
    }
    
    public static float ease_out_bounce (float t,float b , float c, float d) {
	    if ((t/=d) < (1/2.75f)) {
		    return c*(7.5625f*t*t) + b;
	    } else if (t < (2/2.75f)) {
		    float postFix = t-=(1.5f/2.75f);
		    return c*(7.5625f*(postFix)*t + 0.75f) + b;
	    } else if (t < (2.5/2.75)) {
			    float postFix = t-=(2.25f/2.75f);
		    return c*(7.5625f*(postFix)*t + 0.9375f) + b;
	    } else {
		    float postFix = t-=(2.625f/2.75f);
		    return c*(7.5625f*(postFix)*t + 0.984375f) + b;
	    }
    }


/*
     * easing functions terms of use
TERMS OF USE - EASING EQUATIONS
pen source under  the <a href="http://www.opensource.org/licenses/bsd-license.php">BSD License</a>. <br>

Copyright © 2001 Robert Penner
All rights reserved.
Redistribution and use in source and binary forms,
with or without modification, are permitted provided that the following
conditions are met:

Redistributions of source code must retain the above copyright  notice, this list of
conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of
conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

Neither the name of the author nor the names of contributors may be used to
endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS
AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

}

