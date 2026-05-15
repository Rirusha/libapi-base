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

/**
 * Json helper for de/serialization
 */
[Version (since = "7.5")]
public sealed class Serialize.JsonWorker : Worker {

    internal Json.Node root { get; private set; }

    /**
     * Performs initialization for deserialization. Accepts a json string. In case of
     * a parsing error
     *
     * @param json_string   Correct json string
     * @param sub_members   An array of names of json elements that need to be traversed
     *                      to the target node
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with json or sub_members
     */
    [Version (since = "7.5")]
    public JsonWorker (
        string json_string,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        if (json_string.length < 1) {
            throw new Serialize.Error.EMPTY ("Json string is empty");
        }

        Json.Node? node;
        try {
            node = Json.from_string (json_string);

        } catch (GLib.Error e) {
            throw new Serialize.Error.INVALID ("'%s' is not correct json string".printf (json_string));
        }

        if (node == null) {
            throw new Serialize.Error.EMPTY ("Json string is empty");
        }

        if (sub_members != null) {
            node = steps (node, sub_members);
        }

        debug (
            "Json initted for deserialize with:\n%s",
            json_string
        );

        Object (
            settings: settings == null ? get_settings () : settings
        );

        root = node;
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the
     * form of bytes, the object {@link GLib.Bytes}. In case of a parsing error
     *
     * @param bytes         Json string in the form of bytes, the object {@link GLib.Bytes}
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with json or sub_members
     */
    [Version (since = "7.5")]
    public JsonWorker.from_bytes (
        Bytes bytes,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        if (bytes.length == 0) {
            throw new Serialize.Error.EMPTY ("Json string is empty");
        }

        this.from_data (bytes.get_data (), sub_members, settings);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the form of bytes,
     * an {@link uint8} array. In case of a parsing error
     *
     * @param data         Json string in the form of bytes, {@link uint8} array
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with json or sub_members
     */
    [Version (since = "7.5")]
    public JsonWorker.from_data (
        owned uint8[] data,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        //  Fix not NUL-terminated
        if (data[data.length - 1] != 0) {
            data.resize (data.length + 1);
            data[data.length - 1] = 0;
        }

        this ((string) data, sub_members, settings);
    }

    static Json.Node? steps (
        Json.Node node,
        string[] sub_members
    ) throws Serialize.Error {
        var members_trace = new GLib.Array<string> ();

        foreach (string member_name in sub_members) {
            members_trace.append_val (member_name);

            if (node.get_object ().has_member (member_name)) {
                node = node.get_object ().get_member (member_name);

            } else {
                throw new Serialize.Error.NO_MEMBER ("Json has no %s".printf (string.joinv ("-", members_trace.data)));
            }
        }

        return node;
    }

    /**
     * Serialize {@link GLib.Object} into a correct json string
     *
     * @param obj               {@link GLib.Object}
     * @param settings          Settings
     *
     * @return                  Json string
     */
    [Version (since = "7.5")]
    public static inline string serialize (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        return JsonSerializeSync.serialize (obj, settings);
    }

    /**
     * {@link deserialize} without
     * manual {@link Json} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with json or sub_members
     */
    [Version (since = "7.5")]
    public static inline Dict<Value?> simple_deserialize (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        return JsonDeserializeSync.simple_deserialize (json, sub_members, settings);
    }

    /**
     * Object creation method from json 
     * via {@link Json.deserialize_object}
     * Simple version for fast deserialization without
     * manual {@link Json} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with json or sub_members
     */
    [Version (since = "7.5")]
    public static inline T simple_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        return JsonDeserializeSync.simple_from_json<T> (json, sub_members, settings);
    }

    /**
     * Array creation method from json 
     * via {@link Json.deserialize_array}
     * Simple version for fast deserialization without
     * manual {@link Json} instance creation
     *
     * @param json                  Json string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized array
     *
     * @throws Serialize.Error            Error with json or sub_members
     */
    [Version (since = "7.5")]
    public static inline Array<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        return JsonDeserializeSync.simple_array_from_json<T> (json, sub_members, settings, collection_hierarchy);
    }

    /**
     * Dict creation method from json 
     * via {@link Json.deserialize_dict}
     * Simple version for fast deserialization without
     * manual {@link Json} instance creation
     *
     * @param json                  Json string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized dict
     *
     * @throws Serialize.Error            Error with json or sub_members
     */
    [Version (since = "7.5")]
    public static inline Dict<T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        return JsonDeserializeSync.simple_dict_from_json<T> (json, sub_members, settings, collection_hierarchy);
    }

    [Version (since = "7.5")]
    public override inline Object deserialize_object_by_type (
        GLib.Type obj_type
    ) throws Serialize.Error {
        return JsonDeserializeSync.deserialize_object_by_type (this, obj_type);
    }

    [Version (since = "6.0")]
    public override inline void deserialize_object_into (
        Object obj
    ) throws Serialize.Error {
        JsonDeserializeSync.deserialize_object_into (this, obj);
    }

    [Version (since = "7.5")]
    public override inline Value deserialize_value () throws Serialize.Error {
        return JsonDeserializeSync.deserialize_value (this);
    }

    [Version (since = "7.5")]
    public override inline void deserialize_array_into (
        Array array,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        JsonDeserializeSync.deserialize_array_into (this, array, collection_hierarchy);
    }

    [Version (since = "7.5")]
    public override inline void deserialize_dict_into (
        Dict dict,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        JsonDeserializeSync.deserialize_dict_into (this, dict, collection_hierarchy);
    }

    /**
     * Asynchronous version of method {@link serialize}
     */
    [Version (since = "7.5")]
    public static inline async string serialize_async (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        return yield JsonSerializeAsync.serialize (obj, settings);
    }

    /**
     * Asynchronous version of method {@link simple_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with json or sub_members
     */
    [Version (since = "7.5")]
    public async static inline T simple_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        return yield JsonDeserializeAsync.simple_from_json<T> (json, sub_members, settings);
    }

    /**
     * Asynchronous version of method {@link simple_array_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized array
     *
     * @throws Serialize.Error        Error with json or sub_members
     */
    [Version (since = "7.5")]
    public async static inline Array<T> simple_array_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        return yield JsonDeserializeAsync.simple_array_from_json<T> (json, sub_members, settings);
    }

    /**
     * Asynchronous version of method {@link simple_dict_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized dict
     *
     * @throws Serialize.Error        Error with json or sub_members
     */
    [Version (since = "7.5")]
    public async static inline Dict<T> simple_dict_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        return yield JsonDeserializeAsync.simple_dict_from_json<T> (json, sub_members, settings);
    }
}
