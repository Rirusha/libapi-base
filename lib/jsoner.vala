/*
 * Copyright (C) 2024 Vladimir Vaskov
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

/**
 * @since 0.1.0
 */
public class ApiBase.Jsoner : Object {

    public Case names_case { get; construct; }

    public Json.Node root { get; construct; }

    /**
     * Performs initialization for deserialization. Accepts a json string. In case of
     * a parsing error, it throws {@link CommonError.PARSE_JSON}
     *
     * @param json_string   Correct json string
     * @param sub_members   An array of names of json elements that need to be traversed
     *                      to the target node
     * @param names_case    Name case of element names in a json string
     */
    public Jsoner (
        string json_string,
        string[]? sub_members = null,
        Case names_case = Case.KEBAB
    ) throws CommonError {
        if (json_string.length < 1) {
            throw new CommonError.PARSE_JSON ("Json string is empty");
        }

        Json.Node? node;
        try {
            node = Json.from_string (json_string);

        } catch (GLib.Error e) {
            throw new CommonError.PARSE_JSON ("'%s' is not correct json string".printf (json_string));
        }

        if (node == null) {
            throw new CommonError.PARSE_JSON ("Json string is empty");
        }

        if (sub_members != null) {
            node = steps (node, sub_members);
        }

        debug (
            "Jsoner work with:\n%s",
            json_string
        );

        Object (root : node, names_case : names_case);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the
     * form of bytes, the object {@link GLib.Bytes}. In case of a parsing error,
     * it throws {@link CommonError.PARSE_JSON}
     *
     * @param bytes         Json string in the form of bytes, the object {@link GLib.Bytes}
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param names_case    Name case of element names in a json string
     */
    public Jsoner.from_bytes (
        Bytes bytes,
        string[]? sub_members = null,
        Case names_case = Case.KEBAB
    ) throws CommonError {
        if (bytes.length == 0) {
            throw new CommonError.PARSE_JSON ("Json string is empty");
        }

        this.from_data (bytes.get_data (), sub_members, names_case);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the form of bytes,
     * an {@link uint8} array. In case of a parsing error, it throws {@link CommonError.PARSE_JSON}
     *
     * @param bytes         json string in the form of bytes, {@link uint8} array
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param names_case    Name case of element names in a json string
     */
    public Jsoner.from_data (
        uint8[] data,
        string[]? sub_members = null,
        Case names_case = Case.KEBAB
    ) throws CommonError {
        this ((string) data, sub_members, names_case);
    }

    static Json.Node? steps (
        Json.Node node,
        string[] sub_members
    ) throws CommonError {
        string has_members = "";

        foreach (string member_name in sub_members) {
            if (node.get_object ().has_member (member_name)) {
                node = node.get_object ().get_member (member_name);
                has_members += member_name + "-";

            } else {
                throw new CommonError.PARSE_JSON ("Json has no %s%s".printf (has_members, member_name));
            }
        }

        return node;
    }

    /////////////////
    // Serialize  //
    /////////////////

    /**
     * Serialize {@link Object} into a correct json string
     *
     * @param datalist      {@link Object}
     * @param names_case    Name case of element names in a json string
     *
     * @return              json string
     */
    public static string serialize (
        Object obj,
        Case names_case = Case.KEBAB
    ) {
        var builder = new Json.Builder ();
        serialize_object (builder, obj, names_case);

        return Json.to_string (builder.get_root (), false);
    }

    static void serialize_array (
        Json.Builder builder,
        ArrayList array_list,
        Type element_type,
        Case names_case = Case.KEBAB
    ) {
        builder.begin_array ();

        if (element_type == typeof (ArrayList)) {
            var array_of_arrays = (ArrayList<ArrayList?>) array_list;

            if (array_of_arrays.size > 0) {
                Type sub_element_type = ((ArrayList<ArrayList?>) array_list)[0].element_type;

                foreach (var sub_array_list in (ArrayList<ArrayList?>) array_list) {
                    serialize_array (builder, sub_array_list, sub_element_type, names_case);
                }
            }

        } else if (element_type.is_object ()) {
            foreach (var obj in (ArrayList<Object>) array_list) {
                serialize_object (builder, obj, names_case);
            }

        } else {
            switch (element_type) {
                case Type.STRING:
                    foreach (var val in (ArrayList<string>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.INT:
                    foreach (var val in (ArrayList<int>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.INT64:
                    foreach (var val in (ArrayList<int64?>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.DOUBLE:
                    foreach (var val in (ArrayList<double?>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.BOOLEAN:
                    foreach (var val in (ArrayList<bool>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;
            }
        }
        builder.end_array ();
    }

    static void serialize_hash_map (
        Json.Builder builder,
        HashMap hash_map,
        Type element_type,
        Case names_case = Case.KEBAB
    ) {
        builder.begin_object ();

        if (element_type.is_object ()) {
            foreach (var entry in (HashMap<string, Object>) hash_map) {
                builder.set_member_name (entry.key);
                serialize_object (builder, entry.value, names_case);
            }

        } else {
            switch (element_type) {
                case Type.STRING:
                    foreach (var entry in (HashMap<string, string>) hash_map) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;

                case Type.INT:
                    foreach (var entry in (HashMap<string, int>) hash_map) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;

                case Type.INT64:
                    foreach (var entry in (HashMap<string, int64?>) hash_map) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;

                case Type.DOUBLE:
                    foreach (var entry in (HashMap<string, double?>) hash_map) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;

                case Type.BOOLEAN:
                    foreach (var entry in (HashMap<string, bool>) hash_map) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;
            }
        }
        builder.end_object ();
    }

    static void serialize_object (
        Json.Builder builder,
        Object? api_obj,
        Case names_case = Case.KEBAB
    ) {
        if (api_obj == null) {
            builder.add_null_value ();

            return;
        }

        builder.begin_object ();
        var cls = (ObjectClass) api_obj.get_type ().class_ref ();

        foreach (ParamSpec property in cls.list_properties ()) {
            if (((property.flags & ParamFlags.READABLE) == 0) || ((property.flags & ParamFlags.WRITABLE) == 0)) {
                continue;
            }

            switch (names_case) {
                case Case.CAMEL:
                    builder.set_member_name (kebab2camel (strip (property.name, '-')));
                    break;

                case Case.SNAKE:
                    builder.set_member_name (kebab2snake (strip (property.name, '-')));
                    break;

                case Case.KEBAB:
                    builder.set_member_name (strip (property.name, '-'));
                    break;

                default:
                    error ("Unknown case - %s", names_case.to_string ());
            }

            var prop_val = Value (property.value_type);
            api_obj.get_property (property.name, ref prop_val);

            if (property.value_type == typeof (ArrayList)) {
                var array_list = (ArrayList) prop_val.get_object ();
                Type element_type = array_list.element_type;

                serialize_array (builder, array_list, element_type, names_case);

            } else if (property.value_type == typeof (HashMap)) {
                var hash_map = (HashMap) prop_val.get_object ();
                Type element_type = hash_map.element_type;

                serialize_hash_map (builder, hash_map, element_type, names_case);

            } else if (property.value_type.is_object ()) {
                serialize_object (builder, (Object) prop_val.get_object (), names_case);

            } else if (property.value_type.is_enum ()) {
                serialize_enum (builder, property.value_type, prop_val);

            } else {
                serialize_value (builder, prop_val);
            }
        }

        builder.end_object ();
    }

    static void serialize_enum (Json.Builder builder, Type enum_type, Value prop_val) {
        builder.add_string_value (get_enum_nick (enum_type, prop_val.get_enum ()));
    }

    static void serialize_value (Json.Builder builder, Value prop_val) {
        switch (prop_val.type ()) {
            case Type.INT:
            case Type.INT64:
                builder.add_int_value (convert_to_int64 (prop_val));
                break;

            case Type.DOUBLE:
                builder.add_double_value (convert_to_double (prop_val));
                break;

            case Type.STRING:
                builder.add_string_value (convert_to_string (prop_val));
                break;

            case Type.BOOLEAN:
                builder.add_boolean_value (convert_to_bool (prop_val));
                break;

            case Type.NONE:
                builder.add_null_value ();
                break;

            default:
                warning ("Unknown type for serialize - %s", prop_val.type ().name ());
                break;
        }
    }

    ///////////////////
    // Deserialize  //
    ///////////////////

    /**
     * Method for deserializing the {@link Object}
     *
     * @param obj_type  the type of object that the json will be deserialized by
     * @param node      the node that will be deserialized. Will be used
     *                  root if `null` is passed
     *
     * @return deserialized object
     */
    public T deserialize_object<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        return deserialize_object_by_type (typeof (T), sub_creation_func);
    }

    public Object deserialize_object_by_type (
        GLib.Type obj_type,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        var obj = Object.new (obj_type);

        deserialize_object_into (obj, sub_creation_func);

        return obj;
    }

    internal Object deserialize_object_by_type_real (
        GLib.Type obj_type,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        var obj = Object.new (obj_type);

        deserialize_object_into_real (obj, node, sub_creation_func);

        return obj;
    }

    public void deserialize_object_into (
        Object obj,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        deserialize_object_into_real (obj, null, sub_creation_func);
    }

    /**
     * Method for deserializing the {@link Object} into the given object
     *
     * @param obj    already created object
     * @param node          the node that will be deserialized. Will be used
     *                      root if `null` is passed
     *
     * @return deserialized object
     */
    internal void deserialize_object_into_real (
        Object obj,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.OBJECT.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new CommonError.PARSE_JSON ("Node isn't object");
        }

        obj.freeze_notify ();

        var obj_type = obj.get_type ();
        var class_ref = (ObjectClass) obj_type.class_ref ();
        ParamSpec[] properties = class_ref.list_properties ();

        foreach (ParamSpec property in properties) {
            if ((property.flags & ParamFlags.WRITABLE) == 0) {
                continue;
            }

            Type prop_type = property.value_type;

            string member_name;
            switch (names_case) {
                case Case.CAMEL:
                    member_name = kebab2camel (strip (property.name, '-'));
                    break;

                case Case.SNAKE:
                    member_name = kebab2snake (strip (property.name, '-'));
                    break;

                case Case.KEBAB:
                    member_name = strip (property.name, '-');
                    break;

                default:
                    error ("Unknown case - %s", names_case.to_string ());
            }

            if (!node.get_object ().has_member (member_name)) {
                warning ("Json string hasn't '%s' of %s::%s", member_name, obj_type.name (), property.name);
                continue;
            }

            var sub_node = node.get_object ().get_member (member_name);

            switch (sub_node.get_node_type ()) {
                case Json.NodeType.ARRAY:
                    var arrayval = Value (prop_type);
                    obj.get_property (property.name, ref arrayval);
                    ArrayList array_list = (Gee.ArrayList) arrayval.get_object ();

                    deserialize_array_into_real (array_list, sub_node, sub_creation_func);
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

                        deserialize_dict_into_real (hash_map, sub_node, sub_creation_func);
                        obj.set_property (
                            property.name,
                            hash_map
                        );
                        break;

                    } else {
                        obj.set_property (
                            property.name,
                            deserialize_object_by_type_real (prop_type, sub_node, sub_creation_func)
                        );
                    }

                    break;

                case Json.NodeType.VALUE:
                    var val = deserialize_value_real (sub_node);
                    if (prop_type.is_enum ()) {
                        obj.set_property (
                            property.name,
                            get_enum_by_nick (prop_type, val.get_string ())
                        );

                    } else {
                        obj.set_property (
                            property.name,
                            convert_type (prop_type, val)
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

    /**
     * Method for deserializing the {@link GLib.Value}
     *
     * @param node      the node that will be deserialized. Will be used
     *                  root if `null` is passed
     *
     * @return deserialized value
     */
    public Value deserialize_value () throws CommonError {
        return deserialize_value_real (null);
    }

    internal Value deserialize_value_real (Json.Node? node = null) throws CommonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.VALUE) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.VALUE.to_string (),
                node.get_node_type ().to_string ()
            );

            throw new CommonError.PARSE_JSON ("Node isn't value");
        }

        return node.get_value ();
    }

    /**
     * Method for deserializing the {@link Gee.ArrayList}
     *
     * @param array_list        array
     * @param node              the node that will be deserialized. Will be used
     *                          root if `null` is passed
     * @param sub_creation_func a function for creating subsets in the case of arrays in an array
     */
    public void deserialize_array_into (
        ArrayList array_list,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        deserialize_array_into_real (array_list, null, sub_creation_func);
    }

    internal void deserialize_array_into_real (
        ArrayList array_list,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.ARRAY) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.ARRAY.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new CommonError.PARSE_JSON ("Node isn't array");
        }

        var jarray = node.get_array ();

        if (array_list.element_type == typeof (ArrayList)) {
            var narray_list = array_list as ArrayList<ArrayList>;

            assert (narray_list.size != 0);

            Type sub_element_type = narray_list[0].element_type;

            foreach (var sub_node in jarray.get_elements ()) {
                Traversable new_col;

                if (sub_creation_func != null) {
                    if (!sub_creation_func (out new_col, sub_element_type)) {
                        error ("Creation func failed");
                    }

                } else {
                    error ("Creation func is null");
                }

                assert (new_col is ArrayList);
                var new_array_list = (ArrayList) new_col;

                try {
                    deserialize_array_into_real (new_array_list, sub_node, sub_creation_func);
                    narray_list.add (new_array_list);
                } catch (CommonError e) {}
            }

            narray_list.remove (narray_list[0]);
        } else if (array_list.element_type.is_object ()) {
            array_list.clear ();
            var narray_list = array_list as ArrayList<Object>;

            foreach (var sub_node in jarray.get_elements ()) {
                try {
                    narray_list.add (deserialize_object_by_type_real (narray_list.element_type, sub_node));
                } catch (CommonError e) {}
            }

        } else {
            array_list.clear ();

            switch (array_list.element_type) {
                case Type.STRING:
                    var narray_list = array_list as ArrayList<string>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        narray_list.add (convert_to_string (deserialize_value_real (sub_node)));
                    }
                    break;

                case Type.INT:
                    var narray_list = array_list as ArrayList<int>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        narray_list.add (convert_to_int (deserialize_value_real (sub_node)));
                    }
                    break;

                case Type.INT64:
                    var narray_list = array_list as ArrayList<int64?>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        narray_list.add (convert_to_int64 (deserialize_value_real (sub_node)));
                    }
                    break;

                case Type.DOUBLE:
                    var narray_list = array_list as ArrayList<double?>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        narray_list.add (convert_to_double (deserialize_value_real (sub_node)));
                    }
                    break;

                case Type.BOOLEAN:
                    var narray_list = array_list as ArrayList<bool>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        narray_list.add (convert_to_bool (deserialize_value_real (sub_node)));
                    }
                    break;

                default:
                    warning ("Unknown type of element of array - %s",
                        array_list.element_type.name ()
                    );
                    break;
            }
        }
    }

    /**
     * Method for deserializing the {@link Gee.ArrayList}
     *
     * @param array_list        array
     * @param node              the node that will be deserialized. Will be used
     *                          root if `null` is passed
     * @param sub_creation_func a function for creating subsets in the case of arrays in an array
     */
    public void deserialize_dict_into (
        HashMap hash_map,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        deserialize_dict_into_real (hash_map, null, sub_creation_func);
    }

    internal void deserialize_dict_into_real (
        HashMap hash_map,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.OBJECT.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new CommonError.PARSE_JSON ("Node isn't object");
        }

        if (hash_map.key_type != Type.STRING) {
            error ("HashMap can only have string as key type");
        }

        var jobject = node.get_object ();

        if (hash_map.element_type.is_object ()) {
            hash_map.clear ();
            var narray_list = hash_map as HashMap<string, Object>;

            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);

                try {
                    narray_list[member_name] = deserialize_object_by_type_real (
                        narray_list.element_type,
                        sub_node,
                        sub_creation_func
                    );
                } catch (CommonError e) {}
            }

        } else {
            hash_map.clear ();

            switch (hash_map.element_type) {
                case Type.STRING:
                    var narray_list = hash_map as HashMap<string, string>;

                    foreach (var member_name in jobject.get_members ()) {
                        var sub_node = jobject.get_member (member_name);

                        narray_list[member_name] = convert_to_string (deserialize_value_real (sub_node));
                    }

                    break;

                case Type.INT:
                    var narray_list = hash_map as HashMap<string, int>;

                    foreach (var member_name in jobject.get_members ()) {
                        var sub_node = jobject.get_member (member_name);

                        narray_list[member_name] = convert_to_int (deserialize_value_real (sub_node));
                    }
                    break;

                case Type.INT64:
                    var narray_list = hash_map as HashMap<string, int64?>;

                    foreach (var member_name in jobject.get_members ()) {
                        var sub_node = jobject.get_member (member_name);

                        narray_list[member_name] = convert_to_int64 (deserialize_value_real (sub_node));
                    }
                    break;

                case Type.DOUBLE:
                    var narray_list = hash_map as HashMap<string, double>;

                    foreach (var member_name in jobject.get_members ()) {
                        var sub_node = jobject.get_member (member_name);

                        narray_list[member_name] = convert_to_double (deserialize_value_real (sub_node));
                    }
                    break;

                case Type.BOOLEAN:
                    var narray_list = hash_map as HashMap<string, bool>;

                    foreach (var member_name in jobject.get_members ()) {
                        var sub_node = jobject.get_member (member_name);

                        narray_list[member_name] = convert_to_bool (deserialize_value_real (sub_node));
                    }
                    break;

                default:
                    warning ("Unknown type of element of hashmap - %s",
                        hash_map.element_type.name ()
                    );
                    break;
            }
        }
    }

