/***
  Copyright (C) 2011-2012 Application Name Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see
***/

using GLib;
using Gtk;
using Gee;
using Granite;
using Pango; 
using Config;
 
 

public class Kyrc : Object
{ 

    
	/*
	 * Uncomment this line when you are done testing and building a tarball
	 * or installing
	 */
	//const string UI_FILE = Config.PACKAGE_DATA_DIR + "/ui/" + "kyrc.ui";
	public const string UI_FILE = "ui/kyrc.ui";
	public const string UI_FILE_SERVERS = "ui/server_window.ui";

	/* ANJUTA: Widgets declaration for kyrc.ui - DO NOT REMOVE */

	Granite.Widgets.DynamicNotebook tabs;
	Window window;
	Entry input;
	Paned pannel;
    Button channel_subject;
    TextView subject_text;

	Gee.HashMap<int, ChannelTab> outputs = new Gee.HashMap<int, ChannelTab> ();
	Gee.HashMap<int, Connection> clients = new Gee.HashMap<int, Connection> (); 
	Granite.Widgets.SourceList servers = new Granite.Widgets.SourceList();

    public static bool on_elementary = false;
    public static int current_tab = -1;


	public Kyrc () {
		try
		{
			Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);
            check_elementary();

			var builder = new Builder ();
			builder.add_from_file (get_asset_file(UI_FILE));
			builder.connect_signals (this);

			var toolbar = new Gtk.HeaderBar (); 
			tabs = new Granite.Widgets.DynamicNotebook();
			tabs.allow_drag = true;

			window = builder.get_object ("window") as Window;
			var nb_wrapper = builder.get_object("notebook_wrapper") as Box;
			nb_wrapper.pack_start(tabs, true, true, 0); 
            tabs.set_size_request(500, 20);
            tabs.show_all(); 

			pannel = builder.get_object("pannel") as Paned;
			var server_list_container = builder.get_object("server_list_container") as Box;
			server_list_container.pack_start(servers, true, true, 0);

			Image icon = new Image.from_file("src/assets/server_run.png");
			var select_channel = new Gtk.Button();
			select_channel.image = icon;
			select_channel.tooltip_text = _("Open server/channel view");
			pannel.position = 1;

			input = builder.get_object("input") as Entry; 
			input.activate.connect (() => {
				send_text_out(input.get_text ());
				input.set_text("");
			});

            if(on_elementary)
            	channel_subject = new Gtk.Button.from_icon_name("help-info-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
	        else
     		    channel_subject = new Gtk.Button.from_icon_name("text-x-generic", Gtk.IconSize.SMALL_TOOLBAR);
            channel_subject.tooltip_text = _("Channel subject");
            var subject_popover = new Gtk.Popover(channel_subject);
            channel_subject.clicked.connect(() => {
                subject_popover.show_all();
            });
            channel_subject.set_no_show_all(true);
            channel_subject.hide();
		  	var scrolled = new Gtk.ScrolledWindow(null, null);
		  	subject_text = new Gtk.TextView();
		  	subject_text.set_wrap_mode(Gtk.WrapMode.WORD);
		  	subject_text.buffer.text = "";
		  	subject_text.cursor_visible = false;
		  	subject_text.editable = false;
		  	subject_text.margin = 10;
		  	scrolled.set_size_request(320, 110);
		  	scrolled.add(subject_text);
		  	subject_popover.add(scrolled); 

			toolbar.pack_start(select_channel);
            toolbar.pack_end(channel_subject); 
			toolbar.show_close_button = true;
			toolbar.set_title("Kyrc");
			toolbar.show_all(); 
			set_up_add_sever(toolbar);
			window.set_titlebar(toolbar);


			/* ANJUTA: Widgets initialization for kyrc.ui - DO NOT REMOVE */
			window.show_all ();
 
			tabs.new_tab_requested.connect(new_channel); 
			tabs.tab_removed.connect(remove_tab);
            tabs.tab_switched.connect(tab_switch); 
			servers.item_selected.connect(set_item_selected);
            window.destroy.connect(kyrc_close_program);
			select_channel.button_release_event.connect(slide_panel);

            SqlClient.get_instance();
            show_welcome_screen();  
            
			refresh_server_list(); 
 
		}
		catch (Error e) {
			error("Could not load UI: %s\n", e.message);
		}

	}

	private static Granite.Widgets.SourceList.Item current_selected_item;
	private void set_item_selected (Granite.Widgets.SourceList.Item? item) {
		current_selected_item = item;
	}

