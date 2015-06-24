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

public class ChannelTab : GLib.Object {
    public int tab_index { get; set; }
    public Connection server { get; set; }
    public string channel_name { get; set; }
    public Granite.Widgets.Tab tab;
    public bool is_server_tab = false;
    public bool has_subject = false;
    public string channel_subject = "";
    public bool is_locked = false;
	public ArrayList<string> users = new ArrayList<string>();
	public ArrayList<string> blocked_users = new ArrayList<string>();
    private TextView output;

    public signal void new_subject(int tab_id, string subject);

    public void add_text (string msg) {
        server.send_output(msg);
    }

    // Constructor
    public ChannelTab (Connection? param_server = null, string param_channel_name = "", int param_tab_index = -1) {
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

	public void add_users_message (Message message) {
		var names = message.message.split(" ");
		foreach (var name in names) {
			if(name.length == 0)
				continue;
			users.add(name);
		}

		
		debug("Inserting names " + message.message);
		debug("USERS SIZE IS " + users.size.to_string());
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
        if (is_server_tab) {
            formatted_message = format_server_msg(message);
        } else {
            formatted_message = format_channel_msg(message);
        }
        if(formatted_message.strip().length == 0)
            return;
        debug("Sending out " + formatted_message);
        server.send_output(formatted_message);
    }

    public string format_channel_msg (string message) { 
        return "PRIVMSG " + channel_name + " :" + message.escape("");
    }

    public string format_server_msg (string message) {
        //TODO: format better;
        if(message[0] != '/')
            return "";
        return message.substring(1); 
    }
 
    public void display_message (Message message) {    
        
        var tag_table = output.buffer.get_tag_table();
        var user_other_tag = tag_table.lookup("user_other");
        var user_self_tag = tag_table.lookup("user_self");
        var std_message_tag = tag_table.lookup("std_message");
        var full_width = tag_table.lookup("full_width");

        message.message += "\n";
        
        switch (message.command) {
            case "PRIVMSG": 
                add_with_tag(message.user_name, message.internal ? user_self_tag : user_other_tag);
                add_with_tag(message.message, std_message_tag);
                break;
            case IRC.RPL_TOPIC:
                set_subject(message.message);
                return;
            case "NOTICE":
            case IRC.RPL_MOTD:
            case IRC.RPL_MOTDSTART:
                add_with_tag(message.message, full_width);
                break;
			default: 
				add_with_tag(message.message, full_width);
				break;
        }  

    }
    
    public void do_autoscroll () {
        ScrolledWindow sw = (ScrolledWindow) output.get_parent();
        Adjustment position = sw.get_vadjustment();
        if (!(position is Adjustment))
            return;
        if (position.value > position.upper - position.page_size - 350) {
            Idle.add( () => {
                position.set_value(position.upper - position.page_size);
                sw.set_vadjustment(position);
                return false;
            });
        }
    }       
 
    private void add_with_tag (string? text, TextTag tag, int retry_count = 0) {
		if(text == null || text.strip() == "" || retry_count > 4)
			return;
		
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
    		is_locked = false;
            return false;
        });
		is_locked = false;
    }

    private void update_tag_table () { 
        var user_other = output.buffer.create_tag("user_other");
        var user_self = output.buffer.create_tag("user_self");
        var std_message = output.buffer.create_tag("std_message");
        var full_width = output.buffer.create_tag("full_width");

        var color = new Gdk.RGBA();
        color.parse("#4EC9DE");
        user_other.foreground_rgba = color;
        user_other.left_margin = 0;
        
        color.parse("#AE81FF");
        user_self.foreground_rgba = color;
        user_self.left_margin = 0;

        color.parse("#F8F8F2");
        std_message.foreground_rgba = color;
        std_message.indent = 0;   

        full_width.left_margin = 0;
    }
}

