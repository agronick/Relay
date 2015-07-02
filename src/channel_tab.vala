
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
using Gee;
using Gdk;

public class ChannelTab : GLib.Object {
    public int tab_index { get; set; }
    public Connection connection { get; set; }
    public string channel_name { get; set; }
    public Granite.Widgets.Tab tab;
    public bool is_server_tab = false;
    public bool has_subject = false;
    public string channel_subject = "";
    public bool is_locked = false;
	public ArrayList<string> users = new ArrayList<string>();
	public LinkedList<string> blocked_users = new LinkedList<string>();
    private TextView output;
	
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

    public signal void new_subject(int tab_id, string subject);
	public signal void user_names_changed(int tab_id);

    public void add_text (string msg) {
        connection.send_output(msg);
    }

    // Constructor
    public ChannelTab (Connection? param_server = null, string param_channel_name = "", int param_tab_index = -1) {
        connection = param_server;
        channel_name = param_channel_name;
        tab_index = param_tab_index;
    }  

    public void set_tab (Widgets.Tab t, int index) { 
        tab_index = index;
        tab = t;
    }

    public void set_topic (string subject, bool append = false) {
        has_subject = true;
        channel_subject = append ? channel_subject + subject + "\n" : subject;
		Idle.add( () => { 
    		new_subject (tab_index, subject);
			return false;
		});
    }

	public void add_block_list (string name) {
		blocked_users.add(name);

		if (IRC.user_prefixes.index_of_char(name[0]) != -1)
			blocked_users.add(IRC.remove_user_prefix(name));	}

	public void remove_block_list (string name) {
		blocked_users.remove(name);

		if(IRC.user_prefixes.index_of_char(name[0]) != -1)
			blocked_users.remove(IRC.remove_user_prefix(name));
	}
	
	public void add_users_message (Message message) {
		var names = message.message.split(" ");
		foreach (var name in names) {
			if(name.length == 0)
				continue;

			name = fix_user_name(name);
			if (!users.contains(name))
				users.add(name);
		}
	}

	public string fix_user_name (string name) {
		if (IRC.user_prefixes.index_of_char(name[0]) != -1)
			return name.substring(1);
		else
			return name;
	}

	public void user_name_change(string old_name, string new_name) {
		int index = users.index_of(fix_user_name(old_name));
		if (index != -1)
			users[index] = fix_user_name(new_name);

		idle_use_names_changed();
	}

	public void user_leave_channel(string name, string msg) {
		if (users.contains(fix_user_name(name))) {
			last_user = "";
			users.remove(fix_user_name(name));
			idle_use_names_changed();
			space();
			add_with_tag(name + _(" has left: ") + msg + "\n", full_width_tag);
		}
	}

	public void user_join_channel(string name) {
		last_user = "";
		string uname = fix_user_name(name);
		if (!users.contains(uname))
			users.add(uname);
		idle_use_names_changed();
		space();
		add_with_tag(uname + _(" has joined: ") + channel_name + "\n", full_width_tag);
	}

	private void idle_use_names_changed(){
		Idle.add( ()=> {
			user_names_changed(tab_index);
			return false;
		});
	}
	
    public void set_output(TextView _output) {
        output = _output;
        output.buffer.changed.connect(do_autoscroll);
        update_tag_table();
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
        return "PRIVMSG " + channel_name + " :" + message.escape("");
    }

	public string parse_nick_change (string message) {
		string[] split = message.split(" ");
		connection.server.nickname = split[1];
		return "NICK " + split[1];
	}

    public string format_server_msg (string message) {
        if (message[0] != '/')
            return "";
        return message.substring(1); 
    }
 
    public void display_message (Message message) {   
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
		tab.working = false;
		message.message += "\n";
		add_with_tag(message.message, error_tag);
	}

	public void space() {
		add_with_tag(" \n", spacing_tag);
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
        if (position.value > position.upper - position.page_size - 50) {
            Idle.add( () => {
                position.set_value(position.upper - position.page_size);
                sw.set_vadjustment(position);
                return false;
            });
        }
    }       
 
