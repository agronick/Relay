/***
  Copyright (C) 2011-2012 Application Name Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see
***/

using GLib;

public class Message : GLib.Object {
    public string? message { get; set; }
    public string prefix { get; set; }
    public string command { get; set; }
    public string[] parameters { get; set; }
    public string user_name = "";
    public bool internal = false;
    private static Regex? regex = null;
    private static Regex? fix_message = null;

    private static const string regex_string = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$""";
    private static const string replace_string = """\\00[0-9]""";
    
    public Message (string _message = "") {
        if (message == "")
            return;
        if (regex == null) {
            try{
                regex = new Regex(regex_string, RegexCompileFlags.OPTIMIZE );
                fix_message = new Regex(replace_string, RegexCompileFlags.OPTIMIZE );
            }catch(RegexError e){
                error("There was a regex error that should never happen");
            }
        }
        
        
        message = _message.escape("\b\f\n\r\t\\");
        message = fix_message.replace_literal(message, message.length, 0, "");

        parse_regex();
    }

    public void user_name_set (string name) {
        int length = 14 - name.length;
        user_name = name + string.nfill(length, ' ');
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
                
                if(command == "PRIVMSG")
                    user_name_set(prefix.split("!")[0]);
                
                return false;
            });
        }catch (RegexError e){
            warning("Regex error with " + message);
        }
    }




}

