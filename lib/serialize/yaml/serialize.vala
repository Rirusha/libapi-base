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

namespace Serialize.YamlSerializeSync {

    string serialize (
        Object obj,
        Serialize.Settings? settings
    ) {
        Serialize.Settings? real_settings = settings;
        if (real_settings == null) {
            real_settings = Serialize.get_settings ();
        }

        var emitter = Yaml.Emitter ();
        emitter.set_unicode (1);
        emitter.set_indent (2);
        emitter.set_width (-1);

        //  Use a StringBuilder to collect output via write handler
        var sb = new StringBuilder ();

        emitter.set_output ((buffer) => {
            sb.append_len ((string) buffer, buffer.length);
            return 1;
        });

        //  Emit events directly, avoiding Yaml.Document entirely
        Yaml.Event event = {};

        //  STREAM_START
        event.stream_start_initialize (Yaml.Encoding.UTF8);
        if (emitter.emit (ref event) == 0) {
            error ("Failed to emit STREAM_START");
        }
        event.type = Yaml.EventType.NO;

        //  DOCUMENT_START (implicit)
        event.document_start_initialize (null, null, null, 1);
        if (emitter.emit (ref event) == 0) {
            error ("Failed to emit DOCUMENT_START");
        }
        event.type = Yaml.EventType.NO;

        //  Root object as mapping
        if (obj is Dict) {
            var dict = (Dict) obj;
            emit_mapping_start (&emitter);
            emit_dict_into_mapping (&emitter, dict, real_settings);
            emit_mapping_end (&emitter);
        } else if (obj is Array) {
            var array = (Array) obj;
            emit_array (&emitter, array, real_settings);
        } else {
            emit_object (&emitter, obj, real_settings);
        }

        //  DOCUMENT_END (implicit)
        event.document_end_initialize (1);
        if (emitter.emit (ref event) == 0) {
            error ("Failed to emit DOCUMENT_END");
        }
        event.type = Yaml.EventType.NO;

        //  STREAM_END
        event.stream_end_initialize ();
        if (emitter.emit (ref event) == 0) {
            error ("Failed to emit STREAM_END");
        }
        event.type = Yaml.EventType.NO;

        if (emitter.flush () == 0) {
            error ("Failed to flush emitter");
        }

        var res = sb.str;

        debug (
            "Yaml serialize complete:\n%s",
            res
        );

        return res;
    }

    void emit_object (
        Yaml.Emitter* emitter,
        Object? obj,
        Serialize.Settings settings
    ) {
        if (obj == null) {
            emit_scalar (emitter, "null");
            return;
        }

        var cls = (ObjectClass) obj.get_type ().class_ref ();

        //  MAPPING_START
        Yaml.Event event = {};
        event.mapping_start_initialize (null, null, 1, Yaml.MappingStyle.ANY);
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit MAPPING_START");
        }
        event.type = Yaml.EventType.NO;

        foreach (ParamSpec property in cls.list_properties ()) {
            if (!(READABLE in property.flags) ||
                !(WRITABLE in property.flags) ||
                (obj is HasFallback && property.name == HasFallback.FALLBACK_PROPERTY_NAME)) {
                continue;
            }

            var prop_val = Value (property.value_type);
            var prop_name = property.get_nick ();
            obj.get_property (property.name, ref prop_val);

            if (settings.ignore_default && property.value_defaults (prop_val)) {
                continue;
            }

            //  Emit key scalar
            emit_scalar (emitter, Convert.kebab2any (prop_name, settings.names_case));

            //  Emit value
            emit_value (emitter, prop_val, settings);
        }

        if (obj is HasFallback) {
            var fallback = (HasFallback) obj;
            var fallback_dict = fallback.serialize_fallback;
            if (fallback_dict != null) {
                emit_dict_into_mapping (emitter, fallback_dict, settings);
            }
        }