    private void add_with_tag (string? text, TextTag? tag, int retry_count = 0) {
		if(text == null || 
		   tag == null || 
		   retry_count > 4 ||
		   (text.strip() == "" && tag != spacing_tag))
			return;

		var rich_text = new RichText(text);
		if (tag == full_width_tag || tag == std_message_tag) {
			rich_text.parse_links();
			rich_text.parse_name(connection.server.nickname);
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
            output.buffer.insert_with_tags(end, text, text.length, tag, null);
			if (rich_text.has_links) {
				for (int i = 0; i < rich_text.link_locations_start.size; i++)
				{
		    		output.buffer.get_end_iter(out end);
					TextIter start = end;
					start.set_offset(start.get_offset() - rich_text.link_locations_start[i]);
					end.set_offset(end.get_offset() - rich_text.link_locations_end[i]);
					output.buffer.apply_tag(link_tag, start, end);
				}
			}
			if (rich_text.has_names) {
				for (int i = 0; i < rich_text.name_location_start.size; i++)
				{
		    		output.buffer.get_end_iter(out end);
					TextIter start = end;
					start.set_offset(start.get_offset() - rich_text.name_location_start[i]);
					end.set_offset(end.get_offset() - rich_text.name_location_end[i]);
					output.buffer.apply_tag(name_hilight_tag, start, end);
				}
			}
    		is_locked = false;
            return false;
        });
		is_locked = false;
    }


    private void update_tag_table () { 
        user_other_tag = output.buffer.create_tag("user_other");
        user_self_tag = output.buffer.create_tag("user_self");
        std_message_tag = output.buffer.create_tag("std_message");
        full_width_tag = output.buffer.create_tag("full_width");
        error_tag = output.buffer.create_tag("error");
        link_tag = output.buffer.create_tag("link");
		name_hilight_tag = output.buffer.create_tag("name_hilight");
		timestamp_tag = output.buffer.create_tag("timestamp");
		spacing_tag = output.buffer.create_tag("spacing");

        var color = new Gdk.RGBA();
        color.parse("#4EC9DE");
        user_other_tag.foreground_rgba = color;
        user_other_tag.left_margin = 0;
		user_other_tag.weight = Pango.Weight.SEMIBOLD;
        
        color.parse("#AE81FF");
        user_self_tag.foreground_rgba = color;
        user_self_tag.left_margin = 0;
		user_self_tag.weight = Pango.Weight.SEMIBOLD;

        color.parse("#F8F8F2");
        std_message_tag.foreground_rgba = color;
        std_message_tag.indent = 0;

        full_width_tag.left_margin = 0;

		color.parse("#C54725");
		error_tag.foreground_rgba = color;
		error_tag.left_margin = 0;

		color.parse("#3D81C4");
		link_tag.foreground_rgba = color;
		link_tag.underline_set = true;

		link_tag.event.connect(hover_hand);
		link_tag.event.connect(link_clicked);

		color.parse("#F1AB25");
		name_hilight_tag.foreground_rgba = color;
		name_hilight_tag.weight = Pango.Weight.SEMIBOLD;

		color.parse("#D5D5D5");
		timestamp_tag.foreground_rgba = color;
		timestamp_tag.justification = Justification.RIGHT;
		timestamp_tag.size_points = 8;
		timestamp_tag.family = "Liberation Sans";
		timestamp_tag.pixels_above_lines = 7;
		timestamp_tag.pixels_below_lines = 1;

		spacing_tag.size_points = 2;
    }

	public bool hover_hand(GLib.Object event_object, Gdk.Event event, TextIter end) {
		//TODO: Make this work or remove it
		TextView tv = (TextView) event_object;
		if (event.type == EventType.ENTER_NOTIFY) {
			stdout.printf("Entered");
			MainWindow.window.get_window().set_cursor(new Cursor.for_display(Display.get_default(), CursorType.HAND1));
		} else if (event.type == EventType.LEAVE_NOTIFY) {
			MainWindow.window.get_window().set_cursor(new Cursor.for_display(Display.get_default(), CursorType.XTERM));
		}
		return false;
	}

	public bool link_clicked(GLib.Object event_object, Gdk.Event event, TextIter end) {
		if (event.type == EventType.BUTTON_RELEASE) {
			TextView tv = (TextView) event_object;
			string delimiters = " \n\t\r";
			TextIter start = end;

			while(delimiters.index_of_char(end.get_char()) == -1)
				tv.buffer.get_iter_at_offset(out end, end.get_offset() + 1);

			while(delimiters.index_of_char(start.get_char()) == -1)
				tv.buffer.get_iter_at_offset(out start, start.get_offset() - 1);

			tv.buffer.get_iter_at_offset(out end, end.get_offset() - 1);
			tv.buffer.get_iter_at_offset(out start, start.get_offset() + 1);
			
			string link = start.get_text(end);
			stdout.printf("LINK IS " + link + start.get_char().to_string() + end.get_char().to_string() +  "\n");
			Granite.Services.System.open_uri(link);
		}
		return false;
	}

	private string parse_message_cmd(string message) {
		string[] split = message.split(" ");
		string[] slice = split[2:split.length];
		string msg = "PRIVMSG " + split[1] + " :" + string.joinv(" ", slice);
		return msg;
	}
}

