/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * channel_sidebar.vala
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

using Granite;
using Gtk;

public class ChannelSidebar : Granite.Widgets.SourceList.Item {

    public ChannelSidebar (string _name) {
        this.name = _name;
    }

    public new Gtk.Menu? get_context_menu ()  {
        debug("CALLED");
        var menu = new Gtk.Menu();
		Gtk.MenuItem connect = new Gtk.MenuItem.with_label (_("Connect"));
        menu.add(connect);
        return menu;
    }
}

