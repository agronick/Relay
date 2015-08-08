/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main-entry.vala
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
using Gee;
using Gtk;
using Gdk;

public class MainEntry : Entry {

    int last_pos = -1;
    ArrayList<string> history = new ArrayList<string>();
    
    public MainEntry () {
        key_press_event.connect(press_event);
        activate.connect(do_activate);
    }

    public bool press_event (EventKey event) { 
        string? keyval = Gdk.keyval_name(event.keyval);
        switch (keyval) {
            case "Up":
                up_arrow();
                return true;
            break;
            case "Down":
                down_arrow();
            break;
        }
        return false;
    }

    private void up_arrow () {
        if (last_pos == -1)
            last_pos = history.size - 1;
        else if (last_pos == 0)
            return;
        else
            last_pos--;
        
    
        write_history(last_pos);
    }

    private void down_arrow () {
        if (history.size > last_pos + 1)
            last_pos++;
        else {
            set_text("");
            return;
        }

        write_history(last_pos);
    }

    private void write_history (int index) {
        if (index > history.size || index < 0)
            return;
        
        set_text(history[index]);
        set_position(get_text().length);
    }

    public void do_activate () {
        if (get_text().strip() == "")
            return;
        
        history.add(get_text());
        last_pos = -1;
    }
}