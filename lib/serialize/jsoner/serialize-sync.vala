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

namespace Serialize.JsonerSerializeSync {

    internal static string serialize (
        Object obj,
        Serialize.Settings? settings
    ) {
        Serialize.Settings? real_settings = settings;
        if (real_settings == null) {
            real_settings = Serialize.get_settings ();
        }

        var builder = new Json.Builder ();

        serialize_value (builder, obj, real_settings);

        var res = Json.to_string (builder.get_root (), real_settings.pretty);

        debug (
            "Jsoner serialize complete:\n%s",
            res
        );

        return res;
    }

    static void serialize_array (
        Json.Builder builder,
        Array array,
        Type element_type,
        Serialize.Settings settings
    ) {
        builder.begin_array ();

        array.foreach_base ((fval) => {
            serialize_value (builder, fval, settings);
        });

        builder.end_array ();
    }

    static void serialize_dict (
        Json.Builder builder,
        Dict dict,
        Type element_type,
        Serialize.Settings settings,
        bool new_object = true
    ) {
        if (new_object) {
            builder.begin_object ();
        }

        dict.foreach_base ((key, fval) => {
            builder.set_member_name (key);
            serialize_value (builder, fval, settings);
        });

        if (new_object) {
            builder.end_object ();
        }
    }

    static void serialize_object (
        Json.Builder builder,
        Object? obj,
        Serialize.Settings settings
    ) {
        if (obj == null) {
            builder.add_null_value ();

            return;
        }

        builder.begin_object ();
        var cls = (ObjectClass) obj.get_type ().class_ref ();

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

            builder.set_member_name (Convert.kebab2any (prop_name, settings.names_case));
            serialize_value (builder, prop_val, settings);
        }

        if (obj is HasFallback) {
            var fallback = (HasFallback) obj;
            serialize_dict (builder, fallback.serialize_fallback, typeof (Value?), settings, false);
        }

        builder.end_object ();
    }

    static void serialize_value (Json.Builder builder, Value? prop_val, Settings settings) {
        if (prop_val == null) {
            builder.add_null_value ();
            return;
        }

        switch (prop_val.type ()) {
            case Type.INT:
                builder.add_int_value ((int64) prop_val.get_int ());
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
                // Get actual type if value is object
                var val_type = prop_val.type ().is_object () ? prop_val.get_object ()?.get_type () ?? prop_val.type () : prop_val.type ();

                if (val_type.is_enum ()) {
                    switch (settings.enum_serialize_method) {
                        case INT:
                            builder.add_int_value (prop_val.get_enum ());
                            break;
                        case STRING:
                            builder.add_string_value (Enum.get_nick_gtype (val_type, prop_val.get_enum (), settings.enum_serialize_case));
                            break;
                    }

                } else if (val_type == typeof (DateTime)) {
                    switch (settings.date_time_serialize_method) {
                        case ISO8601:
                            builder.add_string_value (((DateTime) prop_val.get_boxed ()).format_iso8601 ());
                            break;
                        case UNIX:
                            builder.add_int_value (((DateTime) prop_val.get_boxed ()).to_unix ());
                            break;
                    }

                } else if (val_type == typeof (Dict)) {
                    var dict = (Dict) prop_val.get_object ();
                    serialize_dict (builder, dict, dict.element_type, settings);

                } else if (val_type == typeof (Array)) {
                    var array = (Array) prop_val.get_object ();
                    serialize_array (builder, array, array.element_type, settings);

                } else if (prop_val.type ().is_object ()) {
                    serialize_object (builder, prop_val.get_object (), settings);

                } else {
                    warning ("Unknown type for serialize - %s (%s)", prop_val.type ().name (), val_type.name ());
                }

                break;
        }
    }
}
