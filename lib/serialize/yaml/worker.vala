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
 * YAML helper for de/serialization
 *
 * Uses libyaml to parse and emit YAML data directly.
 * Uses the event-based API (yaml_parser_parse / yaml_emitter_emit)
 * to avoid the memory management issues of yaml_document_t.
 */
[Version (since = "7.8")]
public sealed class Serialize.YamlWorker : Worker, ArraySupport, DictSupport, ValueSupport {

    //  Root value parsed from YAML input
    Serialize.YamlValue? _root_value;

    //  Visited nodes during deserialization to prevent infinite recursion
    //  from circular YAML aliases
    internal Gee.HashSet<Serialize.YamlValue> _deserialize_visited = new Gee.HashSet<Serialize.YamlValue> (null, null);

    internal Serialize.YamlValue? get_root_value () {
        return _root_value;
    }

    /**
     * Performs initialization for deserialization. Accepts a yaml string.
     *
     * @param yaml_string   Correct yaml string
     * @param sub_members   An array of names of yaml elements that need to be traversed
     *                      to the target node
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public YamlWorker (
        string yaml_string,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        if (yaml_string.length < 1) {
            throw new Serialize.Error.EMPTY ("Yaml string is empty");
        }

        var parser = Yaml.Parser ();
        var input = (uint8[]) yaml_string.data;
        parser.set_input_string (input);

        //  Parse events and build internal tree
        //  Use a local variable because self is NULL before Object() is called
        var root = parse_document (ref parser);

        if (root == null) {
            throw new Serialize.Error.EMPTY ("Yaml string is empty");
        }

        if (sub_members != null) {
            root = steps (root, sub_members);
        }

        debug (
            "YamlWorker initted for deserialize with:\n%s",
            yaml_string
        );

        Object (
            settings: settings == null ? get_settings () : settings
        );

        _root_value = root;
    }

    /**
     * Performs initialization for deserialization. Accepts a yaml string in the
     * form of bytes, the object {@link GLib.Bytes}.
     *
     * @param bytes         Yaml string in the form of bytes, the object {@link GLib.Bytes}
     * @param sub_members   An array of names of yaml elements that need to be traversed to the target node
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public YamlWorker.from_bytes (
        Bytes bytes,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        if (bytes.length == 0) {
            throw new Serialize.Error.EMPTY ("Yaml string is empty");
        }

        this.from_data (bytes.get_data (), sub_members, settings);
    }

    /**
     * Performs initialization for deserialization. Accepts a yaml string in the form of bytes,
     * an {@link uint8} array.
     *
     * @param data          Yaml string in the form of bytes, {@link uint8} array
     * @param sub_members   An array of names of yaml elements that need to be traversed to the target node
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public YamlWorker.from_data (
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

    static Serialize.YamlValue? steps (
        Serialize.YamlValue node,
        string[] sub_members
    ) throws Serialize.Error {
        var members_trace = new GLib.Array<string> ();
        Serialize.YamlValue? current = node;

        foreach (string member_name in sub_members) {
            members_trace.append_val (member_name);

            if (current == null || current.node_type != Yaml.NodeType.MAPPING) {
                throw new Serialize.Error.NO_MEMBER ("Yaml has no %s".printf (string.joinv ("-", members_trace.data)));
            }

            bool found = false;
            foreach (var pair in current.mapping_pairs) {
                if (pair.key.node_type == Yaml.NodeType.SCALAR && pair.key.scalar == member_name) {
                    current = pair.value;
                    found = true;
                    break;
                }
            }

            if (!found) {
                throw new Serialize.Error.NO_MEMBER ("Yaml has no %s".printf (string.joinv ("-", members_trace.data)));
            }
        }

        return current;
    }

    /**
     * Parse a YAML document from events into our internal tree.
     *
     * @param parser  An initialized YAML parser.
     *
     * @return The root value, or null if the document is empty.
     *
     * @throws Serialize.Error  On parse error.
     */
    static Serialize.YamlValue? parse_document (ref Yaml.Parser parser) throws Serialize.Error {
        //  Expect STREAM_START
        {
            Yaml.Event event = {};
            if (parser.parse (out event) == 0) {
                throw parse_error (ref parser);
            }
            if (event.type != Yaml.EventType.STREAM_START) {
                throw new Serialize.Error.INVALID ("Expected STREAM_START event");
            }
            //  event goes out of scope here, yaml_event_delete is called
        }

        //  Expect DOCUMENT_START
        {
            Yaml.Event event = {};
            if (parser.parse (out event) == 0) {
                throw parse_error (ref parser);
            }
            if (event.type != Yaml.EventType.DOCUMENT_START) {
                throw new Serialize.Error.INVALID ("Expected DOCUMENT_START event");
            }
            //  event goes out of scope here, yaml_event_delete is called
        }

        //  Parse the root node
        var anchor_map = new Gee.HashMap<string, Serialize.YamlValue> (null, null);
        Serialize.YamlValue? root = parse_node (ref parser, anchor_map);

        //  Expect DOCUMENT_END
        {
            Yaml.Event event = {};
            if (parser.parse (out event) == 0) {
                throw parse_error (ref parser);
            }
            if (event.type != Yaml.EventType.DOCUMENT_END) {
                throw new Serialize.Error.INVALID ("Expected DOCUMENT_END event");
            }
            //  event goes out of scope here, yaml_event_delete is called
        }

        //  Expect STREAM_END
        {
            Yaml.Event event = {};
            if (parser.parse (out event) == 0) {
                throw parse_error (ref parser);
            }
            if (event.type != Yaml.EventType.STREAM_END) {
                throw new Serialize.Error.INVALID ("Expected STREAM_END event");
            }
            //  event goes out of scope here, yaml_event_delete is called
        }

        return root;
    }

