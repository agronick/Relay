/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.c
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
     * 
 * KyRC is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
     * 
 * KyRC is distributed in the hope that it will be useful, but
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
using Granite;

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

    Gee.HashMap<int, ChannelTab> outputs = new Gee.HashMap<int, ChannelTab> ();
    Gee.HashMap<int, Client> clients = new Gee.HashMap<int, Client> ();
    Granite.Widgets.SourceList servers = new Granite.Widgets.SourceList();



    public Kyrc ()
    { 

        try 
        {
            Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);

            var builder = new Builder ();
            builder.add_from_file (get_asset_file(UI_FILE));
            builder.connect_signals (this);

            var toolbar = new Gtk.HeaderBar (); 
            tabs = new Granite.Widgets.DynamicNotebook(); 
            tabs.allow_drag = true; 

            window = builder.get_object ("window") as Window;
            var nb_wrapper = builder.get_object("notebook_wrapper") as Box;
            nb_wrapper.pack_start(tabs, true, true, 1);


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

            refresh_server_list();

            set_up_add_sever(toolbar);

            toolbar.set_title("Kyrc"); 
            toolbar.show_all();

            toolbar.show_close_button = true;
            window.set_titlebar(toolbar);
            /* ANJUTA: Widgets initialization for kyrc.ui - DO NOT REMOVE */
            window.show_all ();  

            add_server("irc.freenode.net");

            tabs.new_tab_requested.connect(() => {
                var dialog = new Dialog.with_buttons("New Connection", window, 
                                                     DialogFlags.DESTROY_WITH_PARENT,
                                                     "Connect", Gtk.ResponseType.ACCEPT,
                                                     "Cancel", Gtk.ResponseType.CANCEL);
                Gtk.Box content = dialog.get_content_area() as Gtk.Box;
                content.pack_start(new Label("Server address"), false, false, 5);
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
                            if(name.length > 2)
                        {
                            add_server(name);
                            dialog.close();
                        }
                            break;
                        case Gtk.ResponseType.CANCEL:
                            dialog.close();
                            break;
                    }
                });
            });
            tabs.tab_removed.connect(remove_tab);
        } 
        catch (Error e) {
            error("Could not load UI: %s\n", e.message);
        } 

    }

    public static int index = 0;
    public void add_tab(ChannelTab newTab)
    {  
        Idle.add( () => {  
            TextView output = new TextView();  
            ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null); 
            scrolled.shadow_type = ShadowType.IN;
            scrolled.add(output); 
            output.set_editable(false); 
            output.set_cursor_visible(false);
            output.set_wrap_mode (Gtk.WrapMode.WORD); 

            var tab = new Granite.Widgets.Tab(); 
            tab.label = newTab.channel_name;

            tab.page = scrolled;
            tabs.insert_tab(tab, index); 
            index = tabs.get_tab_position(tab);

            newTab.output = output;
            outputs.set(index, newTab); 

            tabs.show_all();
            return false;
        });
        newTab.tab_index = index;

        index++;
    }


    public void add_server(string url)
    {
        var client = new Client(this);  
        client.username = "kyle123456";
        clients.set(index, client);

        client.new_data.connect(add_text);
        client.connect_to_server(url); 
    }

    public static bool is_locked = false;
    public void add_text(ChannelTab tab, Message message)
    {
        TextView tv = tab.output; 
        ScrolledWindow sw = (ScrolledWindow)tv.get_parent(); 
        while(is_locked)
        {
            Thread.usleep(111);
        }
        string data = "";
        int offset = -1;
        TextTag? tag = null;
        Gdk.RGBA rgba;
        switch(message.command)
        {
            case "PRIVMSG":
                data = message.user_name + ": " + message.message + "\n";
                tag = tv.buffer.create_tag(null);
                rgba = Gdk.RGBA();
                rgba.red = 1.0;
                rgba.alpha = 1.0;
                tag.foreground_rgba = rgba;
                offset = message.user_name.length + 1;

                break;
            case Client.RPL_TOPIC: 
                data = message.message + "\n";
                break;
            case "NOTICE":
            case Client.RPL_MOTD:
            case Client.RPL_MOTDSTART:
                data = message.message + "\n";
                break;
        }
        Idle.add( () => {     
            is_locked = true;
            int char_count = tv.buffer.get_char_count();
            TextIter outiter;
            tv.buffer.get_end_iter(out outiter); 
            tv.buffer.insert(ref outiter, data + "\n", data.length); 
            is_locked = false; 
            if(offset > 0)
            {  
                TextIter siter;
                TextIter eiter;
                tv.buffer.get_iter_at_offset( out siter, char_count );
                tv.buffer.get_iter_at_offset( out eiter, char_count + offset);
                tv.buffer.apply_tag(tag, siter, eiter);	
            }
            return false;
        });

        //Sleep for a little bit so the adjustment is updated
        Thread.usleep(5000);
        Adjustment position = sw.get_vadjustment();
        if(position.value > position.upper - position.page_size - 350)
        {
            Idle.add( () => {  
                position.set_value(position.upper - position.page_size);  
                sw.set_vadjustment(position);  
                return false;
            });
        }

    }

    public void send_text_out(string text)
    {
        var current = tabs.current; 
        foreach(Map.Entry<int,ChannelTab> output in outputs.entries)
        {
            if(current.label == output.value.channel_name)
            { 
                output.value.server.send_output(text);  
                //add_text(output.value, output.value.server.username + ": " + text); 
                return;
            }
        } 
    }

    public void refresh_server_list()
    {     
        var root = servers.root;
        root.clear(); 
        foreach(var svr in SqlClient.servers.entries)
        {
            var s =  new Granite.Widgets.SourceList.ExpandableItem(svr.value.host); 
            root.add(s);
            var chn = new Granite.Widgets.SourceList.Item (svr.value.host);   
            s.add(chn);
            chn.activated.connect(channel_clicked);
            foreach(var c in svr.value.channels)
            {
                chn = new Widgets.SourceList.Item (c.channel);
                chn.activated.connect(channel_clicked); 
                s.add(chn);
            }
        } 
    }

    public void channel_clicked()
    {
        stderr.printf("Channel clicked");
    }

    public bool slide_panel()
    { 
        new Thread<int>("slider_move", move_slider_t);
        return false;
    }

    public int move_slider_t()
    { 
        int add, end;
        bool opening;
        if(pannel.position < 10)
        {
            opening = true;
            add = 1;
            end = 150;
        }else{
            opening = false;
            add = -1;
            end = 0;
        }  
        for(int i = pannel.position; (opening) ? i < end : end < i; i+= add)
        { 
            pannel.set_position(i); 
            Thread.usleep(3600);
        }
        return 0;
    }

    public void set_up_add_sever(Gtk.HeaderBar toolbar)
    { 
        var add_server_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        add_server_button.tooltip_text = "Add new server";  

        var sm = new ServerManager();
        add_server_button.button_release_event.connect( (event) => { 
            sm.open_window(event);
            sm.window.destroy.connect( () => {
                refresh_server_list ();
            });
            return false;
        });

        toolbar.pack_start(add_server_button); 
    }

    private void remove_tab(Widgets.Tab tab)
    {
        int index = tabs.get_tab_position(tab);
        tabs.remove_tab(tabs.get_tab_by_index(index));
        clients[index].stop(); 
        clients.unset(index);
        outputs.unset(index);
    }

    [CCode (instance_pos = -1)]
    public void on_destroy (Widget window) 
    {
        Gtk.main_quit();
    }

    public static void handle_log(string? log_domain, LogLevelFlags log_levels, string message)
    {
        string prefix = "";
        string suffix = "\x1b[39;49m " ;
        switch(log_levels)
        {
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

    public static string get_asset_file(string name)
    {
        string check = Config.PACKAGE_DATA_DIR + name;
        File file = File.new_for_path (check);
        if(file.query_exists()) 
            return check;

        check = "src/" + name; 
        file = File.new_for_path (check);
        if(file.query_exists()) 
            return check;

        check =  name; 
        file = File.new_for_path (check);
        if(file.query_exists()) 
            return check;

        error("Unable to find UI file."); 
    }

    static int main (string[] args) 
    { 
        GLib.Log.set_default_handler(handle_log);  

        Gtk.init (ref args); 
        new Kyrc ();

        Gtk.main ();

        return 0;
    }
}

