using GLib;
using GLib.Environment;
using Sqlite;
using Gee;

public class SqlClient : Object
{
	static SqlClient self = null;
	Sqlite.Database db;
	public ArrayList<Server> servers = new ArrayList<Server>();
	
	private SqlClient()
	{ 
		init();
	}

	public static SqlClient get_instance()
	{
		if(self == null)
			self = new SqlClient();

		return self;
	}

	private void init()
	{
		string confbase = GLib.Environment.get_user_config_dir() + "/kyrc";
		File dir = File.new_for_path(confbase);
		if(!dir.query_exists())
			dir.make_directory();

		string conffile = confbase + "/kyrc.db";
		
		int ec = Sqlite.Database.open_v2(conffile, out db);
		if (ec != Sqlite.OK) {
			stderr.printf ("Can't open database: %d: %s\n", db.errcode (), db.errmsg ()); 
		} 

		add_tables();
		refresh();
	}

	public void refresh()
	{
		servers.clear();
		db.exec("SELECT * from servers", refresh_callback);
		db.exec("SELECT * from channels", refresh_callback_channel);
	}

	public Server get_server(string name)
	{
		foreach(Server svr in servers)
		{
			if(svr.host == name)
				return svr;
		}
		return null;
	}

	public Server get_server_id(int id)
	{
		foreach(Server svr in servers)
		{
			if(svr.id == id)
				return svr;
		}
		return null;
	}

	public int update(Server svr)
	{
		stderr.printf("RUNNING SQL\n");
		
		Sqlite.Statement stmt;
		int ok;
		string sql = "SELECT id FROM servers WHERE id = " + svr.id.to_string();
		bool exists = false;
		db.exec(sql, (n_columns, values, column_names) => { 
			exists = true;
			return 0;
		}); 
 
		
		string keys = "";
		foreach(string i in Server.keys)
		{
			//Skip over ID
			if(keys == "")
			{
				keys = " ";
				
			}
			keys += i + "=$" + i + ", ";
		}

		keys = keys[0:-2];
 

		if(exists)
		{
			sql = "UPDATE servers SET " + keys + " WHERE id = " + svr.id.to_string();
		
			ok = db.prepare_v2(sql, sql.length, out stmt);
			if (ok != Sqlite.OK) { 
				critical (db.errmsg ());
				return -1;
	  		}
	 
			stmt.bind_text(1, svr.host);
			stmt.bind_int(2, svr.port);
			stmt.bind_text(3, svr.nickname);
			stmt.bind_text(4, svr.realname);
			stmt.bind_text(5, svr.username);
			stmt.bind_text(6, svr.password);
			stmt.bind_text(7, svr.on_connect); 
			stmt.bind_int(8, bool_to(svr.encryption));  
			stmt.bind_int(9, bool_to(svr.validate_server)); 
			stmt.bind_int(10, bool_to(svr.autoconnect));

			if(stmt.step() == Sqlite.DONE)
			{
				sql = "DELETE FROM channels WHERE server_id=" + svr.id.to_string();
				string errmsg;
				ok = db.exec(sql, null, out errmsg);  
				
				sql = "INSERT INTO channels (server_id, channel) VALUES(" + svr.id.to_string() + ", $CHANNEL)";

				ok = db.prepare_v2(sql, sql.length, out stmt);
				if (ok == Sqlite.ERROR) { 
					critical (db.errmsg ());
					return -1;
				}
				
				foreach(Channel chn in svr.channels)
				{ 
					stmt.bind_text(1, chn.channel);
					stmt.step(); 
				}
			}
		}
		return 0;
	}

	private int refresh_callback(int n_columns, string[] values, string[] column_names) {
		var server = new Server();
		for (int i = 0; i < n_columns; i++) {  
			switch(column_names[i])
			{
				case "id":
					server.id = values[i].to_int();
					break;
				case "host":
					server.host = values[i];
					break;
				case "port":
					server.port = values[i].to_int();
					break;
				case "nickname":
					server.nickname = values[i];
					break;
				case "realname":
					server.realname = values[i];
					break; 
				case "username":
					server.username = values[i];
					break;
				case "password":
					server.password = values[i];
					break;
				case "on_connect":
					server.on_connect = values[i];
					break;
				case "encryption":
					server.encryption = to_bool(values[i]);
					break;
				case "validate_server":
					server.validate_server = to_bool(values[i]);
					break; 
				case "autoconnect":
					server.autoconnect = to_bool(values[i]);
					break; 
			}
		} 
		servers.add(server);
		return 0;
	}

	private int refresh_callback_channel(int n_columns, string[] values, string[] column_names) {
		Server svr = null;
		for (int i = 0; i < n_columns; i++) { 
			if(column_names[i] == "server_id")
			{
				svr = get_server_id(values[i].to_int());
			}
		}
		Channel chn = new Channel();
		for (int i = 0; i < n_columns; i++) { 
			switch(column_names[i])
			{
				case "id":
					chn.id = values[i].to_int();
					break;
				case "server_id":
					chn.server_id = values[i].to_int();
					break;
				case "channel":
					chn.channel = values[i];
					break;
			}
		}
		svr.channels.add(chn);
		return 0;
	}

	public static bool to_bool(string input)
	{
		return (input == "1");
	}
	
	public static int bool_to(bool b)
	{
		return b ? 1 : 0;
	}

	public class Server{

		public const string[] keys = {"host", "port", "nickname", "realname", "username", "password", "on_connect", "encryption", "validate_server", "autoconnect"};
		
		public int id = -1;
		public string host = "";
		public int port = 6667;
		public string nickname = "";
		public string realname = "";
		public string username = "";
		public string password = "";
		public string on_connect = "";
		public bool encryption = false;
		public bool autoconnect = false;
		public bool validate_server = false;
		public ArrayList<Channel> channels = new ArrayList<Channel>();
	}

	public class Channel{
		public int id = -1;
		public int server_id;
		public string channel;
	}


	private void add_tables()
	{
		string sql = """
		CREATE TABLE IF NOT EXISTS "servers" (
			"id" INTEGER PRIMARY KEY AUTOINCREMENT,
			"host" TEXT NOT NULL,
			"port" INTEGER NOT NULL,
			"nickname" TEXT,
			"realname" TEXT,
			"username" TEXT,
			"password" TEXT,
			"on_connect" TEXT,
			"encryption" BOOL,
			"autoconnect" BOOL,
			"validate_server" BOOL
		);

		CREATE TABLE IF NOT EXISTS "channels" (
			"id" INTEGER PRIMARY KEY AUTOINCREMENT,
			"server_id" INTEGER,
			"channel" TEXT
		); 
		""";

		db.exec(sql);
	}
}
