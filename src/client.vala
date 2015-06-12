using GLib;
using Gtk;

public class Client : Object
{

	public DataInputStream input_stream;
	public DataOutputStream output_stream;
	public string url = ""; 
	public int tab;
	public string username = "";
	public bool exit = false; 
	public static const uint16 default_port = 6667;
	private Main backref;

	public signal void new_data(int index, string data);

	public Client(Main back)
	{
		backref = back;
	}

	public bool connect_to_server(string location, int tab_page)
	{
		url = location;
		tab = tab_page;
		
		Thread.create<int> (this.do_connect, true);  
		
		return true;
	}
 
	private int do_connect()
	{   
		SocketClient client = new SocketClient ();
		
		// Resolve hostname to IP address:
		Resolver resolver = Resolver.get_default ();
		List<InetAddress> addresses = resolver.lookup_by_name (url, null);
		InetAddress address = addresses.nth_data (0);
		stderr.printf ("address " + address.to_string());   
		SocketConnection conn = client.connect (new InetSocketAddress (address, default_port));
 
		input_stream = new DataInputStream (conn.input_stream);
		output_stream = new DataOutputStream (conn.output_stream);

		send_output ("PASS  -p");
		send_output ("NICK " + username);
		send_output("USER " + username + " " + username + " * :" + username);
		send_output("MODE " + username + " +i");

		string? line = "";
		do{
			size_t size;
			line = input_stream.read_line_utf8(out size);
			handle_input(line);
		}while(line != null && !exit);
 
		 
		return 1;
	}

	private void handle_input(string? msg)
	{
		if(msg == null)
		{
			stop();
			return;
		} 
		if(msg[0:4] == "PING")
		{
			handle_ping(msg);
			return;
		}if(msg[0:4] == "PONG")
		{
			info(msg);
			return;
		}else if(msg.length > 0 && msg[0] == ':')
		{ 
			new_data(tab, msg.substring(1) + "\n"); 
		}else{
			warning("Unhandled message: " + msg + "\n");
		}
	}

	private void handle_ping(string msg)
	{
		var split = msg.split(" ");
		send_output("PONG " + split[1]);
	}

	public void stop()
	{
		exit = true; 
		input_stream.clear_pending();
		try{
			input_stream.close();
		} catch (GLib.IOError e){} 
		output_stream.clear_pending();
		output_stream.flush();
		try{
			output_stream.close(); 
		} catch (GLib.IOError e){} 
	}

	public void send_output(string output)
	{
		output_stream.put_string(output + "\r\n");
	}
	
}