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

public class Message : GLib.Object {
	public string message { get; set; } 
	public string prefix { get; set; } 
	public string command { get; set; }
	public string[] parameters { get; set; }
	public string user_name;
	private static Regex? regex = null;

	private static const string regex_string = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$""";

	public Message (string _message) {
		message = _message; 

		if(regex == null) 
		{
			try{
				regex = new Regex(regex_string, RegexCompileFlags.OPTIMIZE );  
			}catch(RegexError e){
				error("There was a regex error that should never happen");
			}
		}
 
		parse_regex();
	}


	public void parse_regex()
	{  
		 regex.replace_eval (message, -1, 0, 0, (mi, s) => {
                prefix = mi.fetch_named ("prefix");
                command = mi.fetch_named ("command");
                parameters = mi.fetch_named ("params").split(" ") ;
                message = mi.fetch_named ("trail"); 
				if(command == "PRIVMSG")
					user_name = prefix.split("!")[0];
                return false;
            });
	} 
 

	/**
	 * DELETE THIS WHEN YOU KNOW YOU DONT NEED IT
	public void parse()
	{
		if (message[0] == ':')
		{
			prefixEnd = message.index_of(" "); 
		//	prefix = message[1, prefixEnd -1];
		}

		trailingStart = message.index_of(" :"); 
		if (trailingStart >= 0)
		{
			trailing = message.substring(trailingStart + 2);
		} else {
		//	trailingStart = message.Length;
		}
		
		commandAndParameters = message.substring(prefixEnd + 1, trailingStart - prefixEnd - 1).split(" ");
		command = commandAndParameters[0];

		if (commandAndParameters.length > 1)
			parameters = commandAndParameters[1:commandAndParameters.length - 1];
	}
*/
		

}
	
	