
/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * channel_tab.vala
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
using Gee;
using Gdk;

public class ChannelTab : GLib.Object {
	public int tab_index { get; set; }
	public Connection connection { get; set; }
	public string channel_name { 
				get{return tab.label;}  
				set{tab.label = value;}
	}
	public Granite.Widgets.Tab tab;
	public bool is_server_tab = false;
	public bool has_subject = false;
	public string channel_subject = "";
	public bool is_locked = false;
	public LinkedList<string> users = new LinkedList<string>();
	public LinkedList<string> ops = new LinkedList<string>();
	public LinkedList<string> half_ops = new LinkedList<string>();
	public LinkedList<string> owners = new LinkedList<string>();
	public LinkedList<string> blocked_users = new LinkedList<string>();
	private TextView output;
	public int message_count = 0;
	private LinkedList<Message> pending_msg = new LinkedList<Message>();
	private LinkedList<Message> pending_err = new LinkedList<Message>();
	public string channel_url = "";
	public bool needs_spacer = false;

	public static TimeVal timeval = TimeVal();
	public static int timestamp_seconds = 180;
	private long last_timestamp = 0;
	private string last_user = "";
	string date_format = "%A, %B %e";
	string time_format = Granite.DateTime.get_default_time_format(true, true);

	TextTag user_other_tag;
	TextTag user_self_tag;
	TextTag std_message_tag;
	TextTag full_width_tag;
	TextTag error_tag;
	TextTag link_tag;
	TextTag name_hilight_tag;
	TextTag timestamp_tag;
	TextTag spacing_tag;
	TextTag other_name_hilight_tag;
	TextTag spacer_line_tag;

	public signal void new_subject(int tab_id, string subject);

	public void add_text (string msg) {
		connection.send_output(msg);
	}

	public ChannelTab (Connection param_server) {
		connection = param_server;
	}  

	public void set_tab (Widgets.Tab t, int index) { 
		tab_index = index;
		tab = t;
	}

	public void set_topic (string subject, bool append = false) {
		channel_subject = append ? channel_subject + subject + "\n": subject;
		has_subject = true;
		Idle.add( () => { 
			new_subject(tab_index, channel_subject);
			return false;
		});
	}

	public void add_block_list (string name) {
		if (name == null || name.strip().length < 2)
			return;

		blocked_users.add(name);

		if (IRC.user_prefixes.index_of_char(name[0]) != -1)
			blocked_users.add(IRC.remove_user_prefix(name));	

	}

	public void remove_block_list (string name) {
		blocked_users.remove(name);

		if (IRC.user_prefixes.index_of_char(name[0]) != -1)
			blocked_users.remove(IRC.remove_user_prefix(name));
	}

	public void add_users_message (Message message) {
		var names = message.message.split(" ");
		foreach (var name in names) {
			if (name.strip().length < 2)
				continue;

			add_user(name, false);
		}
	}

	public string fix_user_name (string? name) {
		if (name == null)
			return "";
		if (IRC.user_prefixes.index_of_char(name[0]) != -1)
			return name.substring(1);
		else
			return name;
	}

	public LinkedList<LinkedList<string>> get_all_user_lists() {
		LinkedList<LinkedList<string>> user_types = new LinkedList<LinkedList<string>>();
		user_types.add(owners);
		user_types.add(ops);
		user_types.add(half_ops);
		user_types.add(users);
		return user_types;
	}

	public void user_name_change(string _old_name, string _new_name) {
		string old_name = fix_user_name(_old_name);
		string new_name = fix_user_name(_new_name);

		foreach (LinkedList<string> list in get_all_user_lists()) {
			int index = list.index_of(old_name);
			if (index != -1) {
				list.remove(old_name);
				add_name_ordered(ref list, new_name, true);
			}
		}
		
		if (connection.server.nickname == old_name || connection.server.nickname == new_name)
			connection.server.nickname = new_name;

		if (MainWindow.settings.get_bool("show_join") || new_name == connection.server.nickname)
			add_with_tag(old_name + _(" is now known as ") + new_name + "\n", full_width_tag);
	}

	public void user_leave_channel(string _name, string msg) {
		string name = fix_user_name(_name);
		if (users.contains(name)) {
			last_user = "";
			if (MainWindow.settings.get_bool("show_join")) {
				space();
				string colon = (msg.strip().length > 0) ? ": " + msg : "";
				add_with_tag(name + _(" has left") + colon + "\n", full_width_tag);
			}
		}
		if (!users.remove(name))
			if (!ops.remove(name))
				if (!half_ops.remove(name))
					owners.remove(name);
	}

