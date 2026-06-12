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

namespace Serialize.YamlDeserializeSync {

    void check_node_type (Serialize.YamlValue node, Yaml.NodeType node_type) throws Serialize.Error {
        if (node.node_type != node_type) {
            throw new Serialize.Error.WRONG_TYPE ("Wrong node type: expected '%s', got '%s'",
                node_type.to_string (),
                node.node_type.to_string ()
            );
        }
    }

    Object deserialize_object_by_type (
        YamlWorker self,
        GLib.Type obj_type,
        Serialize.YamlValue? node = null
    ) throws Serialize.Error {
        var obj = Object.new (obj_type);
        if (obj_type.is_a (typeof (YamlTypeFamily))) {
            var type_family = (YamlTypeFamily) obj;
            Serialize.YamlValue? use_node = node;
            if (use_node == null) {
                use_node = self.get_root_value ();
            }
            if (use_node != null) {
                var resolved_type = type_family.match_type_yaml (use_node);
                if (resolved_type != obj_type) {
                    return deserialize_object_by_type (self, resolved_type, use_node);
                }
            }
        }

        deserialize_object_into (self, obj, node);

        return obj;
    }

    void deserialize_object_into (
        YamlWorker self,
        Object obj,
        Serialize.YamlValue? node = null
    ) throws Serialize.Error {
        Serialize.YamlValue? use_node = node;
        if (use_node == null) {
            use_node = self.get_root_value ();
        }

        if (use_node == null) {
            throw new Serialize.Error.EMPTY ("Yaml document has no root node");
        }

        check_node_type (use_node, Yaml.NodeType.MAPPING);

        obj.freeze_notify ();

        var obj_type = obj.get_type ();
        var class_ref = (ObjectClass) obj_type.class_ref ();
        ParamSpec[] properties = class_ref.list_properties ();

        var props_data = new Dict<ParamSpec> ();
        foreach (ParamSpec property in properties) {
            if ((property.flags & ParamFlags.WRITABLE) == 0) {
                continue;
            }

            var prop_name = property.get_nick ();

            if (props_data.has_key (prop_name)) {
                warning ("Detected property collision: %s in '%s' object", prop_name, obj_type.name ());
            }
            props_data[prop_name] = property;
        }

        var unknown_fields = new Array<string> ();

        //  Collect member names from YAML mapping
        var member_names = new Array<string> ();
        var member_values = new Gee.HashMap<string, Serialize.YamlValue> ();

        foreach (var pair in use_node.mapping_pairs) {
            if (pair.key.node_type == Yaml.NodeType.SCALAR) {
                var member_name = pair.key.scalar;
                member_names.add (member_name);
                if (pair.value != null) {
                    member_values[member_name] = pair.value;
                }
            }
        }

        if (Environment.get_variable ("SERIALIZE_UNKNOWN_PROPS") != null) {
            var kebabbed_members = new Gee.HashSet<string> ();
            foreach (var member_name in member_names) {
                kebabbed_members.add (Convert.cany2kebab (member_name, self.settings.names_case));
            }

            foreach (var prop_name in props_data.keys) {
                if (!(prop_name in kebabbed_members) && prop_name != HasFallback.FALLBACK_PROPERTY_NAME) {
                    warning (
                        "The yaml object does not have field '%s' that present in '%s' as property",
                        prop_name,
                        obj_type.name ()
                    );
                }
            }
        }

        foreach (var member_name in member_names) {
            var kebabbed_member_name = Convert.cany2kebab (member_name, self.settings.names_case);

            if (!props_data.has_key (kebabbed_member_name)) {
                if (Environment.get_variable ("SERIALIZE_UNKNOWN_FIELDS") != null) {
                    warning (
                        "The object '%s' does not have a property '%s' corresponding to the yaml field '%s'",
                        obj_type.name (),
                        kebabbed_member_name,
                        member_name
                    );
                }

                unknown_fields.add (member_name);
                continue;
            }

            var property = props_data[kebabbed_member_name];
            var value_node = member_values[member_name];

            if (value_node == null) {
                continue;
            }

            Type prop_type = property.value_type;

            switch (value_node.node_type) {
                case Yaml.NodeType.SEQUENCE:
                    if (prop_type == typeof (string[])) {
                        var strv = new Gee.ArrayList<string> ();

                        foreach (var item in value_node.sequence_items) {
                            if (item.node_type == Yaml.NodeType.SCALAR) {
                                strv.add (item.scalar);
                            }
                        }

                        var result = new string[strv.size];
                        int idx = 0;
                        foreach (var s in strv) {
                            result[idx++] = s;
                        }
                        obj.set_property (property.name, result);

                    } else if (prop_type == typeof (Array)) {
                        var array_val = Value (prop_type);
                        obj.get_property (property.name, ref array_val);
                        Array array = (Array) array_val.get_object ();

                        CollectionFactory[] carr = {};
                        var complex_col_obj = obj as HasComplexCollections;
                        if (complex_col_obj != null) {
                            carr = complex_col_obj.collection_factories (property.name);
                        }

                        assert (array != null || carr.length != 0);

                        if (carr.length != 0) {
                            assert (carr[0] is Array);
                            array = (Array) carr[0].build ();
                        }

                        carr = carr[1:carr.length];

                        deserialize_array_into (self, array, carr, value_node);
                        obj.set_property (
                            property.name,
                            array
                        );

                    } else {
                        warning (
                            "Can't deserialize sequence '%s' of '%s::%s'",
                            "yaml",
                            obj_type.name (),
                            property.name
                        );
                    }
                    break;

                case Yaml.NodeType.MAPPING:
                    if (prop_type.is_a (typeof (Dict))) {
                        var dictval = Value (prop_type);
                        obj.get_property (property.name, ref dictval);
                        Dict hash_map = (Dict) dictval.get_object ();

                        CollectionFactory[] carr = {};
                        var complex_col_obj = obj as HasComplexCollections;
                        if (complex_col_obj != null) {
                            carr = complex_col_obj.collection_factories (property.name);
                        }

                        assert (hash_map != null || carr.length != 0);

                        if (carr.length != 0) {
                            assert (carr[0] is Dict);
                            hash_map = (Dict) carr[0].build ();
                        }

                        carr = carr[1:carr.length];

                        deserialize_dict_into (self, hash_map, carr, value_node);
                        obj.set_property (
                            property.name,
                            hash_map
                        );
                        break;

                    } else {
                        obj.set_property (
                            property.name,
                            deserialize_object_by_type (self, prop_type, value_node)
                        );
                    }

                    break;

                case Yaml.NodeType.SCALAR:
                    if (prop_type.is_enum ()) {
                        var val = Value (prop_type);
                        deserialize_scalar_value (self, value_node, ref val);
                        obj.set_property (property.name, val);
                    } else {
                        var jval = deserialize_value (self, value_node);
                        var pval = Value (prop_type);
                        Convert.value2value (ref jval, ref pval);

                        obj.set_property (property.name, pval);
                    }
                    break;

                case Yaml.NodeType.NO:
                    obj.set_property (
                        property.name,
                        Value (prop_type)
                    );
                    break;
            }
        }

        if (obj is HasFallback) {
            var fallback_dict = new Dict<Value?> ();
            deserialize_dict_into (self, fallback_dict, {}, use_node, unknown_fields);
            obj.set_property (HasFallback.FALLBACK_PROPERTY_NAME, fallback_dict);
        }
        obj.thaw_notify ();
    }

