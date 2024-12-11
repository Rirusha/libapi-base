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
     * @param json_string   Corrent json string
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
     * Serialize {@link GLib.Datalist} into a correct json string
     *
     * @param datalist  {@link GLib.Datalist}
     *
     * @return          json string
     */
    public static string serialize_datalist (Datalist<string> datalist) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        datalist.foreach ((key_id, data) => {
            builder.set_member_name (key_id.to_string ());

            Jsoner.serialize_value (builder, data);
        });

        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());

        return generator.to_data (null);
    }

    /**
     * Serialize {@link Object} into a correct json string
     *
     * @param datalist      {@link Object}
     * @param names_case    Name case of element names in a json string
     *
     * @return              json string
     */
    public static string serialize (
        Object api_obj,
        Case names_case = Case.KEBAB
    ) {
        var builder = new Json.Builder ();
        serialize_object (builder, api_obj, names_case);

        return Json.to_string (builder.get_root (), false);
    }

    static void serialize_array (
        Json.Builder builder,
        ArrayList array_list,
        Type element_type,
        Case names_case = Case.KEBAB
    ) {
        builder.begin_array ();

        if (element_type.parent () == typeof (Object)) {
            foreach (var api_obj in (ArrayList<Object>) array_list) {
                serialize_object (builder, api_obj, names_case);
            }
        } else if (element_type == typeof (ArrayList)) {
            var array_of_arrays = (ArrayList<ArrayList?>) array_list;

            if (array_of_arrays.size > 0) {
                Type sub_element_type = ((ArrayList<ArrayList?>) array_list)[0].element_type;

                foreach (var sub_array_list in (ArrayList<ArrayList?>) array_list) {
                    serialize_array (builder, sub_array_list, sub_element_type, names_case);
                }
            }
        } else {
            switch (element_type) {
                case Type.STRING:
                    foreach (string val in (ArrayList<string>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.INT:
                    foreach (int val in (ArrayList<int>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;
            }
        }
        builder.end_array ();
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

            } else if (property.value_type.is_object ()) {
                serialize_object (builder, (Object) prop_val.get_object (), names_case);

            } else {
                serialize_value (builder, prop_val);
            }
        }

        builder.end_object ();
    }

    static void serialize_value (Json.Builder builder, Value prop_val) {
        switch (prop_val.type ()) {
            case Type.INT:
                builder.add_int_value (prop_val.get_int ());
                break;

            case Type.INT64:
                builder.add_int_value (prop_val.get_int64 ());
                break;

            case Type.DOUBLE:
                builder.add_double_value (prop_val.get_double ());
                break;

            case Type.STRING:
                builder.add_string_value (prop_val.get_string ());
                break;

            case Type.BOOLEAN:
                builder.add_boolean_value (prop_val.get_boolean ());
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
    public Object deserialize_object (
        GLib.Type obj_type,
        Json.Node? node = null,
        SubArrayCreationFunc? sub_creation_func = null
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

        var api_object = (Object) Object.new (obj_type);
        api_object.freeze_notify ();

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
                continue;
            }

            var sub_node = node.get_object ().get_member (member_name);

            switch (sub_node.get_node_type ()) {
                case Json.NodeType.ARRAY:
                    var arrayval = Value (prop_type);
                    api_object.get_property (property.name, ref arrayval);
                    ArrayList array_list = (Gee.ArrayList) arrayval.get_object ();

                    deserialize_array (array_list, sub_node, sub_creation_func);
                    api_object.set_property (
                        property.name,
                        array_list
                    );
                    break;

                case Json.NodeType.OBJECT:
                    api_object.set_property (
                        property.name,
                        deserialize_object (prop_type, sub_node, sub_creation_func)
                    );
                    break;

                case Json.NodeType.VALUE:
                    var val = deserialize_value (sub_node);
                    if ((val.type () == Type.INT64) && (prop_type == Type.STRING)) {
                        api_object.set_property (
                            property.name,
                            val.get_int64 ().to_string ()
                        );
                    } else {
                        api_object.set_property (
                            property.name,
                            val
                        );
                    }
                    break;

                case Json.NodeType.NULL:
                    api_object.set_property (
                        property.name,
                        Value (prop_type)
                    );
                    break;
            }
        }

        api_object.thaw_notify ();

        return api_object;
    }

    /**
     * Method for deserializing the {@link GLib.Value}
     *
     * @param node      the node that will be deserialized. Will be used
     *                  root if `null` is passed
     *
     * @return deserialized value
     */
    public Value deserialize_value (Json.Node? node = null) throws CommonError {
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
    public void deserialize_array (
        ArrayList array_list,
        Json.Node? node = null,
        SubArrayCreationFunc? sub_creation_func = null
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
                ArrayList new_array_list;

                if (sub_creation_func != null) {
                    if (!sub_creation_func (out new_array_list, sub_element_type)) {
                        error ("Creation func failed");
                    }

                } else {
                    error ("Creation func is null");
                }

                try {
                    deserialize_array (new_array_list, sub_node, sub_creation_func);
                    narray_list.add (new_array_list);
                } catch (CommonError e) {}
            }

            narray_list.remove (narray_list[0]);
        } else if (array_list.element_type.is_object ()) {
            array_list.clear ();
            var narray_list = array_list as ArrayList<Object>;

            foreach (var sub_node in jarray.get_elements ()) {
                try {
                    narray_list.add (deserialize_object (narray_list.element_type, sub_node));
                } catch (CommonError e) {}
            }

        } else {
            array_list.clear ();

            switch (array_list.element_type) {
                case Type.STRING:
                    var narray_list = array_list as ArrayList<string>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        try {
                            narray_list.add (deserialize_value (sub_node).get_string ());
                        } catch (CommonError e) {}
                    }
                    break;

                case Type.INT:
                    var narray_list = array_list as ArrayList<int>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        try {
                            narray_list.add ((int) deserialize_value (sub_node).get_int64 ());
                        } catch (CommonError e) {}
                    }
                    break;

                case Type.INT64:
                    var narray_list = array_list as ArrayList<int64>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        try {
                            narray_list.add (deserialize_value (sub_node).get_int64 ());
                        } catch (CommonError e) {}
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

    // ASYNC

    /**
     * Asynchronous version of method {@link serialize}
     */
    public static async string serialize_async (
        Object api_obj,
        Case names_case = Case.KEBAB
    ) {
        var builder = new Json.Builder ();
        yield serialize_object_async (builder, api_obj, names_case);

        return Json.to_string (builder.get_root (), false);
    }

    /**
     * Asynchronous version of method {@link serialize_array}
     */
    static async void serialize_array_async (
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
                    yield serialize_array_async (builder, sub_array_list, sub_element_type, names_case);

                    Idle.add (serialize_array_async.callback);
                    yield;
                }
            }
        } else if (element_type.is_object ()) {
            foreach (var api_obj in (ArrayList<Object>) array_list) {
                yield serialize_object_async (builder, api_obj, names_case);

                Idle.add (serialize_array_async.callback);
                yield;
            }
        } else {
            switch (element_type) {
                case Type.STRING:
                    foreach (string val in (ArrayList<string>) array_list) {
                        serialize_value (builder, val);

                        Idle.add (serialize_array_async.callback);
                        yield;
                    }
                    break;

                case Type.INT:
                    foreach (int val in (ArrayList<int>) array_list) {
                        serialize_value (builder, val);

                        Idle.add (serialize_array_async.callback);
                        yield;
                    }
                    break;
            }
        }
        builder.end_array ();
    }

    /**
     * Asynchronous version of method {@link serialize_object}
     */
    static async void serialize_object_async (
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

                yield serialize_array_async (builder, array_list, element_type, names_case);
            } else if (property.value_type.is_object ()) {
                yield serialize_object_async (builder, (Object) prop_val.get_object (), names_case);
            } else {
                serialize_value (builder, prop_val);
            }

            Idle.add (serialize_object_async.callback);
            yield;
        }

        builder.end_object ();
    }

    ///////////////////
    // Deserialize  //
    ///////////////////

    /**
     * Asynchronous version of method {@link deserialize_object}
     */
    public async Object deserialize_object_async (
        GLib.Type obj_type,
        Json.Node? node = null,
        SubArrayCreationFunc? sub_creation_func = null
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

        var api_object = (Object) Object.new (obj_type);
        api_object.freeze_notify ();

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
                continue;
            }

            var sub_node = node.get_object ().get_member (member_name);

            switch (sub_node.get_node_type ()) {
                case Json.NodeType.ARRAY:
                    var arrayval = Value (prop_type);
                    api_object.get_property (property.name, ref arrayval);
                    ArrayList array_list = (Gee.ArrayList) arrayval.get_object ();

                    yield deserialize_array_async (array_list, sub_node, sub_creation_func);
                    api_object.set_property (
                        property.name,
                        array_list
                    );
                    break;

                case Json.NodeType.OBJECT:
                    api_object.set_property (
                        property.name,
                        yield deserialize_object_async (prop_type, sub_node, sub_creation_func)
                    );
                    break;

                case Json.NodeType.VALUE:
                    var val = deserialize_value (sub_node);
                    if ((val.type () == Type.INT64) && (prop_type == Type.STRING)) {
                        api_object.set_property (
                            property.name,
                            val.get_int64 ().to_string ()
                        );
                    } else {
                        api_object.set_property (
                            property.name,
                            val
                        );
                    }
                    break;

                case Json.NodeType.NULL:
                    api_object.set_property (
                        property.name,
                        Value (prop_type)
                    );
                    break;
            }

            Idle.add (deserialize_object_async.callback);
            yield;
        }

        api_object.thaw_notify ();

        return api_object;
    }

    /**
     * Asynchronous version of method {@link deserialize_array}
     */
    public async void deserialize_array_async (
        ArrayList array_list,
        Json.Node? node = null,
        SubArrayCreationFunc? sub_creation_func = null
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

            // Проверка, если ли в массиве массив, из которого будет взят тип
            assert (narray_list.size != 0);

            Type sub_element_type = narray_list[0].element_type;

            foreach (var sub_node in jarray.get_elements ()) {
                ArrayList new_array_list;

                if (sub_creation_func != null) {
                    if (!sub_creation_func (out new_array_list, sub_element_type)) {
                        error ("Creation func failed");
                    }

                } else {
                    error ("Creation func is null");
                }

                try {
                    yield deserialize_array_async (new_array_list, sub_node, sub_creation_func);
                    narray_list.add (new_array_list);
                } catch (CommonError e) {}

                Idle.add (deserialize_array_async.callback);
                yield;
            }

            narray_list.remove (narray_list[0]);
        } else if (array_list.element_type.is_object ()) {
            array_list.clear ();
            var narray_list = array_list as ArrayList<Object>;

            foreach (var sub_node in jarray.get_elements ()) {
                try {
                    narray_list.add (yield deserialize_object_async (narray_list.element_type, sub_node));
                } catch (CommonError e) {}

                Idle.add (deserialize_array_async.callback);
                yield;
            }

        } else {
            array_list.clear ();

            switch (array_list.element_type) {
                case Type.STRING:
                    var narray_list = array_list as ArrayList<string>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        try {
                            narray_list.add (deserialize_value (sub_node).get_string ());
                        } catch (CommonError e) {}

                        Idle.add (deserialize_array_async.callback);
                        yield;
                    }
                    break;

                case Type.INT:
                    var narray_list = array_list as ArrayList<int>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        try {
                            narray_list.add ((int) deserialize_value (sub_node).get_int64 ());
                        } catch (CommonError e) {}

                        Idle.add (deserialize_array_async.callback);
                        yield;
                    }
                    break;

                case Type.INT64:
                    var narray_list = array_list as ArrayList<int64>;

                    foreach (var sub_node in jarray.get_elements ()) {
                        try {
                            narray_list.add (deserialize_value (sub_node).get_int64 ());
                        } catch (CommonError e) {}

                        Idle.add (deserialize_array_async.callback);
                        yield;
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
}
