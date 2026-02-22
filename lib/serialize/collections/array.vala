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

public class Serialize.Array<T> : Gee.ArrayList<T>, CollectionFactory<T> {

    public Array (owned Gee.EqualDataFunc<G>? equal_func = null) {
        base (equal_func);
    }

    /**
     * Create new empty Array
     */
    public CollectionFactory<T> build () {
        return new Array<T> (equal_func);
    }

    [NoReturn]
    internal inline void print_type_warning (Type actual_type) {
        warning ("Array: expected '%s' value type, got '%s'", element_type.name (), actual_type.name ());
    }

    //  element_type must be an {@link Object} type
    internal inline void add_object (Object obj) {
        ((Array<Object>) this).add (obj);
    }

    //  element_type must be an {@link Array} type
    internal inline void add_array (Array array) {
        ((Array<Array>) this).add (array);
    }

    //  element_type must be an {@link Dict} type
    internal inline void add_dict (Dict dict) {
        ((Array<Dict>) this).add (dict);
    }

    internal inline void add_base (owned Value value) {
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
                ((Array<string>) this).add (nval.get_string ());
                break;

            case Type.INT:
                ((Array<int>) this).add (nval.get_int ());
                break;

            case Type.INT64:
                ((Array<int64?>) this).add (nval.get_int64 ());
                break;

            case Type.DOUBLE:
                ((Array<double?>) this).add (nval.get_double ());
                break;

            case Type.BOOLEAN:
                ((Array<bool>) this).add (nval.get_boolean ());
                break;

            case Type.NONE:
                add (null);
                break;

            default:
                if (nval.holds (typeof (DateTime))) {
                    ((Array<DateTime?>) this).add ((DateTime) nval.get_boxed ());

                } else if (nval.holds (Type.ENUM)) {
                    add (nval.get_enum ());
                }
                break;
        }
    }

    internal void foreach_base (ArrayForeachBaseFunc foreach_func) {
        var val = Value (element_type);

        foreach (var v in this) {
            switch (element_type) {
                case Type.STRING:
                    val.set_string ((string) v);
                    break;

                case Type.INT:
                    val.set_int ((int) v);
                    break;

                case Type.INT64:
                    val.set_int64 ((int64?) v);
                    break;

                case Type.DOUBLE:
                    val.set_double ((double?) v);
                    break;

                case Type.BOOLEAN:
                    val.set_boolean ((bool) v);
                    break;

                case Type.NONE:
                    break;

                default:
                    if (element_type == typeof (DateTime)) {
                        val.set_boxed ((DateTime?) v);

                    } else if (element_type.is_enum ()) {
                        val.set_enum ((int) v);
                    }
                    break;
            }

            foreach_func (val);
        }
    }

    //  TODO: doc
    //  Also check types and print warning
    public void add_value (Value value) {
        if (element_type == typeof (Array)) {
            if (value.type () != typeof (Array)) {
                print_type_warning (value.type ());
            }
            add_array ((Array) value.get_object ());

        } else if (element_type == typeof (Dict)) {
            if (value.type () != typeof (Dict)) {
                print_type_warning (value.type ());
            }
            add_dict ((Dict) value.get_object ());

        } else if (element_type.is_object ()) {
            add_object (value.get_object ());

        } else if (element_type in SUPPORTED_BASE_TYPES || element_type == typeof (DateTime) || element_type.is_enum ()) {
            add_base (value);
        }
    }
}