	public void user_join_channel(string name) {
		last_user = "";
		string uname = add_user(name, true);
		if (uname == null)
			return;
		if (MainWindow.settings.get_bool("show_join")) {
			space();
			add_with_tag(uname + _(" has joined: ") + channel_name + "\n", full_width_tag);
		}
	}

	public string? add_user(string? user, bool sorted = true) {
		if (user == null)
			return null;
		
		bool op = (user[0] == '@');
		bool halfop = (user[0] == '%');
		bool owner = (user[0] == '~');
		string uname = fix_user_name(user);

		if (op && !ops.contains(uname))
			add_name_ordered(ref ops, uname, sorted);
		else if (halfop && !half_ops.contains(uname))
			add_name_ordered(ref half_ops, uname, sorted);
		else if (owner && !owners.contains(uname))
			add_name_ordered(ref owners, uname, sorted);
		else if (!users.contains(uname))
			add_name_ordered(ref users, uname, sorted);

		return uname;
	}

	public void sort_names () {
		Relay.sort_clean(ref owners);
		Relay.sort_clean(ref ops);
		Relay.sort_clean(ref half_ops);
		Relay.sort_clean(ref users);
	}

	public void add_name_ordered (ref LinkedList<string> list, string name, bool ordered) {
		if (!ordered) {
			list.add(name);
			return;
		}

		int i = 0;
		foreach (var item in list) {
			int compare = Relay.compare(name, item);
			if (compare < 1) {
				list.insert(i, name);
				return;
			}
			i++;
		}
		list.insert(i, name);
	}

	public void set_output(TextView _output) {
		output = _output;
		output.buffer.changed.connect(do_autoscroll);

		user_other_tag = output.buffer.create_tag("user_other");
		user_self_tag = output.buffer.create_tag("user_self");
		std_message_tag = output.buffer.create_tag("std_message");
		full_width_tag = output.buffer.create_tag("full_width");
		error_tag = output.buffer.create_tag("error");
		link_tag = output.buffer.create_tag("link");
		name_hilight_tag = output.buffer.create_tag("name_hilight");
		timestamp_tag = output.buffer.create_tag("timestamp");
		spacing_tag = output.buffer.create_tag("spacing");
		other_name_hilight_tag =  output.buffer.create_tag("other_name");
		spacer_line_tag =  output.buffer.create_tag("spacer_line");
		
		update_tag_table();

		var _pending_msg = pending_msg;
		var _pending_err = pending_err;
		pending_msg = null;
		pending_err = null;
		foreach (var msg in _pending_msg)
			display_message(msg);

		foreach (var msg in _pending_err)
			display_error(msg);
	}

	public TextView get_output () {
		return output;
	}

	public void send_text_out (string message) {
		string formatted_message = "";
		if (message.length > 4 && message[0:4] == "/msg") {
			formatted_message =  parse_message_cmd(message);
		} else if (message.length > 5 && message[0:5] == "/nick") {
			formatted_message = parse_nick_change(message);
		} else {
			if (is_server_tab) {
				formatted_message = format_server_msg(message);
			} else {
				formatted_message = format_channel_msg(message);
			}
			if (formatted_message.strip().length == 0)
				return;
		}
		connection.send_output(formatted_message);
	}

	public string format_channel_msg (string message) { 
		if (message[0] == '/')
			return message.substring(1);
		return "PRIVMSG " + channel_name + " :" + message;
	}

	public string parse_nick_change (string? message) {
		if (message == null)
			return "";
		string[] split = message.split(" ");
		connection.server.nickname = split[1];
		return "NICK " + split[1];
	}

	public string format_server_msg (string message) {
		if (message[0] != '/') {
			add_with_tag(_("Start you command with a / to send it \n"), error_tag);
			return "";
		}
		return message.substring(1); 
	}

	public void display_message (Message message) {
		if (pending_msg != null) {
			pending_msg.add(message);
			return;
		}
		
		message.message = message.get_msg_txt();
		message.message += "\n";

		switch (message.command) {
			case "PRIVMSG": 
				handle_private_message(message);
				break;
			case "NOTICE":
			case IRC.RPL_MOTD:
			case IRC.RPL_MOTDSTART:
				add_with_tag(message.message, full_width_tag);
				break;
			default: 
				add_with_tag(message.message, full_width_tag);
				break;
		} 
	}