    Value deserialize_value (
        YamlWorker self,
        Serialize.YamlValue? node = null
    ) throws Serialize.Error {
        Serialize.YamlValue? use_node = node;
        if (use_node == null) {
            use_node = self.get_root_value ();
        }

        if (use_node == null) {
            throw new Serialize.Error.EMPTY ("Yaml document has no root node");
        }

        check_node_type (use_node, Yaml.NodeType.SCALAR);

        var val = Value (typeof (string));
        deserialize_scalar_value (self, use_node, ref val);
        return val;
    }

    void deserialize_scalar_value (
        YamlWorker self,
        Serialize.YamlValue node,
        ref Value prop_val
    ) throws Serialize.Error {
        var value = node.scalar;

        switch (prop_val.type ()) {
            case Type.INT:
                prop_val.set_int ((int) int64.parse (value));
                break;

            case Type.INT64:
                prop_val.set_int64 (int64.parse (value));
                break;

            case Type.DOUBLE:
                prop_val.set_double (double.parse (value));
                break;

            case Type.STRING:
                prop_val.set_string (value);
                break;

            case Type.BOOLEAN:
                prop_val.set_boolean (value == "true" || value == "yes" || value == "on");
                break;

            case Type.NONE:
                break;

            default:
                var val_type = prop_val.type ();

                if (val_type.is_enum ()) {
                    int64 res;
                    if (int64.try_parse (value, out res)) {
                        prop_val.set_enum ((int) res);
                    } else {
                        prop_val.set_enum (
                            Enum.get_by_nick_gtype (val_type, value.down ())
                        );
                    }

                } else if (val_type == typeof (DateTime)) {
                    var dt = new DateTime.from_iso8601 (value, new TimeZone.utc ());
                    if (dt != null) {
                        prop_val.set_boxed (dt);
                    } else {
                        int64 res;
                        if (int64.try_parse (value, out res)) {
                            dt = new DateTime.from_unix_utc (res);
                            if (dt != null) {
                                prop_val.set_boxed (dt);
                            }
                        }
                    }

                } else {
                    warning ("Unknown type for deserialize - %s", val_type.name ());
                }

                break;
        }
    }

