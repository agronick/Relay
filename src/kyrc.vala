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

public class Main : Object 
{

	/* 
	 * Uncomment this line when you are done testing and building a tarball
	 * or installing
	 */
	//const string UI_FILE = Config.PACKAGE_DATA_DIR + "/ui/" + "kyrc.ui";
	const string UI_FILE = "src/kyrc.ui";

	/* ANJUTA: Widgets declaration for kyrc.ui - DO NOT REMOVE */
 
	Notebook tabs;
	Window window;
	Entry input;
	
	Gee.HashMap<int, TextView> outputs = new Gee.HashMap<int, TextView> ();
	Gee.HashMap<int, Client> clients = new Gee.HashMap<int, Client> ();
	

	public Main ()
	{

		try 
		{
			Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);
			
			var builder = new Builder ();
			builder.add_from_file (UI_FILE);
			builder.connect_signals (this);

			var toolbar = new Gtk.HeaderBar ();

			window = builder.get_object ("window") as Window;
			tabs = builder.get_object("tabs") as Notebook;
			input = builder.get_object("input") as Entry;

			input.activate.connect (() => {
				send_text_out(input.get_text ());
				input.set_text("");
			});
			
            toolbar.show_close_button = true;
			window.set_titlebar(toolbar);
			/* ANJUTA: Widgets initialization for kyrc.ui - DO NOT REMOVE */
			window.show_all ();
			

			add_tab("irc.freenode.net");
 
		} 
		catch (Error e) {
			stderr.printf ("Could not load UI: %s\n", e.message);
		} 

	}

	public void add_tab(string url)
	{ 
		Gtk.Label title = new Gtk.Label (url);   
		Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null); 
		TextView output = new TextView();
		output.set_wrap_mode (Gtk.WrapMode.WORD);
		scrolled.add(output);

		int index = tabs.append_page(scrolled, title); 
		outputs.set(index, output);
		
		window.show_all();
		
		var client = new Client();  
		client.username = "kyle123456";
		clients.set(index, client);
		
		client.new_data.connect(add_text);
		client.connect_to_server("irc.freenode.net", index);
	}

	public void add_text(int index, string data)
	{
		TextView tv = outputs[index];
		Idle.add( () => {   
			tv.buffer.text += data; 
			return false;
		});
	}

	public void send_text_out(string text)
	{
		int page = tabs.get_current_page();
		clients[page].send_output(text);
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