	public static int index = 0;
	public void add_tab (ChannelTab newTab) {

        
		Idle.add( () => { 
            newTab.tab = new Granite.Widgets.Tab(); 
            TextView output = new TextView(); 
            output.set_editable(false);
            output.set_cursor_visible(false);
            output.set_wrap_mode (Gtk.WrapMode.WORD);
            output.set_left_margin(100);
            output.modify_font(FontDescription.from_string("Inconsolata 9"));
            ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.shadow_type = ShadowType.IN;
            scrolled.margin = 3;
            scrolled.add(output);

			var ptabs = new Pango.TabArray(1, true);
    		ptabs.set_tab(0, Pango.TabAlign.LEFT, 100);
    		output.tabs = ptabs;
			output.indent = -100;
			output.left_margin = 100; 

			newTab.tab.label = newTab.channel_name; 
			newTab.tab.page = scrolled;
            newTab.new_subject.connect(new_subject);
			tabs.insert_tab(newTab.tab, -1); 
            
            debug("Setting index " + newTab.channel_name + ":" + index.to_string()); 

			newTab.set_output(output);
			outputs.set(index, newTab); 

			tabs.show_all();
            
		    newTab.tab_index = index;

            if (index == 0) {
                tab_switch (null, newTab.tab);
            }
            
            index++;

            
			return false;
		});
	}


	public void add_server (string url) {
		var client = new Connection(this);
		client.username = "kyle123456";
		clients.set(index, client); 
		client.connect_to_server(url);
	}

	public void add_text (ChannelTab tab, Message message) {
        tab.display_message(message);
	}

	public void send_text_out (string text) {
        if(current_tab == -1 || !outputs.has_key(current_tab))
            return;
        var output = outputs[current_tab];  
        output.send_text_out(text);
        
        var message = new Message();

        //Append message to screen
        message.user_name_set(output.server.username);
        message.message = text;
        message.command = "PRIVMSG";
        message.internal = true;
        add_text(output, message); 
        return; 
    }

	public void refresh_server_list () {
		var root = servers.root;
		root.clear();
		foreach (var svr in SqlClient.servers.entries) {
			var s =  new Granite.Widgets.SourceList.ExpandableItem(svr.value.host);
			root.add(s);
			var chn = new Granite.Widgets.SourceList.Item (svr.value.host);
			chn.set_data<string>("type", "server");
			chn.set_data<SqlClient.Server>("server", svr.value);
			chn.activated.connect(item_activated);
			s.add(chn);
			foreach (var c in svr.value.channels) {
				chn = new Widgets.SourceList.Item (c.channel);
				chn.set_data<string>("type", "channel");
				chn.set_data<SqlClient.Channel>("channel", c);
				chn.activated.connect(item_activated);
				s.add(chn);
			}
		}
	}

	private void item_activated () {
		string type = current_selected_item.get_data<string>("type");
		if (type == "server") {
			SqlClient.Server svr = current_selected_item.get_data<SqlClient.Server>("server");
			foreach (var tab in outputs.entries) {
				if (tab.value.is_server_tab && tab.value.channel_name == svr.host) {
					tabs.current = tab.value.tab;
					return;
				}
			}
		} else {
			SqlClient.Channel channel = current_selected_item.get_data<SqlClient.Channel>("channel");
			foreach (var tab in outputs.entries) {
				if (!tab.value.is_server_tab && tab.value.channel_name == channel.channel) {
					tabs.current = tab.value.tab;
					return;
				}
			}
		}

	} 

	public bool slide_panel () {
		new Thread<int>("slider_move", move_slider_t);
		return false;
	}

	public int move_slider_t () {
		int add, end;
		bool opening;
		if (pannel.position < 10) {
			opening = true;
			add = 1;
			end = 150;
		} else {
			opening = false;
			add = -1;
			end = 0;
		}
		for (int i = pannel.position; (opening) ? i < end : end < i; i+= add) {
			pannel.set_position(i);
			Thread.usleep(3600);
		}
		return 0;
	}

	public void set_up_add_sever (Gtk.HeaderBar toolbar) {
		var add_server_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		add_server_button.tooltip_text = "Add new server"; 
		add_server_button.button_release_event.connect( (event) => {
            show_server_view();
			return false;
		});

		toolbar.pack_start(add_server_button);
	}

    public void show_server_view () {
            var sm = new ServerManager();
			sm.open_window();
			sm.window.destroy.connect( () => {
				refresh_server_list ();
			}); 
    }
    
