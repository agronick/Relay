/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * channeltab.vala
 * Copyright (C) 2015 Kyle Agronick <stack@kyle-ele>
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
using Granite;
using Gtk;

public class ChannelTab : GLib.Object {
	public int tab_index { get; set; }
	public Client server { get; set; }
	public string channel_name { get; set; }
	public Granite.Widgets.Tab tab;
	public TextView output;

	public void add_text(string msg)
	{
		server.send_output(msg);
	}

	// Constructor
	public ChannelTab (Client? param_server = null, string param_channel_name = "", int param_tab_index = -1) {
		server = param_server;
		channel_name = param_channel_name;
		tab_index = param_tab_index;
	}

	public void set_tab(Widgets.Tab t, int index)
	{
		tab_index = index;
		tab = t;
	}

}

