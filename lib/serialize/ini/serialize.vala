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

namespace Serialize.IniSerializeSync {

    string serialize (
        Object obj,
        Serialize.Settings? settings
    ) {
        Serialize.Settings? real_settings = settings;
        if (real_settings == null) {
            real_settings = Serialize.get_settings ();
        }

        var keyfile = new KeyFile ();
        keyfile.set_list_separator (real_settings.ini_list_separator);

        serialize_object (keyfile, obj, null, real_settings);

        var res = keyfile.to_data ();

        debug (
            "Ini serialize complete:\n%s",
            res
        );

        return res;
    }

    //  If group_name if null, we in root and all props MUST be an objects
    void serialize_object (
        KeyFile keyfile,
        Object? obj,
        string? group_name,
        Serialize.Settings settings
    ) {
        if (obj == null) {
            return;
        }

        var cls = (ObjectClass) obj.get_type ().class_ref ();

        foreach (ParamSpec property in cls.list_properties ()) {
            if (!(READABLE in property.flags) ||
                !(WRITABLE in property.flags) ||
                (obj is HasFallback && property.name == HasFallback.FALLBACK_PROPERTY_NAME)) {
                continue;
            }

            if (group_name == null) {
                if (!property.value_type.is_object ()) {
                    error ("Can't serialize root object with non object property type");
                }
            }

            var prop_val = Value (property.value_type);
            var prop_name = property.get_nick ();
            obj.get_property (property.name, ref prop_val);

            if (settings.ignore_default && property.value_defaults (prop_val)) {
                continue;
            }

            if (group_name == null) {
                serialize_object (
                    keyfile,
                    prop_val.get_object (),
                    Convert.kebab2any (prop_name, settings.ini_group_names_case),
                    settings
                );

            } else {
                serialize_value (
                    keyfile,
                    group_name,
                    Convert.kebab2any (prop_name, settings.names_case),
                    prop_val,
                    settings
                );
            }
        }
    }

    void serialize_value (
        KeyFile keyfile,
        string group_name,
        string key,
        Value? prop_val,
        Settings settings
    ) {
        if (prop_val == null) {
            return;
        }

        assert (!prop_val.type ().is_object ());

        switch (prop_val.type ()) {
            case Type.INT:
                keyfile.set_integer (group_name, key, prop_val.get_int ());
                break;

            case Type.INT64:
                keyfile.set_int64 (group_name, key, prop_val.get_int64 ());
                break;

            case Type.DOUBLE:
                keyfile.set_double (group_name, key, prop_val.get_double ());
                break;

            case Type.STRING:
                keyfile.set_string (group_name, key, prop_val.get_string ());
                break;

            case Type.BOOLEAN:
                keyfile.set_boolean (group_name, key, prop_val.get_boolean ());
                break;

            case Type.NONE:
                break;

            default:
                // Get actual type if value is object
                var val_type = prop_val.type ();

                if (val_type.is_enum ()) {
                    switch (settings.enum_serialize_method) {
                        case INT:
                            keyfile.set_integer (group_name, key, prop_val.get_enum ());
                            break;
                        case STRING:
                            keyfile.set_string (
                                group_name,
                                key,
                                Enum.get_nick_gtype (val_type, prop_val.get_enum (), settings.enum_serialize_case)
                            );
                            break;
                    }

                } else if (val_type == typeof (DateTime)) {
                    switch (settings.date_time_serialize_method) {
                        case ISO8601:
                            keyfile.set_string (group_name, key, ((DateTime) prop_val.get_boxed ()).format_iso8601 ());
                            break;
                        case UNIX:
                            keyfile.set_int64 (group_name, key, ((DateTime) prop_val.get_boxed ()).to_unix ());
                            break;
                    }

                } else if (val_type == typeof (string[])) {
                    var arr_pointer = prop_val.get_boxed ();
                    char **arr = (char **) arr_pointer;

                    if (arr == null) {
                        keyfile.set_string_list (group_name, key, {});
                    } else {
                        var builder = new StrvBuilder ();
                        for (int i = 0; arr[i] != null; i++) {
                            builder.add ((string) arr[i]);
                        }
                        keyfile.set_string_list (group_name, key, builder.end ());
                    }

                } else if (val_type == typeof (Array)) {
                    var array = (Array) prop_val.get_object ();
                    switch (array.element_type) {
                        case Type.STRING:
                            keyfile.set_string_list (group_name, key, ((Array<string>) array).to_array ());
                            break;
                        case Type.INT:
                            keyfile.set_integer_list (group_name, key, ((Array<int>) array).to_array ());
                            break;
                        default:
                            error ("Unsupported type '%s' for array in ini", array.element_type.name ());
                    }

                } else {
                    warning ("Unknown type for serialize - %s (%s)", prop_val.type ().name (), val_type.name ());
                }

                break;
        }
    }
}
