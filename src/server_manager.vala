
/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * server_manager.vala
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

using Gdk;
using Gtk;
using Gee;

public class ServerManager : Object
{
	public Gtk.Window window;
	Entry new_channel;
	ListBox channels;
	ListBox servers;
	ListBoxRow select_row = null;
	SqlClient sqlclient = SqlClient.get_instance();
	Button add_channel;
	Button cancel;

	Entry host;
	SpinButton port;
	Entry real;
	Entry user;
	Entry pass;
	Entry nick;
	Switch encrypt;
	TextView connect_cmds;
	Grid form;
	SqlClient.Server current_server = null;
	bool none_selected = false;
	public char[] CHANNEL_CHAR = {'&', '#', '+', '!'};



	public bool open_window () {
		current_server = null;
		var builder = new Builder();
		try{
			builder.add_from_file(Relay.get_asset_file(MainWindow.UI_FILE_SERVERS));
		}catch(Error e){
			error("Unable to load UI file " + Relay.get_asset_file(MainWindow.UI_FILE_SERVERS));
		}


		window = builder.get_object ("window") as Gtk.Window;
		var box = builder.get_object ("port_wrap") as Box;
		var remove_channel = builder.get_object ("remove_channel") as Button;
		var server_btns = builder.get_object ("server_buttons") as Box;
		cancel = builder.get_object ("cancel") as Button;
		add_channel = builder.get_object ("add_channel") as Button;
		new_channel = builder.get_object ("channel_name") as Entry;
		channels = builder.get_object ("channel") as ListBox;
		servers = builder.get_object ("servers") as ListBox;
		host = builder.get_object ("host") as Entry;
		real = builder.get_object ("real") as Entry;
		user = builder.get_object ("user") as Entry;
		pass = builder.get_object ("pass") as Entry;
		nick = builder.get_object ("nick") as Entry;
		connect_cmds = builder.get_object ("connect_cmds") as TextView;
		encrypt = builder.get_object ("encrypt") as Switch;
		form = builder.get_object ("form") as Grid;

		var channels_placeholder = new Label(_("No Channels"));
		channels.set_placeholder(channels_placeholder);
		channels_placeholder.show_all();

		servers.set_selection_mode(SelectionMode.BROWSE);
		servers.row_activated.connect(save_changes);
		servers.row_activated.connect(populate_fields);
		servers.row_selected.connect(clear_row);

		var add_server = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var remove_server = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		server_btns.pack_end(add_server, false, false, 0);
		server_btns.pack_end(remove_server, false, false, 0);

		channels.set_size_request(100,100);
		channels.set_selection_mode(SelectionMode.BROWSE);
		servers.set_size_request(175,50);


		cancel.button_release_event.connect(cancel_clicked);
		add_channel.button_release_event.connect(add_channel_clicked);
		add_server.button_release_event.connect(add_server_clicked);
		remove_server.button_release_event.connect(remove_server_clicked);
		remove_channel.button_release_event.connect(remove_channel_clicked);
		host.focus_out_event.connect(host_text_changed);


		var chn_adj = new Adjustment(1, 1, 500, 1, 2, 100);
		channels.set_adjustment(chn_adj);


		port = new Gtk.SpinButton.with_range (0, 65535, 1);
		box.pack_start(port, false, false, 0);

		add_servers();
		window.show_all ();
		set_forms_active(false);


		return false;
	}

	private void clear_row (ListBoxRow? row) {
		if (!(row is Widget)) {
			none_selected = true;
		}else if (none_selected) {
			current_server = null;
			select_row = null;
			none_selected = false;
		}
	}


	public void save_changes (ListBoxRow row) {
		if (current_server == null || select_row == null)
			return;

		string hostname = host.get_text().strip();

		if (hostname == "")
			return;

		var exists = sqlclient.get_server(hostname);
		if (exists != null && exists.id != current_server.id)
			return;


		current_server.host = hostname;
		current_server.realname = real.get_text();
		current_server.username = user.get_text();
		current_server.password = pass.get_text();
		current_server.nickname = nick.get_text();
		current_server.port = port.get_value_as_int();
		current_server.encryption = encrypt.get_active();
		current_server.connect_cmds = connect_cmds.buffer.text;

		current_server.update();


		if (select_row != null) {
			int index = select_row.get_index();
			var newrow = get_list_box_row (hostname);
			servers.remove(select_row);
			servers.insert(newrow, index);
			servers.show_all();
		}
	}

	private bool host_text_changed (EventFocus event) {
		string message = "";
		string name = host.get_text().strip();
		if (name.length == 0) {
			message = "Host can not be empty. Your changes will not be saved.";
		}
		var exists = sqlclient.get_server(name);
		if (exists != null && exists.id != current_server.id) {
			message = "A server with that host already exists. Your changes will not be saved.";
		}
		if (message != "") {
			Gtk.MessageDialog msg = new Gtk.MessageDialog (window, 
			                                               Gtk.DialogFlags.MODAL, 
			                                               Gtk.MessageType.WARNING, 
			                                               Gtk.ButtonsType.OK, 
			                                               "%s",
			                                               message);
			msg.response.connect ((response_id) => {
				host.grab_focus();
				msg.destroy();
			});
			msg.show ();
		}
		return false;
	}

