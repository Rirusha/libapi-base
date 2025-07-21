/*
 * Copyright 2024 Vladimir Vaskov
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

internal class ApiBase.Headers : Object {

    Gee.ArrayList<Header?> headers = new Gee.ArrayList<Header?> ();

    public void set_headers (Header[] headers) {
        this.headers.clear ();
        this.headers.add_all_array (headers);
    }

    public Header[] get_headers () {
        return headers.to_array ();
    }
}