        //  MAPPING_END
        event.mapping_end_initialize ();
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit MAPPING_END");
        }
        event.type = Yaml.EventType.NO;
    }

    void emit_value (
        Yaml.Emitter* emitter,
        Value? prop_val,
        Settings settings
    ) {
        if (prop_val == null) {
            emit_scalar (emitter, "null");
            return;
        }

        switch (prop_val.type ()) {
            case Type.INT:
                emit_scalar (emitter, prop_val.get_int ().to_string ());
                break;

            case Type.INT64:
                emit_scalar (emitter, prop_val.get_int64 ().to_string ());
                break;

            case Type.DOUBLE:
                emit_scalar (emitter, "%.15g".printf (prop_val.get_double ()));
                break;

            case Type.STRING:
                var str = prop_val.get_string ();
                emit_scalar (emitter, str ?? "null");
                break;

            case Type.BOOLEAN:
                emit_scalar (emitter, prop_val.get_boolean ().to_string ());
                break;

            case Type.NONE:
                emit_scalar (emitter, "null");
                break;

            default:
                //  Get actual type if value is object
                var val_type = prop_val.type ().is_object () ?
                    prop_val.get_object ()?.get_type () ?? prop_val.type () :
                    prop_val.type ();

                if (val_type.is_enum ()) {
                    switch (settings.enum_serialize_method) {
                        case INT:
                            emit_scalar (emitter, prop_val.get_enum ().to_string ());
                            break;
                        case STRING:
                            var enum_str = Enum.get_nick_gtype (val_type, prop_val.get_enum (), settings.enum_serialize_case);
                            emit_scalar (emitter, enum_str);
                            break;
                    }

                } else if (val_type == typeof (DateTime)) {
                    switch (settings.date_time_serialize_method) {
                        case ISO8601:
                            var dt_str = ((DateTime) prop_val.get_boxed ()).format_iso8601 ();
                            emit_scalar (emitter, dt_str);
                            break;
                        case UNIX:
                            var unix_str = ((DateTime) prop_val.get_boxed ()).to_unix ().to_string ();
                            emit_scalar (emitter, unix_str);
                            break;
                    }

                } else if (val_type == typeof (string[])) {
                    var arr_pointer = prop_val.get_boxed ();
                    char **arr = (char **) arr_pointer;

                    emit_sequence_start (emitter);
                    if (arr != null) {
                        for (int i = 0; arr[i] != null; i++) {
                            emit_scalar (emitter, (string) arr[i]);
                        }
                    }
                    emit_sequence_end (emitter);

                } else if (prop_val.type ().is_a (typeof (Array))) {
                    var array = (Array) prop_val.get_object ();
                    emit_array (emitter, array, settings);

                } else if (prop_val.type ().is_a (typeof (Dict))) {
                    var dict = (Dict) prop_val.get_object ();
                    emit_mapping_start (emitter);
                    emit_dict_into_mapping (emitter, dict, settings);
                    emit_mapping_end (emitter);

                } else if (prop_val.type ().is_object ()) {
                    var obj = prop_val.get_object ();
                    if (obj == null) {
                        emit_scalar (emitter, "null");
                    } else {
                        emit_object (emitter, obj, settings);
                    }

                } else {
                    warning ("Unknown type for serialize - %s (%s)", prop_val.type ().name (), val_type.name ());
                    emit_scalar (emitter, "");
                }

                break;
        }
    }

    void emit_array (
        Yaml.Emitter* emitter,
        Array array,
        Serialize.Settings settings
    ) {
        emit_sequence_start (emitter);

        array.foreach_base ((val) => {
            emit_value (emitter, val, settings);
        });

        emit_sequence_end (emitter);
    }

    void emit_dict_into_mapping (
        Yaml.Emitter* emitter,
        Dict dict,
        Serialize.Settings settings
    ) {
        dict.foreach_base ((key, val) => {
            emit_scalar (emitter, key);
            emit_value (emitter, val, settings);
        });
    }

    void emit_scalar (
        Yaml.Emitter* emitter,
        string value
    ) {
        Yaml.Event event = {};
        event.scalar_initialize (null, null, value, (int) value.length, 1, 1, Yaml.ScalarStyle.ANY);
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit SCALAR: %s", value);
        }
        event.type = Yaml.EventType.NO;
    }

    void emit_sequence_start (
        Yaml.Emitter* emitter
    ) {
        Yaml.Event event = {};
        event.sequence_start_initialize (null, null, 1, Yaml.SequenceStyle.ANY);
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit SEQUENCE_START");
        }
        event.type = Yaml.EventType.NO;
    }

    void emit_sequence_end (
        Yaml.Emitter* emitter
    ) {
        Yaml.Event event = {};
        event.sequence_end_initialize ();
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit SEQUENCE_END");
        }
        event.type = Yaml.EventType.NO;
    }

    void emit_mapping_start (
        Yaml.Emitter* emitter
    ) {
        Yaml.Event event = {};
        event.mapping_start_initialize (null, null, 1, Yaml.MappingStyle.ANY);
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit MAPPING_START");
        }
        event.type = Yaml.EventType.NO;
    }

    void emit_mapping_end (
        Yaml.Emitter* emitter
    ) {
        Yaml.Event event = {};
        event.mapping_end_initialize ();
        if (emitter->emit (ref event) == 0) {
            error ("Failed to emit MAPPING_END");
        }
        event.type = Yaml.EventType.NO;
    }
}