	public void display_error (Message message) {
		if (pending_err != null) {
			pending_err.add(message);
			return;
		}
		tab.working = false;
		message.message += "\n";
		add_with_tag(message.message, error_tag);
	}

	public string space(int count = 1) {
		string txt = " \n";
		for (int i = 0; i < count - 1; i++)
			txt += txt;
		add_with_tag(txt, spacing_tag);
		return txt;
	}

	public void handle_private_message (Message message) {
		if (blocked_users.contains(fix_user_name(message.user_name)))
			return;

		string user = message.user_name_get();
		if (!is_server_tab && user == last_user)
			user = "";
		else {
			if (!make_timestamp())
				space();
			last_user = user;
		}

		add_with_tag(user, message.internal ? user_self_tag : user_other_tag);
		add_with_tag(message.message, std_message_tag);
	}

	private bool make_timestamp() {
		if (!MainWindow.settings.get_bool("show_datestamp"))
			return false;
		
		timeval.get_current_time();
		long current = timeval.tv_sec;
		if (current - last_timestamp > timestamp_seconds) {
			var local = new GLib.DateTime.now_local();
			string datetime = local.format(date_format + " "  + time_format) + "\n";
			add_with_tag(datetime, timestamp_tag);
			last_timestamp = current;
			return true;
		}
		return false;
	}

	public void do_autoscroll () {
		ScrolledWindow sw = (ScrolledWindow) output.get_parent();
		Adjustment position = sw.get_vadjustment();
		if (!(position is Adjustment))
			return;
		if (position.value > position.upper - position.page_size - 75) {
			Idle.add( () => {
				position.set_value(position.upper - position.page_size);
				sw.set_vadjustment(position);
				return false;
			});
		}
	}   

	private void add_with_tag (string? text, TextTag? tag, int retry_count = 0) {
		if (text == null || 
		   tag == null || 
		   retry_count > 4 ||
		   (text.strip() == "" && tag != spacing_tag))
			return;


		var rich_text = new RichText(text);
		if (tag == full_width_tag || tag == std_message_tag) {
			rich_text.parse_links();
			if (tag == std_message_tag) {
				foreach (var usr in users)
					rich_text.parse_name(usr);
			}
		}

		while (is_locked) {
			Thread.usleep(111);
		} 
		Idle.add( () => {
			is_locked = true;
			TextIter? end;
			output.buffer.get_end_iter(out end);
			if (end == null) {
				add_with_tag(text, tag, retry_count++);
				return false;
			}
			output.buffer.insert_text(ref end, text, text.length);
			TextIter start = end;
			start.backward_chars(text.length);
			output.buffer.apply_tag(tag, start, end);
			if (rich_text.has_links) {
				for (int i = 0; i < rich_text.link_locations_start.size; i++)
				{
					output.buffer.get_end_iter(out end);
					start = end;
					start.set_offset(start.get_offset() - rich_text.link_locations_start[i]);
					end.set_offset(end.get_offset() - rich_text.link_locations_end[i]);
					output.buffer.apply_tag(link_tag, start, end);
				}
			}
			if (rich_text.has_names) {
				for (int i = 0; i < rich_text.names.size; i++)
				{
					output.buffer.get_end_iter(out end);
					start = end;
					start.set_offset(start.get_offset() - rich_text.name_location_start[i]);
					end.set_offset(end.get_offset() - rich_text.name_location_end[i]);
					TextTag utag = (rich_text.names[i] == connection.server.nickname) ? name_hilight_tag : other_name_hilight_tag;
					utag.set_data<string>("uname", output.buffer.get_text(start, end, false));
					output.buffer.apply_tag(
					             utag, 
					             start, end);
				}
			}
			is_locked = false;
			return false;
		});
		is_locked = false;
	}