    /**
     * Parse a single YAML node from events.
     *
     * Extracts all needed data from the event inside a scope block,
     * then processes the data after the event has been cleaned up.
     * This avoids issues with Vala's destroy_function on the Event struct.
     *
     * @param parser  The YAML parser.
     *
     * @return The parsed value, or null for empty.
     *
     * @throws Serialize.Error  On parse error.
     */
    static Serialize.YamlValue? parse_node (
        ref Yaml.Parser parser,
        Gee.HashMap<string, Serialize.YamlValue> anchor_map
    ) throws Serialize.Error {
        Serialize.YamlValue? result = null;

        //  Extract event data in its own scope
        Yaml.EventType etype;
        string? scalar_value = null;
        string? anchor = null;
        {
            Yaml.Event event = {};
            if (parser.parse (out event) == 0) {
                throw parse_error (ref parser);
            }

            etype = event.type;

            if (etype == Yaml.EventType.SCALAR) {
                scalar_value = event.data_scalar_value.dup ();
                if (event.data_scalar_anchor != null) {
                    anchor = event.data_scalar_anchor.dup ();
                }
            } else if (etype == Yaml.EventType.ALIAS) {
                if (event.data_alias_anchor != null) {
                    anchor = event.data_alias_anchor.dup ();
                }
            } else if (etype == Yaml.EventType.SEQUENCE_START) {
                if (event.data_sequence_start_anchor != null) {
                    anchor = event.data_sequence_start_anchor.dup ();
                }
            } else if (etype == Yaml.EventType.MAPPING_START) {
                if (event.data_mapping_start_anchor != null) {
                    anchor = event.data_mapping_start_anchor.dup ();
                }
            }
            //  event goes out of scope here, yaml_event_delete is called once
        }

        //  Process based on type (event is already cleaned up)
        switch (etype) {
            case Yaml.EventType.SCALAR: {
                if (scalar_value == null ||
                    scalar_value == "" ||
                    scalar_value == "null" ||
                    scalar_value == "Null" ||
                    scalar_value == "NULL" ||
                    scalar_value == "~") {
                    result = new Serialize.YamlValue (Yaml.NodeType.NO);
                } else {
                    var val = new Serialize.YamlValue (Yaml.NodeType.SCALAR);
                    val.scalar = scalar_value;
                    result = val;
                }
                if (anchor != null) {
                    anchor_map[anchor] = result;
                }
                break;
            }

            case Yaml.EventType.ALIAS: {
                if (anchor != null && anchor_map.has_key (anchor)) {
                    result = anchor_map[anchor];
                } else {
                    throw new Serialize.Error.INVALID (
                        "Unknown YAML anchor: %s", anchor ?? "(null)"
                    );
                }
                break;
            }

            case Yaml.EventType.SEQUENCE_START: {
                var seq = new Serialize.YamlValue (Yaml.NodeType.SEQUENCE);

                if (anchor != null) {
                    anchor_map[anchor] = seq;
                }

                while (true) {
                    var item = parse_node (ref parser, anchor_map);
                    if (item == null) {
                        break;
                    }

                    seq.sequence_items.add (item);
                }

                result = seq;
                break;
            }

            case Yaml.EventType.MAPPING_START: {
                var map = new Serialize.YamlValue (Yaml.NodeType.MAPPING);

                if (anchor != null) {
                    anchor_map[anchor] = map;
                }

                while (true) {
                    var key = parse_node (ref parser, anchor_map);
                    if (key == null) {
                        break;
                    }

                    var value = parse_node (ref parser, anchor_map);
                    if (value == null) {
                        //  Key without value — add with null value
                        map.mapping_pairs.add (new Serialize.YamlPair (key, new Serialize.YamlValue (Yaml.NodeType.NO)));
                        break;
                    }

                    map.mapping_pairs.add (new Serialize.YamlPair (key, value));
                }

                result = map;
                break;
            }

            case Yaml.EventType.SEQUENCE_END:
            case Yaml.EventType.MAPPING_END:
                //  These are handled by the caller — return null to signal end
                result = null;
                break;

            default:
                throw new Serialize.Error.INVALID (
                    "Unexpected YAML event type: %d", (int) etype
                );
        }

        return result;
    }

