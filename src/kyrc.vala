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

public class Main : Object 
{

	/* 
	 * Uncomment this line when you are done testing and building a tarball
	 * or installing
	 */
	//const string UI_FILE = Config.PACKAGE_DATA_DIR + "/ui/" + "kyrc.ui";
	public const string UI_FILE = "src/kyrc.ui";
	public const string UI_FILE_SERVERS = "src/server_window.ui";

	/* ANJUTA: Widgets declaration for kyrc.ui - DO NOT REMOVE */
 
	Granite.Widgets.DynamicNotebook tabs;
	Window window;
	Entry input;
	SqlClient sqlclient = SqlClient.get_instance();
	
	Gee.HashMap<int, TextView> outputs = new Gee.HashMap<int, TextView> ();
	Gee.HashMap<int, Client> clients = new Gee.HashMap<int, Client> ();
	ListBox servers = new ListBox();
	

	public Main ()
	{

		try 
		{
			Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);
			
			var builder = new Builder ();
			builder.add_from_file (UI_FILE);
			builder.connect_signals (this);

			var toolbar = new Gtk.HeaderBar (); 
			tabs = new Granite.Widgets.DynamicNotebook(); 
			tabs.allow_drag = true; 
			
			window = builder.get_object ("window") as Window;
			var nb_wrapper = builder.get_object("notebook_wrapper") as Box;
			nb_wrapper.pack_start(tabs, true, true, 1);
			
			
			var server_list_container = builder.get_object("server_list_container") as Box;
			server_list_container.pack_start(servers, true, true, 0);
			
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

			add_tab("irc.freenode.net");
			
			tabs.new_tab_requested.connect(() => {
				var dialog = new Dialog.with_buttons("New Connection", window, 
				                                     DialogFlags.DESTROY_WITH_PARENT,
				                                     "Connect", Gtk.ResponseType.ACCEPT,
				                                     "Cancel", Gtk.ResponseType.CANCEL);
				Gtk.Box content = dialog.get_content_area() as Gtk.Box;
				content.pack_start(new Label("Server address"), false, false, 5);
				var server_name = new Entry();
				content.pack_start(server_name, false, false, 5); 
				dialog.show_all();
				dialog.response.connect((id) => {
					switch (id){
						case Gtk.ResponseType.ACCEPT:
							string name = server_name.get_text().strip();
							if(name.length > 2)
							{
								add_tab(name);
								dialog.close();
							}
							break;
						case Gtk.ResponseType.CANCEL:
							dialog.close();
							break;
					}
				});
			});
		} 
		catch (Error e) {
			stderr.printf ("Could not load UI: %s\n", e.message);
		} 

	}


	public void add_tab(string url)
	{ 
		Gtk.Label title = new Gtk.Label (url);    
		TextView output = new TextView();  
		ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null); 
		scrolled.add(output); 
		output.set_editable(false); 
		output.set_wrap_mode (Gtk.WrapMode.WORD); 

		var tab = new Granite.Widgets.Tab(); 
		tab.label = url;
		
		tab.page = scrolled;
		tabs.insert_tab(tab, 0);
		
		int index = 0;
		 
		outputs.set(index, output);
		
		tabs.show_all();
		
		var client = new Client();  
		client.username = "kyle123456";
		clients.set(index, client);
		
		client.new_data.connect(add_text);
		client.connect_to_server(url, index);
  
	}

	public void add_text(int index, string data)
	{
		TextView tv = outputs[index]; 
		TextIter outiter;
		tv.buffer.get_end_iter(out outiter); 
		ScrolledWindow sw = (ScrolledWindow)tv.get_parent();
		Idle.add( () => {   
			string text = data + "\n";  
			tv.buffer.insert(ref outiter, text, text.length);
			Adjustment adj = sw.get_vadjustment(); 
			adj.set_value(adj.get_upper() - adj.get_page_size());
			return false;
		});

		//Sleep for a little bit so the adjustment is updated
		Thread.usleep(5000);
		
		Idle.add( () => { 
			Adjustment adj = sw.get_vadjustment(); 
			adj.set_value(adj.get_upper() - adj.get_page_size());  
			sw.set_vadjustment(adj);  
			return false;
		});
	 
	}

	public void send_text_out(string text)
	{
		int page = 0;
		clients[page].send_output(text);
		add_text(page, clients[page].username + ": " + text);
	}

	public void refresh_server_list()
	{ 
		foreach(var svr in sqlclient.servers.entries)
		{
			var server = svr.value;
			var lbr = new ListBoxRow();
			var lbl = new Label(server.host); 
			lbr.set_halign(Align.FILL);
			lbl.set_halign(Align.START);
			lbr.add(lbl);
			servers.insert(lbr, -1);
		}
	}

	public void set_up_add_sever(Gtk.HeaderBar toolbar)
	{ 
		var add_server_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        add_server_button.tooltip_text = "Add new server";  
		
		var sm = new ServerManager();
		add_server_button.button_release_event.connect( (event) => { 
			sm.open_window(event);
			return false;
		});
		
		toolbar.pack_start(add_server_button); 
	}

	private void remove_tab(int index)
	{
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

	static int main (string[] args) 
	{
		Gtk.init (ref args);
		var app = new Main ();

		Gtk.main ();
		
		return 0;
	}
}

