
/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main_window.vala
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

using GLib;
using Gtk;
using Gdk;
using Gee;
using Granite;
using Pango;

public class MainWindow : Object
{

	/*
	 * Uncomment this line when you are done testing and building a tarball
	 * or installing
	 */
	//const string UI_FILE = Config.PACKAGE_DATA_DIR + "/ui/" + "relay.ui";
	public const string UI_FILE = "ui/relay.ui";
	public const string UI_FILE_SERVERS = "ui/server_window.ui";


	public static Gtk.Window window;
	public static Entry input;
	Granite.Widgets.DynamicNotebook tabs;
	Paned pannel;
	Button channel_subject;
	Button channel_users;
	Icon channel_tab_icon_new_msg;
	TextView subject_text;
	Box users_list;
	bool update_users_on_close = false;
	Gtk.Menu user_menu;
	Label users_header;
	Popover users_popover;
	ScrolledWindow users_scrolled;
	HeaderBar toolbar;
	string channel_user_selected = "";
	Relay app;
	HashMap<string, Widgets.SourceList.Item> items_sidebar;
	Gtk.Menu tab_rightclick;
	Gtk.Menu tab_channel_list;
	DragFile drag_file;
	public static Button paste;
	public static Box paste_box;
	Icon inactive_channel;
	Icon active_channel;

	Gee.HashMap<int, ChannelTab> outputs = new Gee.HashMap<int, ChannelTab> ();
	Gee.HashMap<string, Connection> clients = new Gee.HashMap<string, Connection> (); 
	Granite.Widgets.SourceList servers = new Granite.Widgets.SourceList();

	public static int current_tab = -1;


