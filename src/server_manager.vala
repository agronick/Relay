using Gdk;
using Gtk;
using Gee;

public class ServerManager : Object
{
	Gtk.Window window;
	Entry new_channel;
	ListBox channels;
	ListBox servers;
	ListBoxRow select_row = null;
	SqlClient sqlclient = SqlClient.get_instance();
	Button add_channel; 

	Entry host;
	SpinButton port;
	Entry real;
	Entry user;
	Entry pass;
	Entry nick;
	Switch encrypt;
	Switch autoconnect;
	Spinner spinner;
	SqlClient.Server current_server;  
	Gtk.TreeIter iter;
	ArrayList<string> svr_channels = new ArrayList<string>();
	
	public bool open_window(Gdk.EventButton event)
	{
			var builder = new Builder();
			builder.add_from_file(Main.UI_FILE_SERVERS);
		
			window = builder.get_object ("window") as Gtk.Window;
			var box = builder.get_object ("port_wrap") as Box;
			var ok = builder.get_object ("ok") as Button;
			var cancel = builder.get_object ("cancel") as Button;
			var remove_channel = builder.get_object ("remove_channel") as Button;
			var server_btns = builder.get_object ("server_buttons") as Box;
			add_channel = builder.get_object ("add_channel") as Button;
			new_channel = builder.get_object ("channel_name") as Entry;
			channels = builder.get_object ("channel") as ListBox;
			servers = builder.get_object ("servers") as ListBox;
			host = builder.get_object ("host") as Entry;
			real = builder.get_object ("real") as Entry;
			user = builder.get_object ("user") as Entry;
			pass = builder.get_object ("pass") as Entry;
			nick = builder.get_object ("nick") as Entry;
			spinner = builder.get_object ("spinner") as Spinner;
			encrypt = builder.get_object ("encrypt") as Switch;
			autoconnect = builder.get_object ("autoconnect") as Switch;
		 
 
			servers.set_selection_mode(SelectionMode.BROWSE); 
			servers.row_activated.connect(save_changes);
			servers.row_activated.connect(populate_fields);

            var add_server = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            var remove_server = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			server_btns.pack_end(add_server, false, false, 0);
			server_btns.pack_end(remove_server, false, false, 0);
			
			channels.set_size_request (100,100);	
			servers.set_size_request (175,50);	
			

			cancel.button_release_event.connect(cancel_clicked); 
			add_channel.button_release_event.connect(add_channel_clicked);
			add_server.button_release_event.connect(add_server_clicked);
			remove_server.button_release_event.connect(remove_server_clicked);
			remove_channel.button_release_event.connect(remove_channel_clicked);
			//host.changed.connect(host_text_changed); 

		
			var chn_adj = new Adjustment(1, 1, 500, 1, 2, 100); 
			channels.set_adjustment(chn_adj);

		
			port = new Gtk.SpinButton.with_range (0, 65535, 1);
			port.set_value(6667);
			box.pack_start(port, false, false, 0); 

			add_servers();
			window.show_all ();   

			return false;
	}
 

	public void save_changes(ListBoxRow row)
	{ 
		if(current_server == null)
			return;

		spinner.active = true;
		
		if(select_row != null)
		{
			int index = select_row.get_index();
			var newrow = get_list_box_row (host.get_text());
			servers.remove(select_row);
			servers.insert(newrow, index);
			servers.show_all();
		}
		
		current_server.host = host.get_text();
		current_server.realname = real.get_text(); 
		current_server.username = user.get_text();
		current_server.password = pass.get_text();
		current_server.nickname = nick.get_text();
		current_server.port = port.get_value_as_int();
		current_server.encryption = encrypt.get_active();
		current_server.autoconnect = autoconnect.get_active();

		current_server.channels.clear();
		foreach(string c in svr_channels)
		{ 
			var chan = new SqlClient.Channel();
			chan.channel = c;
			chan.server_id = current_server.id;
			current_server.channels.add(chan);
		}

		sqlclient.update(current_server);
		 
		sqlclient.refresh(); 

		spinner.active = false;
 
	}
 
 
	public void populate_fields(ListBoxRow row)
	{     
		select_row = row;
		
		SqlClient.Server svr = sqlclient.get_server(row.name);
		if(svr == null)
			svr = new SqlClient.Server();

		current_server = svr;
		
		host.set_text(svr.host);
		user.set_text(svr.username);
		real.set_text(svr.realname);
		pass.set_text(svr.password);
		port.set_value(svr.port);
		nick.set_text(svr.nickname); 
		encrypt.set_state(svr.encryption);
		autoconnect.set_state(svr.autoconnect);

		foreach(Widget lbr in channels.get_children())
		{
			channels.remove(lbr);
		}

		svr_channels.clear(); 
		
		foreach(SqlClient.Channel chn in svr.channels)
		{  
			var lbr = get_list_box_row(chn.channel); 
			channels.insert(lbr, -1); 
			svr_channels.add(chn.channel);
		}
		
		channels.show_all(); 
	}

	private ListBoxRow get_list_box_row(string name)
	{
		var lbr = new ListBoxRow();
		var lbl = new Label(name); 
		lbr.add(lbl);
		lbr.set_halign(Align.FILL);
		lbl.set_halign(Align.START);
		lbr.name = name;
		return lbr;
	}
 

	private void add_servers()
	{  
		ListBoxRow first_row = null;
		foreach(SqlClient.Server server in sqlclient.servers)
		{ 
			var lbr = get_list_box_row(server.host);
			servers.insert(lbr, -1);
			if(first_row == null)
				first_row = lbr;
		}

		if(sqlclient.servers.size < 1)
		{
			add_channel.activate();
		}else{
			servers.select_row(first_row);
		} 
	}

	private bool remove_channel_clicked(Gdk.EventButton event)
	{ 
		var widget = channels.get_selected_row();
		if(!svr_channels.remove(widget.name))
			stderr.printf("Could not find row to remove" + widget.name);
		channels.remove(widget);
		return false;
	}
	
	private bool remove_server_clicked(Gdk.EventButton event)
	{
		var widget = servers.get_selected_row();
		
		servers.remove(widget);
		return false;
	}

	private bool add_channel_clicked(Gdk.EventButton event)
	{
		string chan_name = new_channel.get_text().strip();
		if(chan_name.length == 0)
			return false;
		var lbr = get_list_box_row(chan_name);
		svr_channels.add(chan_name);
		new_channel.set_text("");
		channels.add(lbr);  
		channels.show_all();
		return false;
	}

	private bool add_server_clicked(Gdk.EventButton event)
	{  
		var lbr = new ListBoxRow();
		var lbl = new Label("");
		lbl.set_halign(Align.START);
		lbr.add(lbl);  
		servers.insert(lbr, -1); 
		servers.select_row(lbr); 
		servers.show_all();
		return false;
	}
 

	private bool cancel_clicked(Gdk.EventButton event)
	{ 
		window.close(); 
		return false;
	}
}
