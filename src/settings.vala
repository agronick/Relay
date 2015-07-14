/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * settings.vala
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
 *
 * Relay is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Relay is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using GLib;
using Gtk;
using Gee;
using Gdk;
using Pango;

public class Settings : GLib.Object {

    const string[] switch_names = {"show_animations", "show_join", "show_sidebar", "open_server", "show_datestamp", "change_tab"};
    const string[] color_names = {"user-self-color", "user-other-color", "message-color", "link-color", "timestamp-color"};
    HashMap<string, string> colors_defaults = new HashMap<string, string>();
    GLib.Settings settings;
    Gtk.Window window = null;

    public signal void changed_color();
    
    construct {
        settings = new GLib.Settings("org.agronick.relay");
        set_colors_defaults();
    }
    
    public bool show_window () {
        if (window is Widget && window.visible) {
            window.present();
            return true;
        }
		var builder = new Builder();
        try {
		    builder.add_from_file(Relay.get_asset_file(MainWindow.UI_FILE_SETTINGS));
		} catch (Error e){
			error("Unable to load UI file " + Relay.get_asset_file(MainWindow.UI_FILE_SETTINGS));
		}
        window = builder.get_object ("window") as Gtk.Window;
        
        foreach (string name in switch_names) {
            var switches = builder.get_object (name) as Switch;
            settings.bind(name.replace("_", "-"), switches, "active", SettingsBindFlags.DEFAULT);
        }

        foreach (string type in color_names) {
            var colors = builder.get_object (type) as Entry;
            settings.bind(type, colors, "text", SettingsBindFlags.DEFAULT);
            colors.button_press_event.connect((event) => {
                if (event.button != 1)
                    return true;
                var picker = new ColorChooserDialog(_("Color Picker"), window);
                picker.response.connect( (id)=> {
                    if (id == ResponseType.OK)
                        colors.text = RGBA_to_hex(picker.get_rgba());
                    picker.close();
                });

                var color = RGBA();
                color.parse(colors.text);
                picker.set_rgba(color);
                picker.show_all();
                return true;
            });
            
            colors.changed.connect( ()=> {
                if (colors.text == "default")
                    colors.text = colors_defaults[type];

                var bg = RGBA();
                bg.parse(colors.text);
                colors.override_color(StateFlags.NORMAL , bg);
                changed_color();
            });

           var reset = builder.get_object (type + "-reset") as Button;
           reset.button_release_event.connect( (event)=> {
               colors.text = "default";
               return false;
           });

            var change_back = colors.text;
            colors.text = "";
            colors.text = change_back;

            var bold = new Pango.FontDescription();
            bold.set_weight(Weight.BOLD);
            colors.override_font(bold);
        }

        var close = builder.get_object ("close") as Button;
        close.button_release_event.connect( (event)=> {
            window.close();
            return true;
        });
        
        window.show_all();
        
        return true;
    }

    public string get_color (string color) {
        var val = settings.get_string(color);
        return (val == "default") ? colors_defaults[color] : val;
    }

    public bool get_bool (string name) {
        return settings.get_boolean(name.replace("_","-"));
    }

    public static string RGBA_to_hex (RGBA rgba) {
        string s =
            "#%02x%02x%02x%02x"
            .printf((uint)(Math.round(rgba.red*255)),
                    (uint)(Math.round(rgba.green*255)),
                    (uint)(Math.round(rgba.blue*255)),
                    (uint)(Math.round(rgba.alpha*255)))
            .up();
        return s;
    }


    public void set_colors_defaults () {
		colors_defaults["user-self-color"] = Relay.is_light_theme ? "#3B1C73" : "#AE81FF";
		colors_defaults["user-other-color"] = Relay.is_light_theme ? "#1D6A77" : "#4EC9DE";
		colors_defaults["message-color"] = Relay.is_light_theme ? "#505050" : "#F8F8F2";
		colors_defaults["link-color"] = Relay.is_light_theme ? "#0000FF" : "#3D81C4";
		colors_defaults["timestamp-color"] = Relay.is_light_theme ? "#181818" : "#D5D5D5";	
    }
}

