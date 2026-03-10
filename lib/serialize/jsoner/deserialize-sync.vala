/*
 * Copyright (C) 2025-2026 Vladimir Romanov <rirusha@altlinux.org>
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

namespace Serialize.JsonerDeserializeSync {

    internal void check_node_type (Json.Node node, Json.NodeType node_type) throws JsonError {
        if (node.get_node_type () != node_type) {
            throw new JsonError.WRONG_TYPE ("Wrong node type: expected '%s', got '%s'",
                node_type.to_string (),
                node.get_node_type ().to_string ()
            );
        }
    }

    internal static Dict<Value?> simple_deserialize (
        string json,
        string[]? sub_members,
        Serialize.Settings? settings = null
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, settings);
        return jsoner.deserialize ();
    }

    internal static T simple_from_json<T> (
        string json,
        string[]? sub_members,
        Serialize.Settings? settings = null
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, settings);
        return jsoner.deserialize_object<T> ();
    }

    internal static Array<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, settings);
        return jsoner.deserialize_array<T> (collection_hierarchy);
    }

    internal static Dict<T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, settings);
        return jsoner.deserialize_dict<T> (collection_hierarchy);
    }

    internal Dict<Value?> deserialize (
        Jsoner self
    ) throws JsonError {
        var dict = new Dict<Value?> ();
        deserialize_dict_into (self, dict, {});
        return dict;
    }

    internal T deserialize_object<T> (
        Jsoner self
    ) throws JsonError {
        return deserialize_object_by_type (self, typeof (T));
    }

    internal Object deserialize_object_by_type (
        Jsoner self,
        GLib.Type obj_type,
        Json.Node? node = null
    ) throws JsonError {
        var obj = Object.new (obj_type);
        if (obj_type.is_a (typeof (TypeFamily))) {
            var actual_type = ((TypeFamily)obj).match_type (node ?? self.root);
            debug (
                "Type transition %s -> %s",
                obj_type.name (), actual_type.name ()
            );
            obj = Object.new (actual_type);
        }

        deserialize_object_into (self, obj, node);

        return obj;
    }

    internal void deserialize_object_into (
        Jsoner self,
        Object obj,
        Json.Node? node = null
    ) throws JsonError {
        if (node == null) {
            node = self.root;
        }

        check_node_type (node, Json.NodeType.OBJECT);

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

        if (Environment.get_variable ("API_BASE_UNKNOWN_PROPS") != null) {
            var members = node.get_object ().get_members ();

            var kebabbed_members = new Gee.HashSet<string> ();
            foreach (var member_name in members) {
                kebabbed_members.add (Convert.cany2kebab (member_name, self.settings.names_case));
            }

            foreach (var prop in properties) {
                if (!(prop.name in kebabbed_members)) {
                    warning (
                        "The json object does not have field '%s' that present in '%s' as property",
                        prop.name,
                        obj_type.name ()
                    );
                }
            }
        }

        foreach (var member_name in node.get_object ().get_members ()) {
            var kebabbed_member_name = Convert.cany2kebab (member_name, self.settings.names_case);

            var sub_node = node.get_object ().get_member (member_name);

            if (!props_data.has_key (kebabbed_member_name)) {
                if (Environment.get_variable ("API_BASE_UNKNOWN_FIELDS") != null) {
                    warning (
                        "The object '%s' does not have a property '%s' corresponding to the json field '%s' with type '%s':\n%s",
                        obj_type.name (),
                        kebabbed_member_name,
                        member_name,
                        sub_node.get_node_type ().to_string (),
                        Json.to_string (sub_node, true)
                    );
                }

                unknown_fields.add (member_name);
                continue;
            }

            var property = props_data[kebabbed_member_name];

            Type prop_type = property.value_type;

            switch (sub_node.get_node_type ()) {
                case Json.NodeType.ARRAY:
                    if (prop_type == typeof (string[])) {
                        var jarr = sub_node.get_array ();
                        string[] arr = new string[jarr.get_length ()];
                        jarr.foreach_element ((array, index, element_node) => {
                            arr[index] = element_node.get_string ();
                        });

                        obj.set_property (
                            property.name,
                            arr
                        );

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

                        deserialize_array_into (self, array, carr, sub_node);
                        obj.set_property (
                            property.name,
                            array
                        );

                    } else {
                        warning (
                            "Can't deserialize array '%s' of '%s::%s'",
                            Json.to_string (sub_node, false),
                            obj_type.name (),
                            property.name
                        );
                    }
                    break;

                case Json.NodeType.OBJECT:
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

                        deserialize_dict_into (self, hash_map, carr, sub_node);
                        obj.set_property (
                            property.name,
                            hash_map
                        );
                        break;

                    } else {
                        obj.set_property (
                            property.name,
                            deserialize_object_by_type (self, prop_type, sub_node)
                        );
                    }

                    break;

                case Json.NodeType.VALUE:
                    var jval = deserialize_value (self, sub_node);
                    var pval = Value (prop_type);
                    Convert.value2value (ref jval, ref pval);

                    obj.set_property (property.name, pval);
                    break;

                case Json.NodeType.NULL:
                    obj.set_property (
                        property.name,
                        Value (prop_type)
                    );
                    break;
            }
        }

        if (obj is HasFallback) {
            var fallback_dict = new Dict<Value?> ();
            deserialize_dict_into (self, fallback_dict, {}, node, unknown_fields);
            obj.set_property (HasFallback.FALLBACK_PROPERTY_NAME, fallback_dict);
        }
        obj.thaw_notify ();
    }

    internal Value deserialize_value (
        Jsoner self,
        Json.Node? node = null
    ) throws JsonError {
        if (node == null) {
            node = self.root;
        }

        check_node_type (node, Json.NodeType.VALUE);

        return node.get_value ();
    }

    internal Array<T> deserialize_array<T> (
        Jsoner self,
        CollectionFactory[] collection_hierarchy
    ) throws JsonError {
        var array = new Array<T> ();
        deserialize_array_into (self, array, collection_hierarchy);
        return array;
    }

    internal void deserialize_array_into (
        Jsoner self,
        Array array,
        CollectionFactory[] collection_hierarchy,
        Json.Node? node = null
    ) throws JsonError {
        if (node == null) {
            node = self.root;
        }

        check_node_type (node, Json.NodeType.ARRAY);

        var jarray = node.get_array ();
        array.clear ();

        if (array.element_type == typeof (Array)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Array);

            foreach (var sub_node in jarray.get_elements ()) {
                var arr_obj = (Array) collection_factory.build ();
                try {
                    deserialize_array_into (self, arr_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    array.add_array (arr_obj);
                } catch (JsonError e) {}
            }

        } else if (array.element_type == typeof (Dict)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Dict);

            foreach (var sub_node in jarray.get_elements ()) {
                var dict_obj = (Dict) collection_factory.build ();
                try {
                    deserialize_dict_into (self, dict_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    array.add_dict (dict_obj);
                } catch (JsonError e) {}
            }

        } else if (array.element_type.is_object ()) {
            foreach (var sub_node in jarray.get_elements ()) {
                try {
                    array.add_object (deserialize_object_by_type (self, array.element_type, sub_node));
                } catch (JsonError e) {}
            }

        } else {
            foreach (var sub_node in jarray.get_elements ()) {
                if (array.element_type == typeof (Value?)) {
                    var varray = (Array<Value?>) array;

                    switch (sub_node.get_node_type ()) {
                        case OBJECT:
                            var sub_dict = new Dict<Value?> ();
                            deserialize_dict_into (self, sub_dict, {}, sub_node);
                            var dict_val = Value (typeof (Dict));
                            dict_val.set_object (sub_dict);
                            varray.add (dict_val);
                            break;

                        case ARRAY:
                            var sub_array = new Array<Value?> ();
                            deserialize_array_into (self, sub_array, {}, sub_node);
                            var dict_val = Value (typeof (Array));
                            dict_val.set_object (sub_array);
                            varray.add (dict_val);
                            break;

                        case VALUE:
                            varray.add (deserialize_value (self, sub_node));
                            break;

                        case NULL:
                            varray.add (null);
                            break;
                    }

                } else {
                    array.add_base (deserialize_value (self, sub_node));
                }
            }
        }
    }

    internal Dict<T> deserialize_dict<T> (
        Jsoner self,
        CollectionFactory[] collection_hierarchy
    ) throws JsonError {
        var dict = new Dict<T> ();
        deserialize_dict_into (self, dict, collection_hierarchy);
        return dict;
    }

    internal void deserialize_dict_into (
        Jsoner self,
        Dict dict,
        CollectionFactory[] collection_hierarchy,
        Json.Node? node = null,
        Array<string>? fallback_whitelist = null
    ) throws JsonError {
        if (node == null) {
            node = self.root;
        }

        check_node_type (node, Json.NodeType.OBJECT);

        dict.clear ();
        var jobject = node.get_object ();

        if (dict.value_type == typeof (Array)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Array);

            foreach (var member_name in jobject.get_members ()) {
                var arr_obj = (Array) collection_factory.build ();
                var sub_node = jobject.get_member (member_name);

                try {
                    deserialize_array_into (self, arr_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    dict.set_array (member_name, arr_obj);
                } catch (JsonError e) {}
            }

        } else if (dict.value_type == typeof (Dict)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is Dict);

            foreach (var member_name in jobject.get_members ()) {
                var dict_obj = (Dict) collection_factory.build ();
                var sub_node = jobject.get_member (member_name);

                try {
                    deserialize_dict_into (self, dict_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    dict.set_dict (member_name, dict_obj);
                } catch (JsonError e) {}
            }

        } else if (dict.value_type.is_object ()) {
            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);

                try {
                    dict.set_object (member_name, deserialize_object_by_type (
                        self,
                        dict.value_type,
                        sub_node
                    ));
                } catch (JsonError e) {}
            }

        } else {
            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);

                if (dict.value_type == typeof (Value?)) {
                    if (fallback_whitelist != null) {
                        if (!(member_name in fallback_whitelist)) {
                            continue;
                        }
                    }
                    var vdict = (Dict<Value?>) dict;

                    switch (sub_node.get_node_type ()) {
                        case OBJECT:
                            var sub_dict = new Dict<Value?> ();
                            deserialize_dict_into (self, sub_dict, {}, sub_node);
                            var dict_val = Value (typeof (Dict));
                            dict_val.set_object (sub_dict);
                            vdict.set (member_name, dict_val);
                            break;

                        case ARRAY:
                            var sub_array = new Array<Value?> ();
                            deserialize_array_into (self, sub_array, {}, sub_node);
                            var dict_val = Value (typeof (Array));
                            dict_val.set_object (sub_array);
                            vdict.set (member_name, dict_val);
                            break;

                        case VALUE:
                            vdict.set (member_name, deserialize_value (self, sub_node));
                            break;

                        case NULL:
                            vdict.set (member_name, null);
                            break;
                    }

                } else {
                    dict.set_base (member_name, deserialize_value (self, sub_node));
                }
            }
        }
    }
}
