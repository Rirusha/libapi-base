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
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Serialize.Dict<T> : Gee.HashMap<string, T>, CollectionFactory<T> {

    public Dict (owned Gee.EqualDataFunc<V>? value_equal_func = null) {
        base (null, null, value_equal_func);
    }

    /**
     * Create new empty Dict
     */
    public CollectionFactory<T> build () {
        return new Dict<T> (value_equal_func);
    }

    [NoReturn]
    internal inline void print_type_warning (Type actual_type) {
        warning ("Dict: expected '%s' value type, got '%s'", element_type.name (), actual_type.name ());
    }

    //  element_type must be an {@link Object} type
    internal inline void set_object (string key, Object obj) {
        ((Dict<Object>) this).set (key, obj);
    }

    //  element_type must be an {@link Array} type
    internal inline void set_array (string key, Array array) {
        ((Dict<Array>) this).set (key, array);
    }

    //  element_type must be an {@link Dict} type
    internal inline void set_dict (string key, Dict dict) {
        ((Dict<Dict>) this).set (key, dict);
    }

    internal inline void set_base (string key, owned Value value) {
        Value nval;

        if (element_type != value.type ()) {
            nval = Value (element_type);
            if (!Convert.value2value (ref value, ref nval)) {
                return;
            }

        } else {
            nval = value;
        }

        switch (nval.type ()) {
            case Type.STRING:
                ((Dict<string>) this).set (key, nval.get_string ());
                break;

            case Type.INT:
                ((Dict<int>) this).set (key, nval.get_int ());
                break;

            case Type.INT64:
                ((Dict<int64?>) this).set (key, nval.get_int64 ());
                break;

            case Type.DOUBLE:
                ((Dict<double?>) this).set (key, nval.get_double ());
                break;

            case Type.BOOLEAN:
                ((Dict<bool>) this).set (key, nval.get_boolean ());
                break;

            case Type.ENUM:
                @set (key, nval.get_enum ());
                break;

            case Type.NONE:
                @set (key, null);
                break;

            default:
                if (nval.holds (typeof (DateTime))) {
                    ((Dict<DateTime?>) this).set (key, (DateTime) nval.get_boxed ());
                }
                break;
        }
    }

    //  TODO: doc
    //  Also check types and print warning
    public void set_value (string key, Value value) {
        if (element_type == typeof (Array)) {
            if (value.type () != typeof (Array)) {
                print_type_warning (value.type ());
            }
            set_array (key, (Array) value.get_object ());

        } else if (element_type == typeof (Dict)) {
            if (value.type () != typeof (Dict)) {
                print_type_warning (value.type ());
            }
            set_dict (key, (Dict) value.get_object ());

        } else if (element_type.is_object ()) {
            set_object (key, value.get_object ());

        } else if (element_type in SUPPORTED_BASE_TYPES || element_type == typeof (DateTime) || element_type.is_enum ()) {
            set_base (key, value);
        }
    }
}
