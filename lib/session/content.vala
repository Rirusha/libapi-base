/*
 * Copyright 2024 Vladimir Romanov <rirusha@altlinux.org>
 *
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

[Version (since = "6.0")]
public struct ApiBase.Content {

    public ContentType content_type;
    string content;

    [Version (since = "6.0")]
    public Bytes get_bytes () {
        return new Bytes (content.data);
    }

    [Version (since = "6.0")]
    /**
     * Set content dict
     */
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

    [Version (since = "6.0")]
    /**
     * Set content datalist
     */
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
