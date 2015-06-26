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

public class Connection : Object
{

    public static const uint16 DEFAULT_PORT = 6667;
    public DataInputStream input_stream;
    public DataOutputStream output_stream;
    public string url = "";
    public string username = "";
	public string nickname = "";
    public bool exit = false;
    public bool encrypted = false;
    private weak MainWindow backref;
    public ChannelTab server_tab;
    public HashMap<string, ChannelTab> channel_tabs = new HashMap<string, ChannelTab>();
    public LinkedList<string> channel_autoconnect = new LinkedList<string>();
 
    public signal void new_topic(ChannelTab tab, string topic);


    public Connection(MainWindow back) {
        backref = back;
    }

    public bool connect_to_server (string location) {
        url = location;
        server_tab = add_channel_tab(url);
        server_tab.is_server_tab = true; 

        new Thread<int>("Connection " + location, do_connect);

        return true;
    }

    public ChannelTab? add_channel_tab (string name) {
        if (name == username || name == nickname)
            return server_tab;
        if (channel_tabs.has_key(name))
            return channel_tabs[name];
        if (name.strip() == "")
            return null;
        var newTab = new ChannelTab(this, name);
        backref.add_tab(newTab); 
        channel_tabs[name] = newTab;
        return newTab;
    }

    private ChannelTab find_channel_tab (string name) {
		debug("LOOKING UP " + name);
        if (channel_tabs.has_key(name))
            return channel_tabs[name];

        return server_tab;
    }

    private int do_connect () {
        SocketClient client = new SocketClient ();
        client.tls = encrypted;
        // Resolve hostname to IP address:
        Resolver resolver = Resolver.get_default ();
        GLib.List<InetAddress> addresses = resolver.lookup_by_name (url, null);
        InetAddress address = addresses.nth_data (0);
        SocketConnection conn = client.connect (new InetSocketAddress (address, DEFAULT_PORT));
        input_stream = new DataInputStream (conn.input_stream);
        output_stream = new DataOutputStream (conn.output_stream);

		do_register();

        string? line = "";
        do{
            size_t size;
            try{
                line = input_stream.read_line(out size);
                debug("RAW INPUT " + line);
                handle_input(line);
            }catch(IOError e) {
                warning("IO error while reading");
            }
        }while (line != null && !exit);


        return 1;
    }

    private void handle_input (string? msg) {
        if (msg == null) {
            stop();
            return;
        }  
        
        Message message = new Message (msg);
        switch (message.command) {
            case "PING":
                handle_ping(ref message);
                return;
            case "PONG":
                info(msg);
                return;
            case IRC.RPL_TOPIC:
                add_channel_tab(message.parameters[1]).set_topic(message.message);
                return;
            case IRC.PRIVATE_MESSAGE: 
                add_channel_tab(message.parameters[0]).display_message(message);
                return;
            case "JOIN": 
                add_channel_tab(message.message); 
                return;
            case IRC.RPL_LUSERCLIENT:
            case "NOTICE":
            case IRC.RPL_MOTD:
            case IRC.RPL_MOTDSTART:
            case IRC.RPL_YOURHOST:
            case IRC.RPL_LUSEROP:
            case IRC.RPL_LUSERUNKNOWN:
            case IRC.RPL_LUSERCHANNELS:
                server_tab.display_message(message);
                return;
            case IRC.RPL_CREATED:
            case IRC.RPL_LUSERME:
                debug("SETTING TOPIC " + message.message);
                server_tab.set_topic(message.message, true);
                server_tab.display_message(message);
                return;
			case IRC.RPL_WELCOME:
				do_autoconnect();
				server_tab.tab.working = false;
                break;
			case IRC.RPL_NAMREPLY:
				var tab = find_channel_tab(message.parameters[2]);
				if (tab == server_tab)
					return;
				tab.add_users_message(message);
				break;
			case IRC.ERR_NICKNAMEINUSE:
            case IRC.ERR_NONICKNAMEGIVEN:
                string error_msg = "";
                if (message.message == null)
                    error_msg = "The name you chose is in use.";
                error_msg = url + "\n" + error_msg;
				name_in_use(error_msg);
				break;
            case IRC.ERR_NOSUCHNICK:
            case IRC.ERR_NOSUCHCHANNEL:
            case IRC.ERR_WASNOSUCHNICK:
            case IRC.ERR_UNKNOWNCOMMAND:
            case IRC.ERR_NOMOTD:
            case IRC.ERR_USERNOTINCHANNEL:
            case IRC.ERR_NOTONCHANNEL:
            case IRC.ERR_NOTREGISTERED:
            case IRC.ERR_NEEDMOREPARAMS:
            case IRC.ERR_UNKNOWNMODE:
            case IRC.ERR_ALREADYONCHANNEL:
            case IRC.ERR_CHANOPRIVSNEEDED:
                find_channel_tab(message.parameters[0]).display_error(message);
                break;
            default:
                warning("Unhandled message: " + msg);
                return;
        } 
    }

	public void do_register () {
        send_output ("PASS  -p");
        send_output ("NICK " + username);
        send_output("USER " + username + " " + username + " * :" + username);
        send_output("MODE " + username + " +i");
	}

	public void do_autoconnect () {
		foreach (var chan in channel_autoconnect) {
			join(chan);
		}
	}

	public void name_in_use (string message) {
		debug("At name in use");
		var dialog = new Dialog.with_buttons(_("Nickname in use"), backref.window,
		                                     DialogFlags.DESTROY_WITH_PARENT,
		                                     _("Connect"), Gtk.ResponseType.ACCEPT,
		                                     _("Cancel"), Gtk.ResponseType.CANCEL);
		Gtk.Box content = dialog.get_content_area() as Gtk.Box;
		content.pack_start(new Label(_(message)), false, false, 5);
		var server_name = new Entry();
		server_name.placeholder_text = _("New username");
		server_name.activate.connect(() => {
			dialog.response(Gtk.ResponseType.ACCEPT);
		});
		content.pack_start(server_name, false, false, 5);
		dialog.show_all();
		dialog.response.connect((id) => {
			switch (id){
				case Gtk.ResponseType.ACCEPT:
					string name = server_name.get_text().strip();
					if (name.length > 0) {
						username = server_name.get_text();
						do_register();
						dialog.close();
					}
					break;
				case Gtk.ResponseType.CANCEL:
					dialog.close();
					server_tab.tab.close();
                    foreach (var tab in channel_tabs.entries) {
                        tab.value.tab.close();
                    }
					break;
			}
		});
	}

    private void handle_ping (ref Message msg) {
        send_output("PONG " + msg.message);
    }

    public void stop () {
        exit = true;
        input_stream.clear_pending();
        try{
            input_stream.close();
        } catch (GLib.IOError e){}
        output_stream.clear_pending();
        try{
            output_stream.flush();
            output_stream.close();
        } catch (GLib.Error e){}
    }

	public void join (string channel) {
		send_output ("JOIN " + channel);
	}

    public void send_output (string output) {
        stderr.printf("Sending out " + output + "\n");
        try{
			if (output_stream == null || output_stream.is_closed())
				return;
            output_stream.put_string(output + "\r\n");
        }catch(GLib.Error e){}
    }

    public void do_exit () {
        exit = true;  
        input_stream.clear_pending();
		if (!input_stream.is_closed())
			try{
    			input_stream.close();
			}catch (IOError e) {}
		if (!output_stream.is_closed())
			try{
   				output_stream.close();
			}catch (IOError e) {}
    }

}