	private void remove_tab (Widgets.Tab tab) {  
        if(tab.label == _("Welcome"))
            return;
        
        int id = lookup_channel_id(tab);
        var tab_server = outputs[id].server; 
        tab_server.channel_tabs.unset(tab.label);
        
        if (tab_server.channel_tabs.size < 1) {
            debug("Closing server");
            tab_server.do_exit();
        }
        
        outputs.unset(index);
        clients.unset(index);

        if (tabs.n_tabs == 0)
            show_welcome_screen();
	}

    public int lookup_channel_id (Widgets.Tab tab) {
        foreach (ChannelTab output in outputs) { 
            if (output.tab == tab) {
                return output.tab_index;
            }
        }
        return -1;
    }

    private void new_subject (int tab_id, string message) {
        if (tab_id != current_tab || message.strip().length == 0) {
            channel_subject.set_no_show_all(true); 
            channel_subject.hide();
            return;
        }
        
        subject_text.buffer.set_text(message);
        channel_subject.set_no_show_all(false); 
        channel_subject.show_all(); 
    }

    private void tab_switch (Granite.Widgets.Tab? old_tab, Granite.Widgets.Tab new_tab) {
        current_tab = lookup_channel_id(new_tab); 
        if (current_tab == -1)
            return;
        var using_tab = outputs[current_tab];
        if (using_tab.has_subject) { 
            new_subject (current_tab, using_tab.channel_subject);
        } else {
            channel_subject.hide();
        }
    }

    public void new_channel () {
        var dialog = new Dialog.with_buttons(_("New Connection"), window,
                                             DialogFlags.DESTROY_WITH_PARENT,
                                             _("Connect"), Gtk.ResponseType.ACCEPT,
                                             _("Cancel"), Gtk.ResponseType.CANCEL);
        Gtk.Box content = dialog.get_content_area() as Gtk.Box;
        content.pack_start(new Label(_("Server address")), false, false, 5);
        var server_name = new Entry();
        server_name.activate.connect(() => {
            dialog.response(Gtk.ResponseType.ACCEPT);
        });
        content.pack_start(server_name, false, false, 5);
        dialog.show_all();
        dialog.response.connect((id) => {
            switch (id){
                case Gtk.ResponseType.ACCEPT:
                    string name = server_name.get_text().strip();
                    if (name.length > 2) {
                        add_server(name);
                        dialog.close();
                    }
                    break;
                case Gtk.ResponseType.CANCEL:
                    dialog.close();
                    break;
            }
        });
    }

	[CCode (instance_pos = -1)]
	public void on_destroy (Widget window) {
		Gtk.main_quit();
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
		stdout.printf(prefix + message + suffix + "\n");
	}

	public static string get_asset_file (string name) {
		string check = Config.PACKAGE_DATA_DIR + name;
		File file = File.new_for_path (check);
		if (file.query_exists())
			return check;

		check = "src/" + name;
		file = File.new_for_path (check);
		if (file.query_exists())
			return check;

		check =  name;
		file = File.new_for_path (check);
		if (file.query_exists())
			return check;

		error("Unable to find UI file.");
	}

	static int main (string[] args) {
		GLib.Log.set_default_handler(handle_log);
        debug(Config.PACKAGE_LOCALE_DIR);
        return 0;
        
        Intl.setlocale(LocaleCategory.MESSAGES, "");
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "utf-8");  
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
        Intl.textdomain (Config.GETTEXT_PACKAGE);
        

		Gtk.init (ref args);
		var app = new Kyrc ();

		Gtk.main ();
        

        return 0;
    }

    private void show_welcome_screen () {
        var title = "Welcome to Kyrc";
        var message =  "Lets get started";
        var welcome = new Widgets.Welcome(title, message);
        welcome.append("network-server", "Manage", "Manage the servers you use");
        welcome.append("list-add", "Connect", "Connect to a single server");
        welcome.append("network-wired", "Saved", "Connect to a saved server");

        var tab = new Widgets.Tab();
        tab.label = "Welcome";
        tab.page = welcome;
        tabs.insert_tab(tab, -1);

        welcome.activated.connect( (index) => {
            switch (index) {
                case 0:
                    show_server_view();
                    return;
                case 1:
                    tabs.new_tab_requested();
                    return;
                case 2:
                    slide_panel();
                    return;
            }
        });
    }

    private void check_elementary () {
        string output;
        output = GLib.Environment.get_variable("XDG_CURRENT_DESKTOP");

        if (output != null && output.contains ("Pantheon")) {  
            on_elementary = true;
        }
    }

    public void kyrc_close_program () { 
        foreach(Connection client in clients) {
            client.do_exit();
        }
        GLib.Process.exit(0);
    }
}

