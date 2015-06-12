using GLib;
using Gtk;

public class Client : Object
{

	public DataInputStream input_stream;
	public DataOutputStream output_stream;
	private string url = ""; 
	public int tab;
	public string username = "";
	public bool exit = false; 
	public static const uint16 default_port = 6667;

	public signal void new_data(int index, string data);
 

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

		send_output ("NICK " + username);
		send_output("USER " + username + " null null :" + username);

		string? line = "";
		do{
			line = input_stream.read_line().strip().substring (1);
			new_data(tab, line); 
		}while(line != null && !exit);
 
		 
		return 1;
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