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

public sealed class ApiBase.PostContent : Object {

    public PostContentType content_type { get; construct; }
    public string content { get; set; }

    public PostContent (PostContentType content_type) {
        Object (content_type: content_type);
    }

    public Bytes get_bytes () {
        return new Bytes (content.data);
    }

    public void set_dict (Gee.HashMap<string, string> dict) {
        switch (content_type) {
            case X_WWW_FORM_URLENCODED:
                content = Soup.Form.encode_datalist (hashmap_to_datalist<string> (dict));
                break;
            case JSON:
                content = Jsoner.serialize (dict);
                break;
            default:
                assert_not_reached ();
            }
    }

    public void set_datalist (Datalist<string> datalist) {
        switch (content_type) {
            case X_WWW_FORM_URLENCODED:
                content = Soup.Form.encode_datalist (datalist);
                break;
            case JSON:
                content = Jsoner.serialize (datalist_to_hashmap<string> (datalist));
                break;
            default:
                assert_not_reached ();
            }
    }
}