    // ASYNC

    /**
     * Asynchronous version of method {@link serialize}
     */
    public static async string serialize_async (
        Object obj,
        Case names_case = Case.KEBAB
    ) {
        var thread = new Thread<string> (null, () => {
            var result = serialize (obj, names_case);

            Idle.add (serialize_async.callback);
            return result;
        });

        yield;

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_object}
     */
    public async T deserialize_object_async<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        CommonError? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = deserialize_object<T> (sub_creation_func);
            } catch (CommonError e) {
                error = e;
            }

            Idle.add (deserialize_object_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_object_by_type}
     */
    public async Object deserialize_object_by_type_async (
        GLib.Type obj_type,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        CommonError? error = null;

        var thread = new Thread<Object?> (null, () => {
            Object? result = null;

            try {
                result = deserialize_object_by_type (obj_type, sub_creation_func);
            } catch (CommonError e) {
                error = e;
            }

            Idle.add (deserialize_object_by_type_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_object_into}
     */
    public async void deserialize_object_into_async (
        Object obj,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        CommonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_object_into (obj, sub_creation_func);
            } catch (CommonError e) {
                error = e;
            }

            Idle.add (deserialize_object_into_async.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_array_into}
     */
    public async void deserialize_array_into_async (
        ArrayList array_list,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws CommonError {
        CommonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_array_into (array_list, sub_creation_func);
            } catch (CommonError e) {
                error = e;
            }

            Idle.add (deserialize_array_into_async.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }
}