	public MainWindow (Relay application) {
		try {
			app = application;

			inactive_channel = new Pixbuf.from_file(Relay.get_asset_file("assets/user-offline.svg"));
			active_channel = new Pixbuf.from_file(Relay.get_asset_file("assets/user-idle.svg"));
			servers.set_tooltip_text(_("Double click an item to connect"));

			var builder = new Builder ();
			builder.add_from_file (Relay.get_asset_file(UI_FILE));
			builder.connect_signals (this);

			toolbar = new HeaderBar (); 
			if (Relay.on_kde)
				toolbar.decoration_layout = "";
			tabs = new Granite.Widgets.DynamicNotebook();
			tabs.add_button_tooltip = _("Connect to a server");
			tabs.add_button_visible = false;
			tabs.allow_drag = true;
			tabs.show_icons = true;

			window = builder.get_object ("window") as Gtk.Window;
			Relay.set_color_mode(window.get_style_context().get_color(StateFlags.NORMAL));
	
			window.destroy.connect(relay_close_program);
			application.add_window(window);
			var nb_wrapper = builder.get_object("notebook_wrapper") as Box;
			nb_wrapper.pack_start(tabs, true, true, 0); 
			tabs.show_all();
			channel_tab_icon_new_msg = new Pixbuf.from_file(Relay.get_asset_file("assets/mail-unread.svg"));

			//Slide out panel
			pannel = builder.get_object("pannel") as Paned;
			var server_list_container = builder.get_object("server_list_container") as Box;
			server_list_container.pack_start(servers, true, true, 0);

			//Slide out panel button
			Image icon = new Image.from_file(Relay.get_asset_file("assets/server-icon.svg"));
			Button select_channel = new Gtk.Button();
			select_channel.image = icon;
			var trans = RGBA();
			trans.parse("#FFFFFFFF");
			select_channel.override_background_color(StateFlags.NORMAL, trans);

			select_channel.tooltip_text = _("Open server/channel view");
			toolbar.pack_start(select_channel);
			select_channel.button_release_event.connect(slide_panel);
			pannel.position = 1;

			input = builder.get_object("input") as Entry;
			input.activate.connect (() => {
				send_text_out(input.get_text ());
				input.set_text("");
			});

			//Channel subject button
			channel_subject = new Button();
			channel_subject.image = new Image.from_file(Relay.get_asset_file("assets/help-info-symbolic.svg"));
			channel_subject.tooltip_text = _("Channel subject");
			var subject_popover = new Gtk.Popover(channel_subject);
			//subject_popover.set_property("transitions-enabled", true);
			channel_subject.clicked.connect(() => {
				subject_popover.show_all();
			});
			channel_subject.set_no_show_all(true);
			channel_subject.hide();
			var scrolled = new Gtk.ScrolledWindow(null, null);
			subject_text = new Gtk.TextView();
			subject_text.set_wrap_mode(Gtk.WrapMode.WORD);
			subject_text.buffer.text = "";
			subject_text.cursor_visible = false;
			subject_text.editable = false;
			subject_text.margin = 10;
			scrolled.set_size_request(320, 110);
			scrolled.add(subject_text);
			subject_popover.add(scrolled);
			toolbar.pack_end(channel_subject);

			//Channel users button
			channel_users = new Button();
			channel_users.image = new Image.from_file(Relay.get_asset_file("assets/system-users.svg"));
			channel_users.tooltip_text = _("Channel users");
			channel_users.hide();
			users_popover = new Gtk.Popover(channel_users);
			//users_popover.set_property("transitions-enabled", true);
			channel_users.clicked.connect(() => {
				users_popover.show_all();
			});
			users_popover.closed.connect( () => {
				if (update_users_on_close) {
					user_names_changed(current_tab);
					update_users_on_close = false;
				}
			});
			toolbar.button_press_event.connect( ()=> {
				toolbar.grab_focus();
				return true;
			});

			users_scrolled = new Gtk.ScrolledWindow (null, null);
			users_scrolled.vscrollbar_policy = PolicyType.NEVER;
			users_scrolled.hscrollbar_policy = PolicyType.AUTOMATIC;
			users_list = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			users_scrolled.add(users_list);

			var users_wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			var font = new FontDescription();
			font.set_weight(Pango.Weight.BOLD);
			users_header = new Label("");
			users_header.override_font(font);
			users_header.height_request = 24;
			users_wrap.pack_start(users_header, true, false, 4);
			users_wrap.pack_start(users_scrolled);
			users_popover.add(users_wrap);
			toolbar.pack_end(channel_users);
			user_menu = new Gtk.Menu();
			Gtk.MenuItem private_message = new Gtk.MenuItem.with_label (_("Private Message"));
			user_menu.add(private_message);
			Gtk.MenuItem block = new Gtk.MenuItem.with_label (_("Block"));
			private_message.button_release_event.connect(click_private_message);
			block.button_release_event.connect(click_block);
			user_menu.add(block);
			user_menu.show_all();

			servers.item_selected.connect(set_item_selected);

			set_up_add_sever(builder);

			toolbar.set_title(app.program_name);

			toolbar.show_close_button = true;
			window.set_titlebar(toolbar);
			window.show_all();

			toolbar.show_all();

			/*
			 * Hastebin code
			 */ 
			paste_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
			paste = new Button();
			paste_box.pack_start(paste);
			paste_box.show_all();
			paste.focus_on_click = false;
			var paste_img = new Image.from_file(Relay.get_asset_file("./assets/paste.png"));
			paste.set_image(paste_img);
			paste.set_tooltip_text(_("Drag a files here to upload to Hastebin.com"));
			paste.activate();
			toolbar.pack_end(paste_box);
			drag_file = new DragFile();
			drag_file.attach_spinner(paste_box);
			drag_file.attach_button(paste);
			Gtk.drag_dest_set(paste, 
			                  Gtk.DestDefaults.ALL,
			                  DragFile.TARGETS, Gdk.DragAction.LINK);
			drag_file.file_uploaded.connect(file_uploaded);
			paste.drag_data_received.connect(drag_file.drop_file);
			paste.enter_notify_event.connect((event) => {
				paste.activate();
				return true;
			});

			tabs.tab_removed.connect(tab_remove);
			tabs.tab_switched.connect(tab_switch); 

			SqlClient.get_instance();

			refresh_server_list(); 

			load_autoconnect();

			tab_rightclick = new Gtk.Menu();
			Gtk.MenuItem close_all = new Gtk.MenuItem.with_label(_("Close All"));
			close_all.activate.connect( ()=> {
				outputs.entries.foreach( (item)=> {
					if(item != null)
						tabs.remove_tab(item.value.tab);
					return true;
				});
			});
			Gtk.MenuItem new_tab = new Gtk.MenuItem.with_label(_("New Tab"));
			new_tab.activate.connect(new_tab_requested);

			Gtk.MenuItem channel_list_menu = new Gtk.MenuItem.with_label(_("Switch"));
			tab_channel_list = new Gtk.Menu();
			channel_list_menu.set_submenu(tab_channel_list);

			tab_rightclick.add(channel_list_menu);
			tab_rightclick.add(close_all);
			tab_rightclick.add(new_tab);

			tab_rightclick.show_all();

		}
		catch (Error e) {
			error("Could not load UI: %s\n", e.message);
		}

	}