    void deserialize_array_into (
        YamlWorker self,
        Array array,
        CollectionFactory[] collection_hierarchy,
        Serialize.YamlValue? node = null
    ) throws Serialize.Error {
        Serialize.YamlValue? use_node = node;
        if (use_node == null) {
            use_node = self.get_root_value ();
        }

        if (use_node == null) {
            throw new Serialize.Error.EMPTY ("Yaml document has no root node");
        }

        if (self._deserialize_visited.contains (use_node)) {
            throw new Serialize.Error.INVALID ("Circular reference detected in YAML");
        }

        self._deserialize_visited.add (use_node);

        check_node_type (use_node, Yaml.NodeType.SEQUENCE);

        array.clear ();

        if (array.element_type == typeof (Array)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Array);

            foreach (var sub_node in use_node.sequence_items) {
                var arr_obj = (Array) collection_factory.build ();
                try {
                    deserialize_array_into (
                        self,
                        arr_obj,
                        collection_hierarchy[1:collection_hierarchy.length],
                        sub_node
                    );

                    array.add_array (arr_obj);
                } catch (Serialize.Error e) {}
            }

        } else if (array.element_type == typeof (Dict)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Dict);

            foreach (var sub_node in use_node.sequence_items) {
                var dict_obj = (Dict) collection_factory.build ();
                try {
                    deserialize_dict_into (
                        self,
                        dict_obj,
                        collection_hierarchy[1:collection_hierarchy.length],
                        sub_node
                    );

                    array.add_dict (dict_obj);
                } catch (Serialize.Error e) {}
            }

        } else if (array.element_type.is_object ()) {
            foreach (var sub_node in use_node.sequence_items) {
                try {
                    array.add_object (deserialize_object_by_type (self, array.element_type, sub_node));
                } catch (Serialize.Error e) {}
            }

        } else {
            foreach (var sub_node in use_node.sequence_items) {
                if (array.element_type == typeof (Value?)) {
                    var varray = (Array<Value?>) array;

                    switch (sub_node.node_type) {
                        case Yaml.NodeType.MAPPING:
                            var sub_dict = new Dict<Value?> ();
                            deserialize_dict_into (self, sub_dict, {}, sub_node);
                            var dict_val = Value (typeof (Dict));
                            dict_val.set_object (sub_dict);
                            varray.add (dict_val);
                            break;

                        case Yaml.NodeType.SEQUENCE:
                            var sub_array = new Array<Value?> ();
                            deserialize_array_into (self, sub_array, {}, sub_node);
                            var arr_val = Value (typeof (Array));
                            arr_val.set_object (sub_array);
                            varray.add (arr_val);
                            break;

                        case Yaml.NodeType.SCALAR:
                            var val = Value (typeof (string));
                            deserialize_scalar_value (self, sub_node, ref val);
                            varray.add (val);
                            break;

                        case Yaml.NodeType.NO:
                            varray.add (null);
                            break;
                    }

                } else {
                    var val = Value (array.element_type);
                    deserialize_scalar_value (self, sub_node, ref val);
                    array.add_base (val);
                }
            }
        }

        self._deserialize_visited.remove (use_node);
    }

    void deserialize_dict_into (
        YamlWorker self,
        Dict dict,
        CollectionFactory[] collection_hierarchy,
        Serialize.YamlValue? node = null,
        Array<string>? fallback_whitelist = null
    ) throws Serialize.Error {
        Serialize.YamlValue? use_node = node;
        if (use_node == null) {
            use_node = self.get_root_value ();
        }

        if (use_node == null) {
            throw new Serialize.Error.EMPTY ("Yaml document has no root node");
        }

        if (self._deserialize_visited.contains (use_node)) {
            throw new Serialize.Error.INVALID ("Circular reference detected in YAML");
        }

        self._deserialize_visited.add (use_node);

        check_node_type (use_node, Yaml.NodeType.MAPPING);

        dict.clear ();

        if (dict.value_type == typeof (Array)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Array);

            foreach (var pair in use_node.mapping_pairs) {
                if (pair.key.node_type != Yaml.NodeType.SCALAR) {
                    continue;
                }
                var member_name = pair.key.scalar;
                var arr_obj = (Array) collection_factory.build ();
                var sub_node = pair.value;

                try {
                    deserialize_array_into (
                        self,
                        arr_obj,
                        collection_hierarchy[1:collection_hierarchy.length],
                        sub_node
                    );

                    dict.set_array (member_name, arr_obj);
                } catch (Serialize.Error e) {}
            }

        } else if (dict.value_type == typeof (Dict)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Dict);

            foreach (var pair in use_node.mapping_pairs) {
                if (pair.key.node_type != Yaml.NodeType.SCALAR) {
                    continue;
                }
                var member_name = pair.key.scalar;
                var dict_obj = (Dict) collection_factory.build ();
                var sub_node = pair.value;

                try {
                    deserialize_dict_into (
                        self,
                        dict_obj,
                        collection_hierarchy[1:collection_hierarchy.length],
                        sub_node
                    );

                    dict.set_dict (member_name, dict_obj);
                } catch (Serialize.Error e) {}
            }

        } else if (dict.value_type.is_object ()) {
            foreach (var pair in use_node.mapping_pairs) {
                if (pair.key.node_type != Yaml.NodeType.SCALAR) {
                    continue;
                }
                var member_name = pair.key.scalar;
                var sub_node = pair.value;

                try {
                    dict.set_object (member_name, deserialize_object_by_type (
                        self,
                        dict.value_type,
                        sub_node
                    ));
                } catch (Serialize.Error e) {}
            }

        } else {
            foreach (var pair in use_node.mapping_pairs) {
                if (pair.key.node_type != Yaml.NodeType.SCALAR) {
                    continue;
                }
                var member_name = pair.key.scalar;
                var sub_node = pair.value;

                if (dict.value_type == typeof (Value?)) {
                    if (fallback_whitelist != null) {
                        if (!(member_name in fallback_whitelist)) {
                            continue;
                        }
                    }
                    var vdict = (Dict<Value?>) dict;

                    switch (sub_node.node_type) {
                        case Yaml.NodeType.MAPPING:
                            var sub_dict = new Dict<Value?> ();
                            deserialize_dict_into (self, sub_dict, {}, sub_node);
                            var dict_val = Value (typeof (Dict));
                            dict_val.set_object (sub_dict);
                            vdict.set (member_name, dict_val);
                            break;

                        case Yaml.NodeType.SEQUENCE:
                            var sub_array = new Array<Value?> ();
                            deserialize_array_into (self, sub_array, {}, sub_node);
                            var arr_val = Value (typeof (Array));
                            arr_val.set_object (sub_array);
                            vdict.set (member_name, arr_val);
                            break;

                        case Yaml.NodeType.SCALAR:
                            var val = Value (typeof (string));
                            deserialize_scalar_value (self, sub_node, ref val);
                            vdict.set (member_name, val);
                            break;

                        case Yaml.NodeType.NO:
                            vdict.set (member_name, null);
                            break;
                    }

            } else {
                var val = Value (dict.value_type);
                deserialize_scalar_value (self, sub_node, ref val);
                dict.set_base (member_name, val);
            }
        }
    }

    self._deserialize_visited.remove (use_node);
}
}
