using GLib;
using Gtk;

public class Client : Object
{

	public DataInputStream input_stream;
	public DataOutputStream output_stream;
	private string url = ""; 
	public int tab;
	public string username = "";

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
		SocketConnection conn = client.connect (new InetSocketAddress (address, 6667));
 
		input_stream = new DataInputStream (conn.input_stream);
		output_stream = new DataOutputStream (conn.output_stream);

		send_output ("NICK " + username);
		send_output("USER " + username + " null null :" + username);

		string? line = "";
		do{
			line = input_stream.read_line().strip().substring (1);
			new_data(tab, line); 
		}while(line != null);
		 
		return 1;
	}

	public void send_output(string output)
	{
		output_stream.put_string(output + "\r\n");
	}
	
}