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
[Version (since = "6.0", deprecated = true, deprecated_since = "7.5", replacement = "Serialize.JsonWorker")]
public class Serialize.Jsoner : Object {

    /**
     * Settings
     */
    public Serialize.Settings settings {
        get {
            return real_worker.settings;
        }
        construct {}
    }

    public Json.Node root { internal get; construct; }

    JsonWorker real_worker;

    /**
     * Performs initialization for deserialization. Accepts a json string. In case of
     * a parsing error
     *
     * @param json_string   Correct json string
     * @param sub_members   An array of names of json elements that need to be traversed
     *                      to the target node
     * @param settings      Settings
     *
     * @throws JsonError    Error with json or sub_members
     */
    [Version (since = "6.0")]
    public Jsoner (
        string json_string,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            real_worker = new JsonWorker (json_string, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the
     * form of bytes, the object {@link GLib.Bytes}. In case of a parsing error
     *
     * @param bytes         Json string in the form of bytes, the object {@link GLib.Bytes}
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param settings      Settings
     *
     * @throws JsonError    Error with json or sub_members
     */
    [Version (since = "6.0")]
    public Jsoner.from_bytes (
        Bytes bytes,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            real_worker = new JsonWorker.from_bytes (bytes, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the form of bytes,
     * an {@link uint8} array. In case of a parsing error
     *
     * @param data         Json string in the form of bytes, {@link uint8} array
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param settings      Settings
     *
     * @throws JsonError    Error with json or sub_members
     */
    [Version (since = "6.0")]
    public Jsoner.from_data (
        owned uint8[] data,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            real_worker = new JsonWorker.from_data (data, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Serialize {@link GLib.Object} into a correct json string
     *
     * @param obj               {@link GLib.Object}
     * @param settings          Settings
     *
     * @return                  Json string
     */
    [Version (since = "6.0")]
    public static inline string serialize (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        return JsonWorker.serialize (obj, settings);
    }

    /**
     * {@link deserialize} without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "7.0")]
    public static inline Dict<Value?> simple_deserialize (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            return JsonWorker.simple_deserialize (json, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Object creation method from json 
     * via {@link Jsoner.deserialize_object}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public static inline T simple_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            return JsonWorker.simple_from_json<T> (json, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Array creation method from json 
     * via {@link Jsoner.deserialize_array}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json                  Json string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized array
     *
     * @throws JsonError            Error with json or sub_members
     */
    [Version (since = "6.0")]
    public static inline Array<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        try {
            return JsonWorker.simple_array_from_json<T> (json, sub_members, settings, collection_hierarchy);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Dict creation method from json 
     * via {@link Jsoner.deserialize_dict}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json                  Json string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized dict
     *
     * @throws JsonError            Error with json or sub_members
     */
    [Version (since = "6.0")]
    public static inline Dict<T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        try {
            return JsonWorker.simple_dict_from_json<T> (json, sub_members, settings, collection_hierarchy);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing to {@link Dict}
     *
     * @return              Deserialized {@link Dict}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "7.0")]
    public inline Dict<Value?> deserialize () throws JsonError {
        try {
            return real_worker.deserialize ();
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing the {@link GLib.Object}
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline T deserialize_object<T> () throws JsonError {
        try {
            return real_worker.deserialize_object<T> ();
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing the {@link GLib.Object} with {@link GLib.Type}
     *
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
        try {
            return real_worker.deserialize_object_by_type (obj_type);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing into existing object
     *
     * @param obj               Object
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline void deserialize_object_into (
        Object obj
    ) throws JsonError {
        try {
            real_worker.deserialize_object_into (obj);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
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
        try {
            return real_worker.deserialize_value ();
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing the {@link Array}
     *
     * @param collection_hierarchy A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline Array<T> deserialize_array<T> (
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        try {
            return real_worker.deserialize_array<T> (collection_hierarchy);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing the {@link Array}
     *
     * @param array        Array
     * @param collection_hierarchy A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline void deserialize_array_into (
        Array array,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        try {
            real_worker.deserialize_array_into (array, collection_hierarchy);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing the {@link Dict}
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline Dict<T> deserialize_dict<T> (
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        try {
            return real_worker.deserialize_dict<T> (collection_hierarchy);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Method for deserializing the {@link Dict}
     *
     * @param dict              Dict
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public inline void deserialize_dict_into (
        Dict dict,
        CollectionFactory[] collection_hierarchy = {}
    ) throws JsonError {
        try {
            real_worker.deserialize_dict_into (dict, collection_hierarchy);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Asynchronous version of method {@link serialize}
     */
    [Version (since = "6.0")]
    public static inline async string serialize_async (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        return yield JsonWorker.serialize_async (obj, settings);
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
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public async static inline T simple_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            return yield JsonWorker.simple_from_json_async<T> (json, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
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
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public async static inline Array<T> simple_array_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            return yield JsonWorker.simple_array_from_json_async<T> (json, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
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
     * @throws JsonError        Error with json or sub_members
     */
    [Version (since = "6.0")]
    public async static inline Dict<T> simple_dict_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws JsonError {
        try {
            return yield JsonWorker.simple_dict_from_json_async<T> (json, sub_members, settings);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
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
        try {
            return yield real_worker.deserialize_object_async<T> ();
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
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
        try {
            return yield real_worker.deserialize_object_by_type_async (obj_type);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
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
        try {
            yield real_worker.deserialize_object_into_async (obj);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Asynchronous version of method {@link deserialize_array}
     *
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async Array<T> deserialize_array_async<T> (
        CollectionFactory[] collection_factories = {}
    ) throws JsonError {
        try {
            return yield real_worker.deserialize_array_async<T> (collection_factories);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Asynchronous version of method {@link deserialize_array_into}
     *
     * @param array        Array
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline void deserialize_array_into_async (
        Array array,
        CollectionFactory[] collection_factories = {}
    ) throws JsonError {
        try {
            yield real_worker.deserialize_array_into_async (array, collection_factories);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Asynchronous version of method {@link deserialize_dict}
     *
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async inline Dict<T> deserialize_dict_async<T> (
        CollectionFactory[] collection_factories = {}
    ) throws JsonError {
        try {
            return yield real_worker.deserialize_dict_async<T> (collection_factories);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    /**
     * Asynchronous version of method {@link deserialize_dict_into}
     *
     * @param dict                  Dict
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws JsonError    Error with json string
     */
    [Version (since = "6.0")]
    public async void deserialize_dict_into_async (
        Dict dict,
        CollectionFactory[] collection_factories = {}
    ) throws JsonError {
        try {
            yield real_worker.deserialize_dict_into_async (dict, collection_factories);
        } catch (Serialize.Error e) {
            throw convert_error (e);
        }
    }

    static JsonError convert_error (Serialize.Error e) {
        switch (e.code) {
            case Serialize.Error.EMPTY:
                return new JsonError.EMPTY (e.message);
            case Serialize.Error.INVALID:
                return new JsonError.INVALID (e.message);
            case Serialize.Error.NO_MEMBER:
                return new JsonError.NO_MEMBER (e.message);
            case Serialize.Error.WRONG_TYPE:
                return new JsonError.WRONG_TYPE (e.message);
            default:
                assert_not_reached ();
        }
    }
}
