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
	public bool is_server_tab = false;
	public bool has_subject = false;
	public string channel_subject = "";
	public static bool is_locked = false;

	public signal void new_subject(int tab_id, string subject);

	public void add_text (string msg) {
		server.send_output(msg);
	}

	// Constructor
	public ChannelTab (Client? param_server = null, string param_channel_name = "", int param_tab_index = -1) {
		server = param_server;
		channel_name = param_channel_name;
		tab_index = param_tab_index;
	}

	public void set_tab (Widgets.Tab t, int index) {
		tab_index = index;
		tab = t;
	}

	public void set_subject (string subject) {
		has_subject = true;
		channel_subject = subject;
		new_subject (tab_index, subject);
	}

	public void display_message (Message message) { 
		message.message += "\n";
		TextView tv = output;
		ScrolledWindow sw = (ScrolledWindow)tv.get_parent();
		while (is_locked) {
			Thread.usleep(111);
		}
		string data = "";
		int message_offset = -1, offset = -1;
		TextTag? left_side = null;
		Gdk.RGBA rgba = Gdk.RGBA();
		switch (message.command) {
			case "PRIVMSG":
				data =   message.user_name + message.message;
				left_side = tv.buffer.create_tag(null);
				rgba.red = 1.0; 
				rgba.alpha = 1.0; 
				left_side.foreground_rgba = rgba;
				left_side.left_margin = 0;
				offset = message.user_name.length;
				break;
			case Client.RPL_TOPIC:
				set_subject(message.message);
				return;
			case "NOTICE":
			case Client.RPL_MOTD:
			case Client.RPL_MOTDSTART:
				data = message.message;
				break;
		}
		Idle.add ( () => {
			is_locked = true;
			int char_count = tv.buffer.get_char_count();
			TextIter outiter;
			TextBuffer buf = tv.buffer;
			buf.get_end_iter(out outiter); 
			buf.insert_text(ref outiter, data, data.length);
			is_locked = false;
			debug("Parsed message: " + data);
			if (offset > 0) {
				TextIter siter;
				TextIter eiter;
				tv.buffer.get_iter_at_offset( out siter, char_count );
				tv.buffer.get_iter_at_offset( out eiter, char_count + offset);
				buf.apply_tag(left_side, siter, eiter);

				TextIter m_siter;
				TextIter m_eiter;
				tv.buffer.get_iter_at_offset( out m_siter, tv.buffer.get_char_count() - message.message.length);
				tv.buffer.get_iter_at_offset( out m_eiter, tv.buffer.get_char_count());
				var right_side = tv.buffer.create_tag(null);
				right_side.indent = 0; 
				buf.apply_tag(right_side, m_siter, m_eiter);
			}
			return false;
		});

		//Sleep for a little bit so the adjustment is updated
		Thread.usleep(5000);
		Adjustment position = sw.get_vadjustment();
		if (!(position is Adjustment))
			return;
		if (position.value > position.upper - position.page_size - 350) {
			Idle.add( () => {
				position.set_value(position.upper - position.page_size);
				if (sw is ScrolledWindow)
					sw.set_vadjustment(position);
				return false;
			});
		}
	}
}

