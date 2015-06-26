/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * rich-text.vala
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
 *
 * kyrc is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * kyrc is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gee;

public class RichText : GLib.Object {

    string text;
    
    private static Regex? parse_url;
    private static const string url_string = """(https?|ftp):\/\/[^\s\/$.?#].[^\s]*""";
    public LinkedList<int> link_locations_start;
    public LinkedList<int> link_locations_end;
    
    public RichText (string _text) {
        text = _text;

        if (parse_url == null)
            parse_url = new Regex(url_string, RegexCompileFlags.OPTIMIZE);
    }

    public void parse_links() {
        link_locations_start = new LinkedList<int>();
        link_locations_end = new LinkedList<int>();

        MatchInfo match_info;
        string lookup = text;
        int last_offset = 0;
        
        while(parse_url.match_all(lookup, 0, out match_info)) {
            int start;
            int end;
            match_info.fetch_pos(0, out start, out end);
            link_locations_start.add(text.length - (start + last_offset));
            link_locations_end.add(text.length - (end + last_offset));
            last_offset = end;
            lookup = lookup.substring(end);
            debug("Looking up at " + lookup);
        }
    }

}

