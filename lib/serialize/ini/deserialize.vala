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

namespace Serialize.IniDeserializeSync {

    Object deserialize_object_by_type (
        IniWorker self,
        GLib.Type obj_type,
        string? group_name = null
    ) throws Serialize.Error {
        var obj = Object.new (obj_type);
        if (obj_type.is_a (typeof (TypeFamily))) {
            warning ("TypeFamily interface doesn't supported for ini");
        }

        deserialize_object_into (self, obj, group_name);

        return obj;
    }

    void deserialize_object_into (
        IniWorker self,
        Object obj,
        string? group_name = null
    ) throws Serialize.Error {
        obj.freeze_notify ();

        var obj_type = obj.get_type ();
        var class_ref = (ObjectClass) obj_type.class_ref ();
        ParamSpec[] properties = class_ref.list_properties ();

        var props_data = new Dict<ParamSpec> ();
        foreach (ParamSpec property in properties) {
            if ((property.flags & ParamFlags.WRITABLE) == 0) {
                continue;
            }

            if (group_name == null && !property.value_type.is_object ()) {
                error ("Can't deserialize ini root object with non object property type");
            }

            var prop_name = property.get_nick ();

            if (props_data.has_key (prop_name)) {
                warning ("Detected property collision: %s in '%s' object", prop_name, obj_type.name ());
            }
            props_data[prop_name] = property;
        }

        var unknown_fields = new Array<string> ();

        string[] members = {};

        if (group_name == null) {
            members = self.keyfile.get_groups ();
        } else {
            try {
                members = self.keyfile.get_keys (group_name);
            } catch (GLib.Error e) {
                error ("Can't get keys from keyfile");
            }
        }

        Case members_names_case = group_name == null ? self.settings.ini_group_names_case : self.settings.names_case;

        if (Environment.get_variable ("SERIALIZE_UNKNOWN_PROPS") != null) {
            var kebabbed_members = new Gee.HashSet<string> ();
            foreach (var member_name in members) {
                kebabbed_members.add (Convert.cany2kebab (member_name, members_names_case));
            }

            foreach (var prop_name in props_data.keys) {
                if (!(prop_name in kebabbed_members)) {
                    warning (
                        "The ini object does not have field '%s' that present in '%s' as property",
                        prop_name,
                        obj_type.name ()
                    );
                }
            }
        }

        foreach (var member_name in members) {
            var kebabbed_member_name = Convert.cany2kebab (member_name, members_names_case);

            if (!props_data.has_key (kebabbed_member_name)) {
                if (Environment.get_variable ("SERIALIZE_UNKNOWN_FIELDS") != null) {
                    warning (
                        "The object '%s' does not have a property '%s' corresponding to the ini field '%s'",  // vala-lint=line-length
                        obj_type.name (),
                        kebabbed_member_name,
                        member_name
                    );
                }

                unknown_fields.add (member_name);
                continue;
            }

            var property = props_data[kebabbed_member_name];

            Type prop_type = property.value_type;

            if (prop_type.is_object () && group_name == null) {
                obj.set_property (
                    property.name,
                    deserialize_object_by_type (self, prop_type, member_name)
                );

            } else {
                var val = Value (prop_type);
                deserialize_value (self, group_name, member_name, ref val);
                obj.set_property (property.name, val);
            }
        }
        obj.thaw_notify ();
    }

    void deserialize_value (
        IniWorker self,
        string group_name,
        string key,
        ref Value prop_val
    ) throws Serialize.Error {
        try {
            switch (prop_val.type ()) {
                case Type.INT:
                    prop_val.set_int (self.keyfile.get_integer (group_name, key));
                    break;

                case Type.INT64:
                    prop_val.set_int64 (self.keyfile.get_int64 (group_name, key));
                    break;

                case Type.DOUBLE:
                    prop_val.set_double (self.keyfile.get_double (group_name, key));
                    break;

                case Type.STRING:
                    prop_val.set_string (self.keyfile.get_string (group_name, key));
                    break;

                case Type.BOOLEAN:
                    prop_val.set_boolean (self.keyfile.get_boolean (group_name, key));
                    break;

                case Type.NONE:
                    break;

                default:
                    // Get actual type if value is object
                    var val_type = prop_val.type ();

                    if (val_type.is_enum ()) {
                        switch (self.settings.enum_serialize_method) {
                            case INT:
                                prop_val.set_enum (self.keyfile.get_integer (group_name, key));
                                break;
                            case STRING:
                                prop_val.set_enum (
                                    Enum.get_by_nick_gtype (val_type, self.keyfile.get_string (group_name, key))
                                );
                                break;
                        }

                    } else if (val_type == typeof (DateTime)) {
                        var dt = new DateTime.from_iso8601 (
                            self.keyfile.get_string (group_name, key), new TimeZone.utc ()
                        );
                        if (dt != null) {
                            prop_val.set_boxed (dt);
                        } else {
                            int64 res;
                            if (int64.try_parse (self.keyfile.get_string (group_name, key), out res)) {
                                dt = new DateTime.from_unix_utc (res);
                                if (dt != null) {
                                    prop_val.set_boxed (dt);
                                }
                            }
                        }

                    } else if (val_type == typeof (string[])) {
                        prop_val.set_boxed (self.keyfile.get_string_list (group_name, key));

                    } else if (val_type == typeof (Array)) {
                        var array = (Array) prop_val.get_object ();
                        array.clear ();
                        switch (array.element_type) {
                            case Type.STRING:
                                ((Array<string>) array).add_all_array (self.keyfile.get_string_list (group_name, key));
                                break;
                            case Type.INT:
                                ((Array<int>) array).add_all_array (self.keyfile.get_integer_list (group_name, key));
                                break;
                            default:
                                error ("Unsupported type '%s' for array in ini", array.element_type.name ());
                        }

                    } else {
                        warning ("Unknown type for serialize - %s (%s)", prop_val.type ().name (), val_type.name ());
                    }

                    break;
            }
        } catch (GLib.Error e) {
            throw new Serialize.Error.WRONG_TYPE (e.message);
        }
    }
}
