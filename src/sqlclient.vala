using GLib;
using GLib.Environment;
using Sqlite;

public class SqlClient : Object
{
	Sqlite.Database db;
	
	public SqlClient()
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
			"encryption" INTEGER DEFAULT (0),
			"validate_server" INTEGER DEFAULT (0)
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