	public void rebuild_channel_list_menu() {
		tab_channel_list.forall( (widget) => {
			tab_channel_list.remove(widget);
		});
		foreach (var tab in outputs.entries) {
			Gtk.MenuItem item = new Gtk.MenuItem.with_label(tab.value.tab.label);
			item.activate.connect( ()=> {
				tabs.current = tab.value.tab;
			});
			tab_channel_list.add(item);
			item.show_all();
		}
		tab_channel_list.show_all();
	}

	public Gtk.Popover make_popover (Button parent) {
		var popover = new Gtk.Popover(parent);
		popover.set_no_show_all(true);
		popover.hide();
		return popover;
	}

	private static Widgets.SourceList.Item current_selected_item;
	private void set_item_selected (Widgets.SourceList.Item? item) {
		current_selected_item = item;
	}

	/* 
	 *  The connection calls this method to create a tab anytime a
	 *  channel or server is opened
	 */
	public static int index = 0;
	public void add_tab (ChannelTab new_tab) {
		Idle.add( () => { 
			new_tab.tab = new Widgets.Tab();
			new_tab.tab.menu = tab_rightclick;
			new_tab.tab.ellipsize_mode = EllipsizeMode.NONE;

			if (new_tab.is_server_tab) {
				new_tab.tab.working = true;
				if (new_tab.connection.error_state) {
					tabs.remove_tab(new_tab.tab);
					return false;
				}
			}
			TextView output = new TextView();
			output.set_editable(false);
			output.set_cursor_visible(false);
			output.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
			output.set_left_margin(IRC.USER_WIDTH);
			output.set_indent(IRC.USER_WIDTH * -1);
			output.override_font(FontDescription.from_string("Inconsolata 9"));
			ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
			if (!Relay.on_ubuntu)
				scrolled.margin = 3;
			scrolled.add(output);

			var ptabs = new Pango.TabArray(1, true);
			ptabs.set_tab(0, Pango.TabAlign.LEFT, IRC.USER_WIDTH);
			output.tabs = ptabs;

			new_tab.tab.restore_data = new_tab.tab.label = new_tab.channel_name; 
			new_tab.tab.page = scrolled;
			new_tab.new_subject.connect(new_subject);
			new_tab.user_names_changed.connect(user_names_changed);
			tabs.insert_tab(new_tab.tab, -1); 

			new_tab.set_output(output);
			outputs.set(index, new_tab); 

			tabs.show_all();

			new_tab.tab_index = index;

			if (tabs.n_tabs == 1) {
				tab_switch (null, new_tab.tab);
			}

			new_tab.tab.icon = null;

			index++;
			if (items_sidebar.has_key(new_tab.tab.label))
				items_sidebar[new_tab.tab.label].icon = active_channel;

			rebuild_channel_list_menu();
			return false;
		});


		if (new_tab.channel_name != new_tab.connection.server.host) {
			new_tab.connection.send_output("TOPIC " + new_tab.channel_name);
		}
	}

