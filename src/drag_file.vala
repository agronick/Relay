/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * drag_file.vala
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
     *
 * Relay is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
     * 
 * Relay is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using GLib;

internal class DragFile : GLib.Object {

    private const string HASTEBIN_HOST = "hastebin.com";
    private Button paste;
    private Spinner spinner;

    public signal void file_uploaded(string url);

    public const Gtk.TargetEntry[] TARGETS = {
        {"text/uri-list",0,0}
    };

    public void attach_spinner (Box box) {
        spinner = new Spinner();
        spinner.active = true;
        spinner.hide();
        box.pack_start(spinner);
    }

    public void attach_button (Button _paste) {
        paste = _paste;
    }

    public void reset_ui () {
        Idle.add( ()=> {
            paste.show();
            spinner.hide();
            return false;
        });
    }

    /* Method definitions */
    public void drop_file (Gdk.DragContext context, int x, int y, SelectionData selection_data, uint info, uint time_) {
        paste.hide();
        spinner.show();

        foreach (string uri in selection_data.get_uris()) {
            new Thread<int>("Pastebin post", ()=>{
                try{
                    string contents = "";
                    var path = File.new_for_uri(uri);

                    int64 file_size = path.query_info ("*", FileQueryInfoFlags.NONE).get_size ();

                    if (file_size > 500000) {
                        Relay.show_error_window(_("The file " + uri + " is too large"));
                        return 1;
                    }

                    var dis = new DataInputStream(path.read());
                    string line;
                    // Read lines until end of file (null) is reached
                    while ((line = dis.read_line (null)) != null) {
                        contents += line + "\n";
                    }

                    SocketClient client = new SocketClient ();
                    Resolver resolver = Resolver.get_default ();
                    GLib.List<InetAddress> addresses = resolver.lookup_by_name(HASTEBIN_HOST, null);
                    InetAddress address = addresses.nth_data (0);
                    SocketConnection conn = client.connect (new InetSocketAddress (address, 80));
                    var input_stream = new DataInputStream (conn.input_stream);
                    var output_stream = new DataOutputStream (conn.output_stream);

                    output_stream.put_string("POST /documents HTTP/1.0\r\n");
                    output_stream.put_string("Host: hastebin.com\r\n");
                    output_stream.put_string("Accept: */*\r\n");
                    output_stream.put_string("Content-Length: " + contents.length.to_string() + "\r\n");
                    output_stream.put_string("Content-Type: application/x-www-form-urlencoded\r\n");
                    output_stream.put_string("\r\n");
                    output_stream.put_string(contents);
                    output_stream.flush();

                    size_t length;
                    string? output = "";
                    string json = "";
                    do{
                        output = input_stream.read_line(out length);
                        if (output != null && output[0] == '{' && output[output.length - 1] == '}')
                            json = output;
                    } while (output != null);

                    /*
                     *  Doing this without a JSON lib so users doin't
                     *  need to install another package. The JSON
                     *  returned only has one element. Its simple.
                     */
                    var parts = json.split(":");
                    if (parts != null && parts.length > 1)
                        json = parts[1][1:parts[1].length - 2];
                    else {
                        Relay.show_error_window(_("The message returned was not formed correctly."));
                        return 1;
                    }

                    Idle.add( ()=>{
                        MainWindow.paste.show();
                        file_uploaded("http://" + HASTEBIN_HOST + "/" + json);
                        reset_ui();
                        return false;
                    });
                } catch (GLib.Error e) {
                    reset_ui();
                    Relay.show_error_window(e.message);
                    warning("Could not upload " + e.message);
                }
                return 0;
            });
        }
    }


}