	public void populate_fields (ListBoxRow? row) {
		if (row == null) {
			current_server = null;
			select_row = null;
		}

		set_forms_active(true);

		select_row = row;

		SqlClient.Server svr = sqlclient.get_server(row.name);
		if (svr == null)
			svr = new SqlClient.Server();

		current_server = svr;

		host.set_text(svr.host);
		user.set_text(svr.username);
		real.set_text(svr.realname);
		pass.set_text(svr.password);
		port.set_value(svr.port);
		nick.set_text(svr.nickname);
		encrypt.state_set(svr.encryption);
		connect_cmds.buffer.text = svr.connect_cmds;

		foreach (Widget lbr in channels.get_children()) {
			channels.remove(lbr);
		}

		foreach (SqlClient.Channel chn in svr.channels) {
			var lbr = get_channel_list_box_row(chn);
			channels.insert(lbr, -1);
		}

		channels.show_all();
	}

	private ListBoxRow get_channel_list_box_row (SqlClient.Channel channel) {
		var box = new Box(Orientation.HORIZONTAL, 1);
		var lbr = new ListBoxRow();
		var lbl = new Label(channel.channel);
		var ac_switch = new Switch();
		var switch_box = new Box(Orientation.HORIZONTAL, 1);
		lbl.set_halign(Align.START);
		switch_box.pack_start(ac_switch);
		box.pack_start(lbl, true, true, 0);
		box.pack_end(switch_box, false, false, 0);
		ac_switch.state = channel.autoconnect;
		ac_switch.state_set.connect(channel.update_autoconnect);
		lbr.add(box);
		lbr.show_all();
		box.set_data("ac_switch", ac_switch);
		lbr.name = channel.channel;
		return lbr;
	}

	private ListBoxRow get_list_box_row (string name) {
		var lbr = new ListBoxRow();
		var lbl = new Label(name);
		lbr.add(lbl);
		lbr.set_halign(Align.FILL);
		lbl.set_halign(Align.START);
		lbr.name = name;
		return lbr;
	}


	private void add_servers () {
		ListBoxRow first_row = null;
		foreach (var svr in SqlClient.servers.entries) {
			var server = svr.value;
			var lbr = get_list_box_row(server.host);
			servers.insert(lbr, -1);
			if (first_row == null)
				first_row = lbr;
		}

	}

	private bool remove_channel_clicked (Gdk.EventButton event) {
		var widget = channels.get_selected_row();
		channels.remove(widget);
		var channel = current_server.find_channel_by_name(widget.name);
		if (channel == null)
			return false;
		channel.delete_channel();
		current_server.channels = SqlClient.servers[current_server.id].channels;
		return false;
	}

	static string CHANNEL_ERROR = _("A channel name must begin with one of the following characters: %c, %c, %c, %c.");
	private bool add_channel_clicked (Gdk.EventButton event) {
		string chan_name = new_channel.get_text().strip();
		if (chan_name.length == 0 || current_server.find_channel_by_name(chan_name) != null)
			return false;

		if (!(chan_name[0] in CHANNEL_CHAR)) {
			Gtk.MessageDialog msg = new Gtk.MessageDialog (window, 
			                                               Gtk.DialogFlags.MODAL, 
			                                               Gtk.MessageType.WARNING, 
			                                               Gtk.ButtonsType.OK, 
			                                               CHANNEL_ERROR,
			                                               CHANNEL_CHAR[0], 
			                                               CHANNEL_CHAR[1], 
			                                               CHANNEL_CHAR[2], 
			                                               CHANNEL_CHAR[3]);
			msg.response.connect ((response_id) => {
				host.grab_focus();
				msg.destroy();
			});
			msg.show ();
			return false;
		}
		var channel = new SqlClient.Channel();
		channel.server_id = current_server.id;
		channel.channel = chan_name;
		channel.add_channel();

		var lbr = get_channel_list_box_row(channel);
		new_channel.set_text("");
		channels.add(lbr);
		channels.show_all();
		current_server.channels = SqlClient.servers[current_server.id].channels;
		return false;
	}

	private bool remove_server_clicked (Gdk.EventButton event) {
		var widget = servers.get_selected_row();
		servers.remove(widget);
		set_forms_active(false);
		current_server.remove_server();
		current_server = null;
		return false;
	}

	private void set_forms_active (bool active) {
		var children = form.get_children();
		foreach (var child in children) {
			child.set_sensitive(active);
		}
		cancel.get_parent().set_sensitive(true);
	}


	private bool add_server_clicked (Gdk.EventButton event) {
		save_changes (select_row);
		current_server = new SqlClient.Server();
		current_server.username = current_server.nickname = Environment.get_user_name();
		int id = current_server.add_server_empty();
		current_server.id = id;
		current_server.host = "New Server " + id.to_string();

		var lbr = get_list_box_row (current_server.host);
		servers.insert(lbr, -1);
		servers.select_row(lbr);
		servers.show_all();
		populate_fields (lbr);
		host.grab_focus();
		port.set_value((int) Connection.DEFAULT_PORT);

		return false;
	}


	private bool cancel_clicked (Gdk.EventButton event) {
		save_changes (select_row);
		window.close();
		return false;
	}
}