	public void new_tab_requested () {
		var dialog = new Dialog.with_buttons(_("New Connection"), window,
		                                     DialogFlags.DESTROY_WITH_PARENT,
		                                     "Connect", Gtk.ResponseType.ACCEPT,
		                                     "Cancel", Gtk.ResponseType.CANCEL);
		Gtk.Box content = dialog.get_content_area() as Gtk.Box;
		content.pack_start(new Label(_("Server address")), false, false, 5);
		var server_name = new Entry();
		server_name.activate.connect(() => {
			dialog.response(Gtk.ResponseType.ACCEPT);
		});
		content.pack_start(server_name, false, false, 5);
		dialog.show_all();
		dialog.response.connect((id) => {
			switch (id){
				case Gtk.ResponseType.ACCEPT:
					string name = server_name.get_text().strip();
					if (name.length > 2) {
						var server = new SqlClient.Server();
						server.host = name;
						server.nickname = server.username = Environment.get_user_name();
						add_server(server);
						dialog.close();
					}
					break;
				case Gtk.ResponseType.CANCEL:
					dialog.close();
					break;
			}
		});
	}

	private void tab_remove (Widgets.Tab tab) {  
		if (tab.label == _("Welcome"))
			return;

		int id = lookup_channel_id(tab);
		Connection tab_server = outputs[id].connection; 

		if (!outputs[id].is_server_tab)
			tab_server.send_output("PART " + outputs[id].channel_name);

		//Remove tab from the servers tab list
		tab_server.channel_tabs.unset(tab.label);

		//Remove server if no connections are left
		if (tab_server.channel_tabs.size < 1) {
			info("Closing server");
			tab_server.do_exit();
			clients.unset(tab_server.server.host);
		}

		//Remove the tab from the list of tabs
		outputs.unset(id);

		//Change the icon in the sidebar
		if (items_sidebar.has_key(tab.label))
			items_sidebar[tab.label].icon = inactive_channel;
		
		if (tabs.n_tabs == 0)
			show_welcome_screen();
	}

	private void tab_switch (Granite.Widgets.Tab? old_tab, Granite.Widgets.Tab new_tab) {
		if (new_tab.label == _("Welcome")) {
			channel_subject.hide();
			channel_users.hide();
			input.hide();
			toolbar.set_title(app.program_name);
			toolbar.set_has_subtitle(false);
			toolbar.set_subtitle("");
			paste.hide();
			return;
		}

		input.show();

		new_tab.icon = null;

		current_tab = lookup_channel_id(new_tab);
		if (!outputs.has_key(current_tab))
			return;
		ChannelTab using_tab = outputs[current_tab];


		if (items_sidebar.has_key(using_tab.tab.label))
			items_sidebar[using_tab.tab.label].badge = "";

		if (using_tab.has_subject) 
			new_subject (current_tab, using_tab.channel_subject.validate(-1) ? using_tab.channel_subject : using_tab.channel_subject.escape(""));
		else
			channel_subject.hide();

		if (using_tab.is_server_tab) {
			toolbar.set_title(using_tab.tab.label);
			toolbar.set_has_subtitle(false);
			toolbar.set_subtitle("");
			channel_users.hide();
			paste.hide();
		} else {
			paste.show();
			toolbar.set_title(using_tab.tab.label);
			toolbar.set_subtitle(using_tab.connection.server.host);
			toolbar.has_subtitle = (using_tab.tab.label != using_tab.connection.server.host);

			input.placeholder_text = using_tab.tab.label;
			make_user_popover(using_tab);
		}
	}

