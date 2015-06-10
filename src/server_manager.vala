using Gdk;
using Gtk;

public class ServerManager : Object
{
	Gtk.Window window;
	Entry new_channel;
	ListBox channels;
	ListBox servers;
	SqlClient sqlclient = SqlClient.get_instance();
	Button add_channel;
	
	public bool open_window(Gdk.EventButton event)
	{
			var builder = new Builder();
			builder.add_from_file(Main.UI_FILE_SERVERS);
			window = builder.get_object ("window") as Gtk.Window;
			var box = builder.get_object ("port_wrap") as Box;
			var ok = builder.get_object ("ok") as Button;
			var cancel = builder.get_object ("cancel") as Button;
			add_channel = builder.get_object ("add_channel") as Button;
			var remove_channel = builder.get_object ("remove_channel") as Button;
			new_channel = builder.get_object ("channel_name") as Entry;
			channels = builder.get_object ("channel") as ListBox;
			var server_btns = builder.get_object ("server_buttons") as Box;
			servers = builder.get_object ("servers") as ListBox;
			servers.set_selection_mode(SelectionMode.BROWSE); 
			servers.row_activated.connect(populate_fields);

            var add_server = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            var remove_server = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			server_btns.pack_end(add_server, false, false, 0);
			server_btns.pack_end(remove_server, false, false, 0);
			
			channels.set_size_request (100,100);			
			

			cancel.button_release_event.connect(cancel_clicked); 
			add_channel.button_release_event.connect(add_channel_clicked);
			add_server.button_release_event.connect(add_server_clicked);
			remove_server.button_release_event.connect(remove_server_clicked);
			
			Gtk.SpinButton port = new Gtk.SpinButton.with_range (0, 65535, 1);
			port.set_value(6667);
			box.pack_start(port, false, false, 0); 

			add_servers();
			window.show_all ();   

			return false;
	}

	
	public void populate_fields(ListBoxRow row)
	{   
		GLib.Value name = new GLib.Value(typeof (string)); 
	    row.get_property("name", ref name);
		stderr.printf("row changed " + name.get_string());
	}

	private void add_servers()
	{  
		ListBoxRow first_row = null;
		foreach(SqlClient.Server server in sqlclient.servers)
		{ 
			var lbr = new ListBoxRow();
			var lbl = new Label(server.host); 
			lbr.set_halign(Align.FILL);
			lbl.set_halign(Align.START);
			lbr.add(lbl);
			lbr.set_property("name", server.host);
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

	private bool add_channel_clicked(Gdk.EventButton event)
	{
		string chan_name = new_channel.get_text().strip();
		if(chan_name.length == 0)
			return false;
		var lbr = new ListBoxRow();
		var lbl = new Label(chan_name);
		lbl.set_halign(Align.START);
		lbr.add(lbl);
		channels.add(lbr);  
		var chn_adj = new Adjustment(1, 1, 500, 1, 2, 100); 
		channels.set_adjustment(chn_adj);
		channels.show_all();
		return false;
	}

	private bool add_server_clicked(Gdk.EventButton event)
	{ 
		stderr.printf("add clc");
		var lbr = new ListBoxRow();
		var lbl = new Label("");
		lbl.set_halign(Align.START);
		lbr.add(lbl);  
		servers.insert(lbr, -1); 
		servers.select_row(lbr); 
		servers.show_all();
		return false;
	}

	private bool remove_server_clicked(Gdk.EventButton event)
	{
		return false;
	}

	private bool cancel_clicked(Gdk.EventButton event)
	{ 
		window.close(); 
		return false;
	}
}