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

using Gee;

namespace Serialize.JsonerDeserializeSync {

    internal static T simple_from_json<T> (
        string json,
        string[]? sub_members,
        Case names_case
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        return jsoner.deserialize_object<T> ();
    }

    internal static ArrayList<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        return jsoner.deserialize_array<T> (collection_hierarchy);
    }

    internal static HashMap<string, T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        return jsoner.deserialize_dict<T> (collection_hierarchy);
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

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.OBJECT.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new JsonError.WRONG_TYPE ("Node isn't object");
        }

        obj.freeze_notify ();

        var obj_type = obj.get_type ();
        var class_ref = (ObjectClass) obj_type.class_ref ();
        ParamSpec[] properties = class_ref.list_properties ();

        var props_data = new Gee.HashMap<string, ParamSpec> ();
        foreach (ParamSpec property in properties) {
            if ((property.flags & ParamFlags.WRITABLE) == 0) {
                continue;
            }

            var prop_name = property.get_nick ();

            if (props_data.has_key (prop_name)) {
                warning ("Detected property collision: %s", prop_name);
            }
            props_data[prop_name] = property;
        }

        foreach (var member_name in node.get_object ().get_members ()) {
            var kebabbed_member_name = Convert.cany2kebab (member_name, self.names_case);

            if (!props_data.has_key (kebabbed_member_name)) {
                var unknown_fields = Environment.get_variable ("API_BASE_UNKNOWN_FIELDS");
                if (unknown_fields != null) {
                    warning (
                        "The object '%s' does not have a property '%s' corresponding to the json field '%s'",
                        obj_type.name (),
                        kebabbed_member_name,
                        member_name
                    );
                }
                continue;
            }

            var property = props_data[kebabbed_member_name];

            Type prop_type = property.value_type;

            var sub_node = node.get_object ().get_member (member_name);

            switch (sub_node.get_node_type ()) {
                case Json.NodeType.ARRAY:
                    var arrayval = Value (prop_type);
                    obj.get_property (property.name, ref arrayval);
                    ArrayList array_list = (Gee.ArrayList) arrayval.get_object ();

                    CollectionFactory[] carr = {};
                    var data_obj = obj as DataObject;
                    if (data_obj != null) {
                        carr = data_obj.collection_factories (property.name);
                    }

                    assert (array_list != null || carr.length != 0);

                    if (carr.length != 0) {
                        assert (carr[0] is ArrayFactory);
                        array_list = (ArrayList) carr[0].build ();
                    }

                    carr = carr[1:carr.length];

                    deserialize_array_into (self, array_list, carr, sub_node);
                    obj.set_property (
                        property.name,
                        array_list
                    );
                    break;

                case Json.NodeType.OBJECT:
                    if (prop_type.is_a (typeof (HashMap))) {
                        var dictval = Value (prop_type);
                        obj.get_property (property.name, ref dictval);
                        HashMap hash_map = (HashMap) dictval.get_object ();

                        CollectionFactory[] carr = {};
                        var data_obj = obj as DataObject;
                        if (data_obj != null) {
                            carr = data_obj.collection_factories (property.name);
                        }

                        assert (hash_map != null || carr.length != 0);

                        if (carr.length != 0) {
                            assert (carr[0] is DictFactory);
                            hash_map = (HashMap) carr[0].build ();
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
                    var val = deserialize_value (self, sub_node);
                    if (prop_type.is_enum ()) {
                        if (val.type () == Type.INT64) {
                            obj.set_property (
                                property.name,
                                val.get_int64 ()
                            );

                        } else if (val.type () == Type.STRING) {
                            var strval = val.get_string ();
                            if (strval != null) {
                                obj.set_property (
                                    property.name,
                                    Enum.get_by_nick_gtype (prop_type, val.get_string ())
                                );
                            }

                        } else {
                            warning ("Property has enum type, but json doesn'y hold int64 or string type");
                        }

                    } else {
                        var new_val = Value (prop_type);
                        if (!val.transform (ref new_val)) {
                            warning (
                                "Failed to transform %s to %s of %s::%s",
                                val.type_name (),
                                prop_type.name (),
                                obj_type.name (),
                                property.name
                            );
                        }
                        obj.set_property (
                            property.name,
                            new_val
                        );
                    }
                    break;

                case Json.NodeType.NULL:
                    obj.set_property (
                        property.name,
                        Value (prop_type)
                    );
                    break;
            }
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

        if (node.get_node_type () != Json.NodeType.VALUE) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.VALUE.to_string (),
                node.get_node_type ().to_string ()
            );

            throw new JsonError.WRONG_TYPE ("Node isn't value");
        }

        return node.get_value ();
    }

    internal ArrayList<T> deserialize_array<T> (
        Jsoner self,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        var array_list = new ArrayList<T> ();
        deserialize_array_into (self, array_list, collection_hierarchy);
        return array_list;
    }

    internal void deserialize_array_into (
        Jsoner self,
        ArrayList array_list,
        CollectionFactory[] collection_hierarchy = {},
        Json.Node? node = null
    ) throws JsonError {
        if (node == null) {
            node = self.root;
        }

        if (node.get_node_type () != Json.NodeType.ARRAY) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.ARRAY.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new JsonError.WRONG_TYPE ("Node isn't array");
        }

        var jarray = node.get_array ();

        if (array_list.element_type == typeof (ArrayList)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is ArrayFactory);

            foreach (var sub_node in jarray.get_elements ()) {
                var arr_obj = (ArrayList) collection_factory.build ();
                try {
                    deserialize_array_into (self, arr_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    ((ArrayList<ArrayList>) array_list).add (arr_obj);
                } catch (JsonError e) {}
            }

        } else if (array_list.element_type == typeof (HashMap)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is DictFactory);

            foreach (var sub_node in jarray.get_elements ()) {
                var dict_obj = (HashMap) collection_factory.build ();
                try {
                    deserialize_dict_into (self, dict_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    ((ArrayList<HashMap>) array_list).add (dict_obj);
                } catch (JsonError e) {}
            }

        } else if (array_list.element_type.is_object ()) {
            array_list.clear ();
            var narray_list = array_list as ArrayList<Object>;

            foreach (var sub_node in jarray.get_elements ()) {
                try {
                    narray_list.add (deserialize_object_by_type (self, narray_list.element_type, sub_node));
                } catch (JsonError e) {}
            }

        } else {
            array_list.clear ();

            foreach (var sub_node in jarray.get_elements ()) {
                var dval = deserialize_value (self, sub_node);
                var new_val = Value (array_list.element_type);
                dval.transform (ref new_val);

                switch (array_list.element_type) {
                    case Type.STRING:
                        ((ArrayList<string>) array_list).add (new_val.get_string ());
                        break;

                    case Type.INT:
                        ((ArrayList<int>) array_list).add (new_val.get_int ());
                        break;

                    case Type.INT64:
                        ((ArrayList<int64?>) array_list).add (new_val.get_int64 ());
                        break;

                    case Type.DOUBLE:
                        ((ArrayList<double?>) array_list).add (new_val.get_double ());
                        break;

                    case Type.BOOLEAN:
                        ((ArrayList<bool>) array_list).add (new_val.get_boolean ());
                        break;

                    default:
                        warning ("Unknown type of element of array - %s",
                            array_list.element_type.name ()
                        );
                        break;
                }
            }
        }
    }

    internal HashMap<string, T> deserialize_dict<T> (
        Jsoner self,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        var dict = new HashMap<string, T> ();
        deserialize_dict_into (self, dict, collection_hierarchy);
        return dict;
    }

    internal void deserialize_dict_into (
        Jsoner self,
        HashMap dict,
        CollectionFactory[] collection_hierarchy = {},
        Json.Node? node = null
    ) throws JsonError {
        if (node == null) {
            node = self.root;
        }

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.OBJECT.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new JsonError.WRONG_TYPE ("Node isn't object");
        }

        if (dict.key_type != Type.STRING) {
            error ("HashMap can only have string as key type");
        }

        dict.clear ();
        var jobject = node.get_object ();

        if (dict.value_type == typeof (ArrayList)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is ArrayFactory);

            foreach (var member_name in jobject.get_members ()) {
                var arr_obj = (ArrayList) collection_factory.build ();
                var sub_node = jobject.get_member (member_name);

                try {
                    deserialize_array_into (self, arr_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    ((HashMap<string, ArrayList>) dict)[member_name] = arr_obj;
                } catch (JsonError e) {}
            }

        } else if (dict.value_type == typeof (HashMap)) {
            var collection_factory = collection_hierarchy[0];

            assert (collection_factory is DictFactory);

            foreach (var member_name in jobject.get_members ()) {
                var dict_obj = (HashMap) collection_factory.build ();
                var sub_node = jobject.get_member (member_name);

                try {
                    deserialize_dict_into (self, dict_obj, collection_hierarchy[1:collection_hierarchy.length], sub_node);

                    ((HashMap<string, HashMap>) dict)[member_name] = dict_obj;
                } catch (JsonError e) {}
            }

        } else if (dict.value_type.is_object ()) {
            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);

                try {
                    ((HashMap<string, Object>) dict)[member_name] = deserialize_object_by_type (
                        self,
                        dict.value_type,
                        sub_node
                    );
                } catch (JsonError e) {}
            }

        } else {
            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);
                var dval = deserialize_value (self, sub_node);
                var new_val = Value (dict.value_type);
                dval.transform (ref new_val);

                switch (dict.value_type) {
                    case Type.STRING:
                        ((HashMap<string, string>) dict)[member_name] = new_val.get_string ();
                        break;

                    case Type.INT:
                        ((HashMap<string, int>) dict)[member_name] = new_val.get_int ();
                        break;

                    case Type.INT64:
                        ((HashMap<string, int64?>) dict)[member_name] = new_val.get_int64 ();
                        break;

                    case Type.DOUBLE:
                        ((HashMap<string, double?>) dict)[member_name] = new_val.get_double ();
                        break;

                    case Type.BOOLEAN:
                        ((HashMap<string, bool>) dict)[member_name] = new_val.get_boolean ();
                        break;

                    default:
                        warning ("Unknown type of element of hashmap - %s",
                            dict.value_type.name ()
                        );
                        break;
                }
            }
        }
    }
}
