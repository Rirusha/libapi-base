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
        Case names_case = Case.AUTO,
        bool pretty = false,
        bool ignore_default = false
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        var builder = new Json.Builder ();

        if (obj is Dict) {
            var dict = (Dict) obj;
            serialize_dict (builder, dict, dict.value_type, names_case, ignore_default);
        } else if (obj is Array) {
            var arr = (Array) obj;
            serialize_array (builder, arr, arr.element_type, names_case, ignore_default);
        } else {
            serialize_object (builder, obj, names_case, ignore_default);
        }

        var res = Json.to_string (builder.get_root (), pretty);

        debug (
            "Jsoner serialize complete:\n%s",
            res
        );

        return res;
    }

    static void serialize_array (
        Json.Builder builder,
        Array array_list,
        Type element_type,
        Case names_case = Case.AUTO,
        bool ignore_default = false
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        builder.begin_array ();

        if (element_type == typeof (Array)) {
            var array_of_arrays = (Array<Array>) array_list;

            foreach (var sub_array_list in array_of_arrays) {
                serialize_array (builder, sub_array_list, sub_array_list.element_type, names_case, ignore_default);
            }

        } else if (element_type == typeof (Dict)) {
            var array_of_maps = (Array<Dict>) array_list;

            foreach (var sub_hash_map in array_of_maps) {
                serialize_dict (builder, sub_hash_map, sub_hash_map.element_type, names_case, ignore_default);
            }

        } else if (element_type.is_object ()) {
            foreach (var obj in (Array<Object>) array_list) {
                serialize_object (builder, obj, names_case, ignore_default);
            }

        } else if (element_type == typeof (Value?)) {
            foreach (var val in (Array<Value?>) array_list) {
                serialize_value (builder, val);
            }

        } else {
            array_list.foreach_base ((fval) => {
                serialize_value (builder, fval);
            });
        }
        builder.end_array ();
    }

    static void serialize_dict (
        Json.Builder builder,
        Dict dict,
        Type element_type,
        Case names_case = Case.AUTO,
        bool ignore_default = false
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        builder.begin_object ();

        if (element_type == typeof (Array)) {
            var dict_of_arrays = (Dict<Array>) dict;

            foreach (var sub_array_list in dict_of_arrays) {
                builder.set_member_name (sub_array_list.key);
                serialize_array (builder, sub_array_list.value, sub_array_list.value.element_type, names_case, ignore_default);
            }

        } else if (element_type == typeof (Dict)) {
            var dict_of_dicts = (Dict<Dict>) dict;

            foreach (var sub_dict in dict_of_dicts) {
                builder.set_member_name (sub_dict.key);
                serialize_dict (builder, sub_dict.value, sub_dict.value.element_type, names_case, ignore_default);
            }

        } else if (element_type.is_object ()) {
            foreach (var entry in (Dict<Object>) dict) {
                builder.set_member_name (entry.key);
                serialize_object (builder, entry.value, names_case, ignore_default);
            }

        } else if (element_type == typeof (Value?)) {
            foreach (var entry in (Dict<Value?>) dict) {
                builder.set_member_name (entry.key);
                serialize_value (builder, entry.value);
            }

        } else {
            dict.foreach_base ((key, fval) => {
                builder.set_member_name (key);
                serialize_value (builder, fval);
            });
        }
        builder.end_object ();
    }

    static void serialize_object (
        Json.Builder builder,
        Object? api_obj,
        Case names_case = Case.AUTO,
        bool ignore_default = false
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

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

            var prop_val = Value (property.value_type);
            var prop_name = property.get_nick ();
            api_obj.get_property (property.name, ref prop_val);

            if (ignore_default && property.value_defaults (prop_val)) {
                continue;
            }

            builder.set_member_name (Convert.kebab2any (prop_name, names_case));

            if (property.value_type == typeof (Array)) {
                var array_list = (Array) prop_val.get_object ();
                Type element_type = array_list.element_type;

                serialize_array (builder, array_list, element_type, names_case, ignore_default);

            } else if (property.value_type == typeof (Dict)) {
                var hash_map = (Dict) prop_val.get_object ();
                Type element_type = hash_map.value_type;

                serialize_dict (builder, hash_map, element_type, names_case, ignore_default);

            } else if (property.value_type.is_object ()) {
                serialize_object (builder, (Object) prop_val.get_object (), names_case, ignore_default);

            } else {
                serialize_value (builder, prop_val);
            }
        }

        builder.end_object ();
    }

    static void serialize_value (Json.Builder builder, Value prop_val) {
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
                if (prop_val.holds (Type.ENUM)) {
                    builder.add_int_value (prop_val.get_enum ());

                } else if (prop_val.holds (typeof (DateTime))) {
                    builder.add_string_value (((DateTime) prop_val.get_boxed ()).format_iso8601 ());

                } else {
                    warning ("Unknown type for serialize - %s", prop_val.type ().name ());
                }

                break;
        }
    }
}
