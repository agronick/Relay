/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * rich_text.vala
 * Copyright (C) 2015 Kyle Agronick <agronick@gmail.com>
     *
 * relay is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
     * 
 * relay is distributed in the hope that it will be useful, but
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
    public LinkedList<int> name_location_start;
    public LinkedList<int> name_location_end;
    public bool has_links = false;
    public bool has_names = false;

    public RichText (string _text) {
        text = _text;

        try{
        if (parse_url == null)
            parse_url = new Regex(url_string, RegexCompileFlags.OPTIMIZE);
        } catch (RegexError e) {}
    }

    public void parse_links () {
        link_locations_start = new LinkedList<int>();
        link_locations_end = new LinkedList<int>();

        MatchInfo match_info;
        string lookup = text;
        int last_offset = 0;

        while (parse_url.match_all (lookup, 0, out match_info)) {
            int start;
            int end;
            match_info.fetch_pos(0, out start, out end);
            link_locations_start.add(text.length - (start + last_offset));
            link_locations_end.add(text.length - (end + last_offset));
            last_offset = end;
            lookup = lookup.substring(end);
            has_links = true;
        }
    }

    public void parse_name (string? name) {
        if (name == null || name.length == 0)
            return;
        name_location_start = new LinkedList<int>();
        name_location_end = new LinkedList<int>();
        int location = text.index_of(name);
        while (location > -1) {
            name_location_start.add(text.length - location - name.length);
            name_location_end.add((text.length - location));
            location += name.length;
            has_names = true;
            location = text.index_of(name, location);
        } 
    }
}