	private void make_user_popover (ChannelTab using_tab) {
		if (users_popover.is_visible()) {
			update_users_on_close = true;
			return;
		}

		//Make users
		foreach (var box in users_list.get_children())
			users_list.remove(box);

		if (using_tab.users.size < 1)
			channel_users.hide();
		else
			channel_users.show_all();

		using_tab.users.sort(IRC.compare);

		int PER_BOX = 15;
		int BOX_WIDTH = 140;
		int MAX_COLS = 4;
		var listbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		int i = 0;
		int type_change = 0;
		LinkedList<LinkedList<string>> user_types = new LinkedList<LinkedList<string>>();
		user_types.add(using_tab.owners);
		user_types.add(using_tab.ops);
		user_types.add(using_tab.half_ops);
		user_types.add(using_tab.users);
		int total_size = using_tab.users.size + using_tab.owners.size + using_tab.ops.size + using_tab.half_ops.size;
		foreach(LinkedList<string> type in user_types) {
			foreach (string user in type) {
				listbox.pack_start(make_user_eventbox(user, type_change), false, false, 0);
				i++;
				if (i % PER_BOX == 0 && total_size >= i) {
					listbox.width_request = BOX_WIDTH;
					users_list.pack_start(listbox, true, true, 0);
					listbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
				}
			}
			type_change++;
		}
		listbox.width_request = BOX_WIDTH;

		users_header.set_text(_("Total users: ") + i.to_string());

		int cols = (int) Math.ceilf((float)i / (float)PER_BOX); 
		users_scrolled.min_content_width = (cols > MAX_COLS) ? BOX_WIDTH * MAX_COLS : cols * BOX_WIDTH;
		users_list.pack_start(listbox, true, true, 0);
	}

	private EventBox make_user_eventbox (string user, int type = -1) {
		var eb = new EventBox();
		eb.enter_notify_event.connect( ()=> {
			eb.set_state_flags(StateFlags.PRELIGHT | StateFlags.SELECTED, true);
			return false;
		});
		eb.leave_notify_event.connect( ()=> {
			eb.set_state_flags(StateFlags.NORMAL, true);
			return false;
		});
		var label = new Label("");
		var color = RGBA();
		if (type == 0) {
			color.parse("#00D901");
			label.set_tooltip_text(_("Owner"));
			label.override_color(StateFlags.NORMAL, color);
		} else if (type == 1) {
			color.parse("#F5E219");
			label.set_tooltip_text(_("Operator"));
			label.override_color(StateFlags.NORMAL, color);
		} else if (type == 2) {
			color.parse("#9A19F5");
			label.set_tooltip_text(_("Half Operator"));
			label.override_color(StateFlags.NORMAL, color);
		} else if (outputs[current_tab].blocked_users.contains(user)) {
			color.parse("#FF0000");
			label.override_color(StateFlags.NORMAL, color);
		}
		label.set_text(user);
		label.width_chars = IRC.USER_LENGTH;
		label.margin_top = label.margin_bottom = 4;
		eb.add(label);
		eb.button_press_event.connect( (event)=> {
			if (event.button == 3) {
				channel_user_selected = user;
				user_menu.popup (null, null, null, event.button, event.time);
			} else if (event.button == 1) {
				MainWindow.fill_input(user + ": ");
			}
			return true;
		});
		return eb;
	}

	private bool click_private_message (Gdk.EventButton event) {
		info("Selected user is " + channel_user_selected);
		user_menu.popdown();
		users_popover.set_visible(false);
		ChannelTab using_tab = outputs[current_tab];
		ChannelTab user_tab = using_tab.connection.add_channel_tab(IRC.remove_user_prefix(channel_user_selected));
		tabs.current = user_tab.tab;
		return false;
	}

	private bool click_block (Gdk.EventButton event) {
		user_menu.popdown();
		ChannelTab using_tab = outputs[current_tab];
		if (using_tab.blocked_users.contains(channel_user_selected))
			using_tab.remove_block_list(channel_user_selected);
		else
			using_tab.add_block_list(channel_user_selected);
		users_popover.set_visible(false);
		make_user_popover(using_tab);
		return false;
	}

