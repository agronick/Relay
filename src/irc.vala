/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * irc-const.vala
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

public class IRC{
	public const uint16 DEFAULT_PORT = 6667;
	public const int USER_LENGTH = 18;
	public const int USER_WIDTH = 126;
	public const string user_prefixes = "~&@%+";

	//Replies
	public const string RPL_WELCOME = "001";
	public const string RPL_YOURHOST = "002";
	public const string RPL_CREATED = "003";
	public const string RPL_MYINFO = "004";
	public const string RPL_BOUNCE = "005";
	public const string RPL_AWAY = "301";
	public const string RPL_UNAWAY = "305";
	public const string RPL_NOWAWAY = "306";
	public const string RPL_WHOISUSER = "311";
	public const string RPL_WHOISSERVER = "312";
	public const string RPL_WHOISOPERATOR = "313";
	public const string RPL_WHOISCHANNELS = "319";
	public const string RPL_WHOISIDLE = "317";
	public const string RPL_ENDOFWHOIS = "318";
	public const string RPL_LIST = "322";
	public const string RPL_LISTEND = "323";
	public const string RPL_CHANNELMODEIS = "324";
	public const string RPL_AUTHEDAS = "330";
	public const string RPL_NOTOPIC = "331";
	public const string RPL_TOPIC = "332";
	public const string RPL_VERSION = "351";
	public const string RPL_NAMREPLY = "353";
	public const string RPL_ENDOFNAMES = "366";
	public const string RPL_MOTD = "372";
	public const string RPL_MOTDSTART = "375";
	public const string RPL_ENDOFMOTD = "376";
    public const string RPL_LUSEROP = "252";
             // "<integer> :operator(s) online"
    public const string RPL_LUSERUNKNOWN = "253";
             //"<integer> :unknown connection(s)"
    public const string RPL_LUSERCHANNELS = "254";
             //"<integer> :channels formed"
    public const string RPL_LUSERME = "255";
             //":I have <integer> clients and <integer> servers"
	public const string RPL_LUSERCLIENT = "251";
			//:There are <integer> users and <integer> services on <integer> servers"
	public const string PRIVATE_MESSAGE = "PRIVMSG";

	//Errors
	public const string ERR_NOSUCHNICK = "401";
	public const string ERR_NOSUCHCHANNEL = "403";
	public const string ERR_WASNOSUCHNICK = "406";
	public const string ERR_UNKNOWNCOMMAND = "421";
	public const string ERR_NOMOTD = "422";
	public const string ERR_NONICKNAMEGIVEN = "431";
	public const string ERR_NICKNAMEINUSE = "433";
	public const string ERR_USERNOTINCHANNEL = "441";
	public const string ERR_NOTONCHANNEL = "442";
	public const string ERR_NOTREGISTERED = "451"; //
	public const string ERR_NEEDMOREPARAMS = "461"; //
	public const string ERR_UNKNOWNMODE = "472";
	public const string ERR_ALREADYONCHANNEL = "479";
	public const string ERR_CHANOPRIVSNEEDED = "482";

	public static int compare(string a, string b) {
		return GLib.strcmp(a, b);                                                                                                                                                                                                                                                                                                                                                       
	}

	public static string remove_user_prefix (string name) {
		if(user_prefixes.index_of_char(name[0]) != -1)
			return name.substring(1);
		return name;
	}
}

