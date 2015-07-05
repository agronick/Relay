
/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * message.vala
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
using Gee;

public class Message : GLib.Object {
    public string? message { get; set; }
    public string prefix { get; set; }
    public string command { get; set; }
    public string[] parameters { get; set; }
    public string user_name = "";
    public bool internal = false;
    public bool usr_private_message = false;
    private static Regex? regex;
    private static Regex? fix_message;

    private static string regex_string = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$""";
    private static string replace_string = """[\x00-\x1F\x80-\xFF]""";
    public static string[] user_cmds = {IRC.PRIVATE_MESSAGE, IRC.JOIN_MSG, IRC.USER_NAME_CHANGED, IRC.QUIT_MSG, IRC.PART_MSG};

    public Message (string _message = "") {
        if (regex == null) {
            try {
                regex = new Regex(regex_string, RegexCompileFlags.OPTIMIZE );
                fix_message = new Regex(replace_string, RegexCompileFlags.OPTIMIZE );
            } catch (RegexError e){
                error("There was a regex error that should never happen");
            }
        }
        if (_message.length == 0)
            return;
		try{
    		message = fix_message.replace_literal(_message, _message.length, 0, "");
		}catch(RegexError e) {
			message = _message;
		}
        parse_regex();
    }

    public string get_prefix_name () {
        if (prefix.index_of_char('!') == -1)
            return "";
        if (command == IRC.PRIVATE_MESSAGE)
            usr_private_message = true;
        return prefix.split("!")[0];
    }

    public void user_name_set (string name) { 
        user_name = name;
    }

    //Use this function to add padding to the user name
    public string user_name_get () {
        string name = user_name;
        if (name.length >= IRC.USER_LENGTH) 
            name = user_name.substring(0, IRC.USER_LENGTH - 3) + "...";
        int length = IRC.USER_LENGTH - name.length;
        return name + string.nfill(length, ' ');
    }

    public string get_msg_txt() {
        return (message == null) ? "" : message.strip();
    }

    public void parse_regex () {
        try{
            regex.replace_eval (message, -1, 0, 0, (mi, s) => {
                prefix = mi.fetch_named ("prefix");
                command = mi.fetch_named ("command");
                parameters = mi.fetch_named ("params").split(" ") ;
                message = mi.fetch_named ("trail");

                if(message != null)
                    message = message.replace("\t", "");
                if(command in user_cmds)
                    user_name_set(prefix.split("!")[0]);

                return false;
            });
        }catch (RegexError e){
            warning("Regex error with " + message);
        }
    }
}