	public void add_server (SqlClient.Server server, LinkedList<string>? connect_channels = null) {
		var connection = new Connection(this);
		clients.set(server.host, connection); 

		if (connect_channels != null)
			connection.channel_autoconnect = connect_channels;

		connection.connect_to_server(server);
	}

	public void refresh_server_list () {
		var root = servers.root;
		root.clear();

		items_sidebar = new HashMap<string, Widgets.SourceList.Item>();

		foreach (var svr in SqlClient.servers.entries) {
			var s =  new Widgets.SourceList.ExpandableItem(svr.value.host);
			root.add(s);
			var chn = new Widgets.SourceList.Item(svr.value.host);
			chn.set_data<string>("type", "server");
			chn.set_data<SqlClient.Server>("server", svr.value);
			chn.activated.connect(item_activated);
			chn.icon = inactive_channel;
			s.add(chn);
			items_sidebar[svr.value.host] = chn;

			foreach (var c in svr.value.channels) {
				chn = new Granite.Widgets.SourceList.Item(c.channel);
				chn.set_data<string>("type", "channel");
				chn.set_data<SqlClient.Channel>("channel", c);
				chn.activated.connect(item_activated);
				chn.icon = inactive_channel;
				s.add(chn);
				items_sidebar[c.channel] = chn;
			}
		}
	}


	public void add_text (ChannelTab tab, Message message, bool error = false) {
		if (error) {
			message.message = _("Error: ") + message.message;
			tab.display_error(message);
		} else
			tab.display_message(message);
		Idle.add( ()=> {
			if (current_tab != tab.tab_index) {
				tab.message_count++;
				if (items_sidebar.has_key(tab.tab.label) && !tab.is_server_tab)
					items_sidebar[tab.tab.label].badge = tab.message_count.to_string();
				tab.tab.icon = channel_tab_icon_new_msg;
			}
			return false;
		});
	}

	public void send_text_out (string text) {
		if (current_tab == -1 || !outputs.has_key(current_tab))
			return;
		var output = outputs[current_tab]; 
		output.send_text_out(text);

		var message = new Message();

		//Append message to screen
		message.user_name_set(output.connection.server.nickname);
		message.message = text;
		message.command = "PRIVMSG";
		message.internal = true;
		add_text(output, message); 
		return; 
	}

	private void item_activated () {
		string type = current_selected_item.get_data<string>("type");
		if (type == "server") {
			//Has existing server
			SqlClient.Server server = current_selected_item.get_data<SqlClient.Server>("server");
			foreach (var tab in outputs.entries) {
				if (tab.value.is_server_tab && tab.value.channel_name == server.host) {
					tabs.current = tab.value.tab;
					return;
				}
			}
			//No existing server
			add_server(server);
		} else {
			//Existing channel tab
			SqlClient.Channel channel = current_selected_item.get_data<SqlClient.Channel>("channel");
			var server = SqlClient.servers[channel.server_id];
			foreach (var tab in outputs.entries) {
				if (!tab.value.is_server_tab && 
				    tab.value.tab.label == channel.channel &&
				    server.host == tab.value.connection.server.host) {
					tabs.current = tab.value.tab;
					return;
				}
			} 
			//Has existing server but no channel
			foreach (var con in clients.entries) {
				if (con.key == server.host) {
					if (con.value.server_tab.tab.working)
						con.value.channel_autoconnect.add(channel.channel);
					else
						con.value.join(channel.channel);
					return;
				}
			}
			//Has no existing server or channel
			LinkedList<string> channels = new LinkedList<string>();
			channels.add(channel.channel);
			add_server(SqlClient.servers[channel.server_id], channels);
		}
	} 

	public void user_names_changed (int tab_id) {
		if (current_tab == tab_id) {
			make_user_popover(outputs[tab_id]);
		}
	}

