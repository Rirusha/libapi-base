/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/**
 * Internal representation of a YAML value.
 * Built from parsing events, used for deserialization.
 */
[Version (since = "7.8")]
public class Serialize.YamlValue : GLib.Object {
    public Yaml.NodeType node_type { get; construct; }
    public string? scalar { get; set; }
    public Gee.ArrayList<Serialize.YamlValue> sequence_items { get; set; default = new Gee.ArrayList<Serialize.YamlValue> (); }
    public Gee.ArrayList<Serialize.YamlPair> mapping_pairs { get; set; default = new Gee.ArrayList<Serialize.YamlPair> (); }

    public YamlValue (Yaml.NodeType node_type) {
        Object (node_type: node_type);
    }
}

/**
 * A key-value pair in a YAML mapping.
 */
[Version (since = "7.8")]
public class Serialize.YamlPair : GLib.Object {
    public Serialize.YamlValue key { get; set; }
    public Serialize.YamlValue value { get; set; }

    public YamlPair (Serialize.YamlValue key, Serialize.YamlValue value) {
        Object (key: key, value: value);
    }
}