    /**
     * Create a parse error from the parser's problem description.
     */
    static Serialize.Error parse_error (ref Yaml.Parser parser) {
        string? problem = parser.problem;
        return new Serialize.Error.INVALID (
            "YAML parse error: %s",
            problem ?? "unknown error"
        );
    }

    /**
     * Serialize {@link GLib.Object} into a correct yaml string
     *
     * @param obj               {@link GLib.Object}
     * @param settings          Settings
     *
     * @return                  Yaml string
     */
    [Version (since = "7.8")]
    public static inline string serialize (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        return YamlSerializeSync.serialize (obj, settings);
    }

    /**
     * {@link deserialize} without
     * manual {@link YamlWorker} instance creation
     *
     * @param yaml              Yaml string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public static inline Dict<Value?> simple_deserialize (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        var worker = new YamlWorker (yaml, sub_members, settings);
        return worker.deserialize ();
    }

    /**
     * Object creation method from yaml
     * via {@link YamlWorker.deserialize_object}
     * Simple version for fast deserialization without
     * manual {@link YamlWorker} instance creation
     *
     * @param yaml              Yaml string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public static inline T simple_from_yaml<T> (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        var worker = new YamlWorker (yaml, sub_members, settings);
        return worker.deserialize_object<T> ();
    }

    /**
     * Array creation method from yaml
     * via {@link YamlWorker.deserialize_array}
     * Simple version for fast deserialization without
     * manual {@link YamlWorker} instance creation
     *
     * @param yaml                  Yaml string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized array
     *
     * @throws Serialize.Error            Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public static inline Array<T> simple_array_from_yaml<T> (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        var worker = new YamlWorker (yaml, sub_members, settings);
        return worker.deserialize_array<T> (collection_hierarchy);
    }

    /**
     * Dict creation method from yaml
     * via {@link YamlWorker.deserialize_dict}
     * Simple version for fast deserialization without
     * manual {@link YamlWorker} instance creation
     *
     * @param yaml                  Yaml string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized dict
     *
     * @throws Serialize.Error            Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public static inline Dict<T> simple_dict_from_yaml<T> (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        var worker = new YamlWorker (yaml, sub_members, settings);
        return worker.deserialize_dict<T> (collection_hierarchy);
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.8")]
    public override inline Object deserialize_object_by_type (
        GLib.Type obj_type
    ) throws Serialize.Error {
        return YamlDeserializeSync.deserialize_object_by_type (this, obj_type);
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.8")]
    public override inline void deserialize_object_into (
        Object obj
    ) throws Serialize.Error {
        YamlDeserializeSync.deserialize_object_into (this, obj);
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.8")]
    public inline Value deserialize_value () throws Serialize.Error {
        return YamlDeserializeSync.deserialize_value (this);
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.8")]
    public inline void deserialize_array_into (
        Array array,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        YamlDeserializeSync.deserialize_array_into (this, array, collection_hierarchy);
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.8")]
    public inline void deserialize_dict_into (
        Dict dict,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        YamlDeserializeSync.deserialize_dict_into (this, dict, collection_hierarchy);
    }

    /**
     * Asynchronous version of method {@link serialize}
     */
    [Version (since = "7.8")]
    public static inline async string serialize_async (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        var thread = new Thread<string> (null, () => {
            var result = serialize (obj, settings);

            Idle.add (serialize_async.callback);
            return result;
        });

        yield;

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link simple_from_yaml}
     *
     * @param yaml              Yaml string
     * @param sub_members       Sub members to 'steps'
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public async static inline T simple_from_yaml_async<T> (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = simple_from_yaml<T> (
                    yaml,
                    sub_members,
                    settings
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_from_yaml_async.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }

    /**
     * Asynchronous version of method {@link simple_array_from_yaml}
     *
     * @param yaml                  Yaml string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized array
     *
     * @throws Serialize.Error            Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public async static inline Array<T> simple_array_from_yaml_async<T> (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Array<T>?> (null, () => {
            Array<T>? result = null;

            try {
                result = simple_array_from_yaml<T> (
                    yaml,
                    sub_members,
                    settings,
                    collection_hierarchy
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_array_from_yaml_async.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }

    /**
     * Asynchronous version of method {@link simple_dict_from_yaml}
     *
     * @param yaml                  Yaml string
     * @param sub_members           Sub members to 'steps'
     * @param settings              Settings
     * @param collection_hierarchy  Objects for creating collection
     *                              objects with generics
     *
     * @return                      Deserialized dict
     *
     * @throws Serialize.Error            Error with yaml or sub_members
     */
    [Version (since = "7.8")]
    public async static inline Dict<T> simple_dict_from_yaml_async<T> (
        string yaml,
        string[]? sub_members = null,
        Serialize.Settings? settings = null,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Dict<T>?> (null, () => {
            Dict<T>? result = null;

            try {
                result = simple_dict_from_yaml<T> (
                    yaml,
                    sub_members,
                    settings,
                    collection_hierarchy
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_dict_from_yaml_async.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }
}
