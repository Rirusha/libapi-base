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


/**
 * Json helper for de/serialization
 */
[Version (since = "6.0")]
public class Serialize.Jsoner : Object {

    /**
     * Names case used for deserialization
     */
    public Case names_case { get; construct; }

    public Json.Node root { internal get; construct; }

    /**
     * Performs initialization for deserialization. Accepts a json string. In case of
     * a parsing error
     *
     * @param json_string   Correct json string
     * @param sub_members   An array of names of json elements that need to be traversed
     *                      to the target node
     * @param names_case    Name case of element names in a json string
     *
     * @throws JsonError    Error with json or sub_members
     */
    [Version (since = "6.0")]
    public Jsoner (
        string json_string,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        if (json_string.length < 1) {
            throw new JsonError.EMPTY ("Json string is empty");
        }

        Json.Node? node;
        try {
            node = Json.from_string (json_string);

        } catch (GLib.Error e) {
            throw new JsonError.INVALID ("'%s' is not correct json string".printf (json_string));
        }

        if (node == null) {
            throw new JsonError.EMPTY ("Json string is empty");
        }

        if (sub_members != null) {
            node = steps (node, sub_members);
        }

        debug (
            "Jsoner initted for deserialize with:\n%s",
            json_string
        );

        Object (root: node, names_case: names_case);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the
     * form of bytes, the object {@link GLib.Bytes}. In case of a parsing error
     *
     * @param bytes         Json string in the form of bytes, the object {@link GLib.Bytes}
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param names_case    Name case of element names in a json string
     *
     * @throws JsonError    Error with json or sub_members
     */
    [Version (since = "6.0")]
    public Jsoner.from_bytes (
        Bytes bytes,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        if (bytes.length == 0) {
            throw new JsonError.EMPTY ("Json string is empty");
        }

        this.from_data (bytes.get_data (), sub_members, names_case);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the form of bytes,
     * an {@link uint8} array. In case of a parsing error
     *
     * @param data         Json string in the form of bytes, {@link uint8} array
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param names_case    Name case of element names in a json string
     *
     * @throws JsonError    Error with json or sub_members
     */
    [Version (since = "6.0")]
    public Jsoner.from_data (
        owned uint8[] data,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        //  Fix not NUL-terminated
        if (data[data.length - 1] != 0) {
            data.resize (data.length + 1);
            data[data.length - 1] = 0;
        }

        this ((string) data, sub_members, names_case);
    }

    static Json.Node? steps (
        Json.Node node,
        string[] sub_members
    ) throws JsonError {
        var members_trace = new Array<string> ();

        foreach (string member_name in sub_members) {
            members_trace.append_val (member_name);

            if (node.get_object ().has_member (member_name)) {
                node = node.get_object ().get_member (member_name);

            } else {
                throw new JsonError.NO_MEMBER ("Json has no %s".printf (string.joinv ("-", members_trace.data)));
            }
        }

        return node;
    }

    /**
     * Serialize {@link GLib.Object} into a correct json string
     *
     * @param obj               {@link GLib.Object}
     * @param names_case        Name case of element names in a json string
     * @param pretty            Pretty print of json or not
     * @param ignore_default    Ignore fields with default values during object serialization. This option works only with primitive types
     *
     * @return              Json string
     */
    [Version (since = "6.0")]
    public static inline string serialize (
        Object obj,
        Case names_case = Case.AUTO,
        bool pretty = false,
        bool ignore_default = false
    ) {
        return JsonerSerializeSync.serialize (obj, names_case, pretty, ignore_default);
    }

    /**
     * Object creation method from json 
     * via {@link Jsoner.deserialize_object}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized object
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public static inline T simple_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        return JsonerDeserializeSync.simple_from_json<T> (json, sub_members, names_case);
    }

    /**
     * Array creation method from json 
     * via {@link Jsoner.deserialize_array}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized array
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public static inline ArrayList<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        return JsonerDeserializeSync.simple_array_from_json<T> (json, sub_members, names_case, collection_hierarchy);
    }

    /**
     * Dict creation method from json 
     * via {@link Jsoner.deserialize_dict}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized dict
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public static inline HashMap<string, T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        return JsonerDeserializeSync.simple_dict_from_json<T> (json, sub_members, names_case, collection_hierarchy);
    }

    /**
     * Method for deserializing the {@link GLib.Object}
     *
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline T deserialize_object<T> () throws JsonError {
        return JsonerDeserializeSync.deserialize_object<T> (this);
    }

    /**
     * Method for deserializing the {@link GLib.Object} with {@link GLib.Type}
     *
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     * @param obj_type          Type of objects
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline Object deserialize_object_by_type (
        GLib.Type obj_type
    ) throws JsonError {
        return JsonerDeserializeSync.deserialize_object_by_type (this, obj_type);
    }

    /**
     * Method for deserializing into existing object
     *
     * @param obj               Object
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline void deserialize_object_into (
        Object obj
    ) throws JsonError {
        JsonerDeserializeSync.deserialize_object_into (this, obj);
    }

    /**
     * Method for deserializing the {@link GLib.Value}
     *
     * @return deserialized value
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline Value deserialize_value () throws JsonError {
        return JsonerDeserializeSync.deserialize_value (this);
    }

    /**
     * Method for deserializing the {@link Gee.ArrayList}
     *
     * @param collection_hierarchy A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline ArrayList<T> deserialize_array<T> (
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        return JsonerDeserializeSync.deserialize_array<T> (this, collection_hierarchy);
    }

    /**
     * Method for deserializing the {@link Gee.ArrayList}
     *
     * @param array_list        Array
     * @param collection_hierarchy A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline void deserialize_array_into (
        ArrayList array_list,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        JsonerDeserializeSync.deserialize_array_into (this, array_list, collection_hierarchy);
    }

    /**
     * Method for deserializing the {@link Gee.HashMap}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline HashMap<string, T> deserialize_dict<T> (
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        return JsonerDeserializeSync.deserialize_dict<T> (this, collection_hierarchy);
    }

    /**
     * Method for deserializing the {@link Gee.HashMap}
     *
     * @param dict              Dict
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline void deserialize_dict_into (
        HashMap dict,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        JsonerDeserializeSync.deserialize_dict_into (this, dict, collection_hierarchy);
    }

    /**
     * Asynchronous version of method {@link serialize}
     */
    [Version (since = "6.0")]
    public static inline async string serialize_async (
        Object obj,
        Case names_case = Case.AUTO,
        bool pretty = false
    ) {
        return yield JsonerSerializeAsync.serialize (obj, names_case, pretty);
    }

    /**
     * Asynchronous version of method {@link simple_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     *
     * @return                  Deserialized object
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public async static inline T simple_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        return yield JsonerDeserializeAsync.simple_from_json<T> (json, sub_members, names_case);
    }

    /**
     * Asynchronous version of method {@link simple_array_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     *
     * @return                  Deserialized array
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public async static inline ArrayList<T> simple_array_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        return yield JsonerDeserializeAsync.simple_array_from_json<T> (json, sub_members, names_case);
    }

    /**
     * Asynchronous version of method {@link simple_dict_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     *
     * @return                  Deserialized dict
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public async static inline HashMap<string, T> simple_dict_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        return yield JsonerDeserializeAsync.simple_dict_from_json<T> (json, sub_members, names_case);
    }

    /**
     * Asynchronous version of method {@link deserialize_object}
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline T deserialize_object_async<T> () throws JsonError {
        return yield JsonerDeserializeAsync.deserialize_object<T> (this);
    }

    /**
     * Asynchronous version of method {@link deserialize_object_by_type}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline Object deserialize_object_by_type_async (
        GLib.Type obj_type
    ) throws JsonError {
        return yield JsonerDeserializeAsync.deserialize_object_by_type (this, obj_type);
    }

    /**
     * Asynchronous version of method {@link deserialize_object_into}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline void deserialize_object_into_async (
        Object obj
    ) throws JsonError {
        yield JsonerDeserializeAsync.deserialize_object_into (this, obj);
    }

    /**
     * Asynchronous version of method {@link deserialize_array}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async ArrayList<T> deserialize_array_async<T> () throws JsonError {
        return yield JsonerDeserializeAsync.deserialize_array<T> (this);
    }

    /**
     * Asynchronous version of method {@link deserialize_array_into}
     *
     * @param array_list        Array
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline void deserialize_array_into_async (
        ArrayList array_list
    ) throws JsonError {
        yield JsonerDeserializeAsync.deserialize_array_into (this, array_list);
    }

    /**
     * Asynchronous version of method {@link deserialize_dict}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline HashMap<string, T> deserialize_dict_async<T> () throws JsonError {
        return yield JsonerDeserializeAsync.deserialize_dict<T> (this);
    }

    /**
     * Asynchronous version of method {@link deserialize_dict_into}
     *
     * @param dict              Dict
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async void deserialize_dict_into_async (
        HashMap dict
    ) throws JsonError {
        yield JsonerDeserializeAsync.deserialize_dict_into (this, dict);
    }
}
