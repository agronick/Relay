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

public class Kyrc : Object
{

    /*
     * Uncomment this line when you are done testing and building a tarball
     * or installing
     */
    //const string UI_FILE = Config.PACKAGE_DATA_DIR + "/ui/" + "kyrc.ui";
    public const string UI_FILE = "ui/kyrc.ui";
    public const string UI_FILE_SERVERS = "ui/server_window.ui";


    public Window window;
    Granite.Widgets.DynamicNotebook tabs;
    Entry input;
    Paned pannel;
    Button channel_subject;
    TextView subject_text;
    Button add_server_button;
    HeaderBar toolbar;

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

            toolbar = new HeaderBar (); 
            tabs = new Granite.Widgets.DynamicNotebook();
            tabs.allow_drag = true;

            window = builder.get_object ("window") as Window;
            window.destroy.connect(kyrc_close_program);
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
            select_channel.tooltip_text = "Open server/channel view";
            toolbar.pack_start(select_channel);
            select_channel.button_release_event.connect(slide_panel);
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
            

            toolbar.pack_end(channel_subject);

            servers.item_selected.connect(set_item_selected);

            set_up_add_sever(toolbar);

            toolbar.set_title("Kyrc");
            toolbar.show_all();

            toolbar.show_close_button = true;
            window.set_titlebar(toolbar);
            /* ANJUTA: Widgets initialization for kyrc.ui - DO NOT REMOVE */
            window.show_all ();
 
            tabs.new_tab_requested.connect(new_tab_requested);
            tabs.tab_removed.connect(remove_tab);
            tabs.tab_switched.connect(tab_switch); 

            SqlClient.get_instance();
            
            refresh_server_list(); 

            load_autoconnect();
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
			
			if (newTab.is_server_tab)
				newTab.tab.working = true;
            TextView output = new TextView(); 
            output.set_editable(false);
            output.set_cursor_visible(false);
            output.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            output.set_left_margin(IRC.USER_WIDTH);
            output.set_indent(IRC.USER_WIDTH * -1);
            output.modify_font(FontDescription.from_string("Inconsolata 9"));
            ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.shadow_type = ShadowType.IN;
            scrolled.margin = 3;
            scrolled.add(output);

            var ptabs = new Pango.TabArray(1, true);
            ptabs.set_tab(0, Pango.TabAlign.LEFT, 100);
            output.tabs = ptabs;

            newTab.tab.label = newTab.channel_name; 
            newTab.tab.page = scrolled;
            newTab.new_subject.connect(new_subject);
            tabs.insert_tab(newTab.tab, -1); 
            
            debug("Setting index " + newTab.channel_name + ":" + index.to_string()); 

            newTab.set_output(output);
            outputs.set(index, newTab); 

            tabs.show_all();
            
            newTab.tab_index = index;

            if (tabs.n_tabs == 0) {
                tab_switch (null, newTab.tab);
            }
            