	public void update_tag_table () { 
		var color = Gdk.RGBA();
		color.parse(MainWindow.settings.get_color("user-other-color"));
		user_other_tag.foreground_rgba = color;
		user_other_tag.left_margin = 0;
		user_other_tag.weight = Pango.Weight.SEMIBOLD;
		user_other_tag.event.connect(user_name_clicked);
                    
		color.parse(MainWindow.settings.get_color("user-self-color"));
		user_self_tag.foreground_rgba = color;
		user_self_tag.left_margin = 0;
		user_self_tag.weight = Pango.Weight.SEMIBOLD;

		color.parse(MainWindow.settings.get_color("message-color"));
		std_message_tag.foreground_rgba = color;
		std_message_tag.indent = 0;

		full_width_tag.left_margin = 0;

		color.parse(Relay.is_light_theme ? "#752712" : "#C54725");
		error_tag.foreground_rgba = color;
		error_tag.left_margin = 0;

		color.parse(MainWindow.settings.get_color("link-color"));
		link_tag.foreground_rgba = color;
		link_tag.underline_set = true;
		link_tag.event.connect(link_clicked);

		color.parse(Relay.is_light_theme ? "#3E749B" :"#2B94E0");
		name_hilight_tag.foreground_rgba = color;
		name_hilight_tag.weight = Pango.Weight.SEMIBOLD;
		
		color.parse(Relay.is_light_theme ? "#748E16" :"#DEFF67");
		other_name_hilight_tag.foreground_rgba = color;
		other_name_hilight_tag.event.connect(user_name_clicked);

		color.parse(MainWindow.settings.get_color("timestamp-color"));
		timestamp_tag.foreground_rgba = color;
		timestamp_tag.justification = Justification.RIGHT;
		timestamp_tag.size_points = 8;
		timestamp_tag.family = "Liberation Sans";
		timestamp_tag.pixels_above_lines = 7;
		timestamp_tag.pixels_below_lines = 3;

		spacing_tag.size_points = 1;
		spacer_line_tag.justification = Justification.FILL;
		spacer_line_tag.underline = Pango.Underline.SINGLE;
		spacer_line_tag.left_margin = 15;
		spacer_line_tag.right_margin = 15;
		spacer_line_tag.foreground_rgba = output.get_style_context().get_background_color(StateFlags.NORMAL);
		color.parse(Relay.is_light_theme? "#C3C3C3" : "#505254");
		spacer_line_tag.paragraph_background_rgba = color;
		spacer_line_tag.size_points = 0.5;
	}

	private int[] last_spacer_range = new int[2];
	public void add_spacer_line () {
		Idle.add( () => {
			TextIter start;
			TextIter end;

			if (last_spacer_range[1] != 0) {
				output.get_buffer().get_iter_at_offset(out start, last_spacer_range[0]);
				output.get_buffer().get_iter_at_offset(out end, last_spacer_range[1]);
				output.buffer.delete(ref start, ref end);
			}
		
			output.buffer.get_end_iter(out start);
			space(3);
			add_with_tag("-  \n", spacer_line_tag);
			space(2);
			last_spacer_range[0] = start.get_offset();
			last_spacer_range[1] = last_spacer_range[0] + 17; //8 = space() * 3 + spacer_line_tag

			return false;
		});
	}

	public bool user_name_clicked (GLib.Object event_object, Gdk.Event event, TextIter end) {
		if (event.type == EventType.BUTTON_RELEASE) {
			
			string name = get_tag_selection((TextView) event_object, ref end);

			if (name == "")
				return false;

			name += ": ";	

			if (MainWindow.current_tab == tab_index)
				MainWindow.fill_input(name);
		}
		return false;
	}

	public bool link_clicked (GLib.Object event_object, Gdk.Event event, TextIter end) {
		if (event.type == EventType.BUTTON_RELEASE) {
			TextView tv = (TextView) event_object;
			TextIter start = end;

			string link = get_tag_selection(tv, ref end);

			if (link == "")
				return false;
			
			Granite.Services.System.open_uri(link);
		}
		return false;
	}

	public string get_tag_selection(TextView tv, ref TextIter end) {
		
			TextIter start = end;
			SList<weak TextTag> tags = end.get_tags();
			TextTag utag = null;
			foreach (var tag in tags) {
				debug(tag.name);
				if (tag.name == "link" || 
				    tag.name == "other_name" || 
				    tag.name == "user_other")
					utag = tag;
			}

			if (utag == null)
				return "";

			while (!end.ends_tag(utag))
				end.forward_char();

			while (!start.begins_tag(utag))
				start.backward_char();

			return tv.buffer.get_text(start, end, false).strip();
	}

	private string parse_message_cmd(string message) {
		string[] split = message.split(" ");
		string[] slice = split[2:split.length];
		string msg = "PRIVMSG " + split[1] + " :" + string.joinv(" ", slice);
		return msg;
	}

	public int get_char_count() {
		if (output == null)
			return 0;
		return output.buffer.get_char_count();
	}
}