	int sliding = 0;
	public bool slide_panel () {
		if (sliding > 1)
			return false;
		new Thread<int>("slider_move", move_slider_t);
		return false;
	}

	public int move_slider_t () {
		sliding++;
		while (sliding > 1)
			Thread.usleep(1000);
		int add, end, go_to, pos;
		bool opening;
		opening = (pannel.position < 10);
		end = opening ? 550 : 618;
		add = 1;
		go_to = 180;
		for (int i = pannel.position; i < end; i+= add) {
			if (opening) {
				pos = (int) Relay.ease_out_elastic(i, 0.0F, go_to, end);
				if (i > 420) 
					break;
			} else {
				pos = (int) Relay.ease_in_bounce(end - i, 0.0F, go_to, end);
			}

			pannel.set_position(pos);
			Thread.usleep(3600);
		}
		sliding--;
		return 0;
	}

	public int lookup_channel_id (Widgets.Tab tab) {
		foreach (var output in outputs.entries) { 
			if (output.value.tab == tab) {
				return output.key;
			}
		}
		return -1;
	}

	private void new_subject (int tab_id, string message) {
		if (tab_id != current_tab || message.strip().length == 0) {
			return;
		}

		subject_text.buffer.set_text(message);
		channel_subject.set_no_show_all(false); 
		channel_subject.show_all(); 
	}

	public static void fill_input (string message) {
		MainWindow.input.set_text(message);
		MainWindow.input.is_focus = true;
		MainWindow.input.select_region(message.length, message.length);
	}

	public void file_uploaded(string url) {
		MainWindow.input.set_text(MainWindow.input.get_text() + " " + url);
	}

	private void load_autoconnect () {
		bool opened_tab = false;

		foreach (var server in SqlClient.servers.entries) {
			var to_connect = server.value.get_autoconnect_channels();
			if (to_connect.size > 0) {
				opened_tab = true;
				add_server(server.value, to_connect);
			}
		}

		if (!opened_tab)
			show_welcome_screen();
	}

	private void show_welcome_screen () {
		var sm = new ServerManager();
		var title = _("Welcome to Relay");
		var message =  _("Lets get started");
		var welcome = new Widgets.Welcome(title, message);
		welcome.append_with_image(new Image.from_file(Relay.get_asset_file("assets/manage-servers.png")), _("Manage"), _("Manage the servers you use"));
		welcome.append_with_image(new Image.from_file(Relay.get_asset_file("assets/connect-server.png")), _("Connect"), _("Connect to a single server"));
		welcome.append_with_image(new Image.from_file(Relay.get_asset_file("assets/saved-server.png")), _("Saved"), _("Connect to a saved server"));

		var tab = new Widgets.Tab();
		tab.icon = null;
		tab.label = _("Welcome");
		toolbar.set_title(app.program_name);
		toolbar.set_subtitle("");
		toolbar.set_has_subtitle(false);
		tab.page = welcome;
		tabs.insert_tab(tab, -1);

		welcome.activated.connect( (index) => {
			switch (index) {
				case 0:
					sm.open_window();
					sm.window.destroy.connect( () => {
						refresh_server_list ();
					});
					return;
				case 1:
					new_tab_requested();
					return;
				case 2:
					slide_panel();
					return;
			}
		});
	}

	public void set_up_add_sever (Builder builder) {
		var add_server_button = builder.get_object("manage_servers") as Button;

		var sm = new ServerManager();
		add_server_button.button_release_event.connect( (event) => {
			sm.open_window();
			sm.window.destroy.connect( () => {
				refresh_server_list ();
			});
			return false;
		});
	}

	public void relay_close_program () { 
		foreach(var client in clients.entries) {
			client.value.do_exit();
		}
		GLib.Process.exit(0);
	}

	[CCode (instance_pos = -1)]
	public void on_destroy (Widget window) {
		Gtk.main_quit();
	}
}

