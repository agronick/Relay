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
	}

	public Server get_server(string name)
	{

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
				case "autoconnect":
					server.validate_server = to_bool(values[i]);
					break; 
			}
		}
		servers.add(server);
		return 0;
	}

	public static bool to_bool(string input)
	{
		return (input == "true");
	}

	public class Server{
		public int id;
		public string host;
		public int port;
		public string nickname;
		public string realname;
		public string username;
		public string password;
		public string on_connect;
		public bool encryption;
		public bool autoconnect;
		public bool validate_server;
		public ArrayList<Channel> channels;
	}

	public class Channel{
		public int id;
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