            index++;
            return false;
        });
        if (!newTab.is_server_tab) {
            newTab.server.send_output("TOPIC " + newTab.channel_name);
        }
    }
    
    private void remove_tab (Widgets.Tab tab) {  
        if(tab.label == _("Welcome"))
            return;
        
        int id = lookup_channel_id(tab);
        var tab_server = outputs[id].server; 
        
        if (!outputs[id].is_server_tab)
            tab_server.send_output("LEAVE " + outputs[id].channel_name);
        
        tab_server.channel_tabs.unset(tab.label);
        
        if (tab_server.channel_tabs.size < 1) {
            debug("Closing server");
            tab_server.do_exit();
            clients.unset(index);
        }
        
        foreach (var item in outputs.entries) {
            if (item.value.tab == tab) {
                outputs.unset(item.key);
                break;
            }
        }

        if (tabs.n_tabs == 0)
            show_welcome_screen();
    }

    public void new_tab_requested () {
                var dialog = new Dialog.with_buttons(_("New Connection"), window,
                                                     DialogFlags.DESTROY_WITH_PARENT,
                                                     "Connect", Gtk.ResponseType.ACCEPT,
                                                     "Cancel", Gtk.ResponseType.CANCEL);
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
                                var server = new SqlClient.Server();
                                server.host = name;
                                add_server(server);
                                dialog.close();
                            }
                            break;
                        case Gtk.ResponseType.CANCEL:
                            dialog.close();
                            break;
                    }
                });
    }
    
    private void tab_switch (Granite.Widgets.Tab? old_tab, Granite.Widgets.Tab new_tab) {
        current_tab = lookup_channel_id(new_tab);
        if (!outputs.has_key(current_tab))
            return;
        var using_tab = outputs[current_tab];
        if (using_tab.has_subject) { 
            new_subject (current_tab, using_tab.channel_subject);
        } else {
            channel_subject.hide();
        }
        toolbar.set_title(using_tab.tab.label);
    }

    public void add_server (SqlClient.Server server, ArrayList<string>? connect_channels = null) {
        var client = new Connection(this);
        client.username =  server.username;
        clients.set(index, client); 

        if (connect_channels != null)
            client.channel_autoconnect = connect_channels;

		client.connect_to_server(server.host);
        
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

    private void item_activated () {
        string type = current_selected_item.get_data<string>("type");
        if (type == "server") {
            //Has existing server
            SqlClient.Server server = current_selected_item.get_data<SqlClient.Server>("server");
            foreach (var tab in outputs.entries) {
                if (tab.value.is_server_tab && tab.value.channel_name == server.host) {
                    tabs.current = tab.value.tab;
                    return;
                }
            }
            //No existing server
            add_server(server);
        } else {
            //Existing channel tab
            SqlClient.Channel channel = current_selected_item.get_data<SqlClient.Channel>("channel");
            debug("Looking up " + channel.channel);
            var server = SqlClient.servers[channel.server_id];
            foreach (var tab in outputs.entries) {
                debug("Looping at " + tab.value.channel_name);
                if (!tab.value.is_server_tab && tab.value.tab.label == channel.channel && server.host == tab.value.server.url) {
                    debug("Switching to " + tab.value.tab.label);
                    tabs.current = tab.value.tab;
                    return;
                }
            } 
            //Has existing server but no channel
            foreach (var con in clients.entries) {
                debug("Has existing server but no channel: " + con.value.url + " " + channel.channel);
                if (con.value.url == server.host) {
                    con.value.join(channel.channel);
                    return;
                }
            }
            //Has no existing server or channel
            ArrayList<string> channels = new ArrayList<string>();
            channels.add(channel.channel);
            add_server(SqlClient.servers[channel.server_id], channels);
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

    public int lookup_channel_id (Widgets.Tab tab) {
        foreach (var output in outputs.entries) { 
            if (output.value.tab == tab) {
                return output.key;
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

    private void load_autoconnect () {
        bool opened_tab = false;
        
        foreach (var server in SqlClient.servers.entries) {
            if(server.value.autoconnect) {
                opened_tab = true;
                ArrayList<string> to_connect = new ArrayList<string>();
                foreach (var chan in server.value.channels) {
                    to_connect.add(chan.channel);
                }
                add_server(server.value, to_connect);
            }
        }
        
        if (!opened_tab)
            show_welcome_screen();
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

        Gtk.init (ref args);
        var app = new Kyrc ();

        Gtk.main ();

        return 0;
    }

    private void show_welcome_screen () {
        var sm = new ServerManager();
        var title = _("Welcome to Kyrc");
        var message =  _("Lets get started");
        var welcome = new Widgets.Welcome(title, message);
        welcome.append("network-server", _("Manage"), _("Manage the servers you use"));
        welcome.append("list-add", _("Connect"), _("Connect to a single server"));
        welcome.append("network-wired", _("Saved"), _("Connect to a saved server"));

        var tab = new Widgets.Tab();
        tab.label = _("Welcome");
        tab.page = welcome;
        tabs.insert_tab(tab, -1);

        welcome.activated.connect( (index) => {
            switch (index) {
                case 0:
                    sm.open_window();
                    sm.window.destroy.connect( () => {
                        refresh_server_list ();
                    });
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
    
    public void set_up_add_sever (Gtk.HeaderBar toolbar) {
        add_server_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        add_server_button.tooltip_text = _("Add new server");

        var sm = new ServerManager();
        add_server_button.button_release_event.connect( (event) => {
            sm.open_window();
            sm.window.destroy.connect( () => {
                refresh_server_list ();
            });
            return false;
        });

        toolbar.pack_start(add_server_button);
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

    [CCode (instance_pos = -1)]
    public void on_destroy (Widget window) {
        Gtk.main_quit();
    }
}

