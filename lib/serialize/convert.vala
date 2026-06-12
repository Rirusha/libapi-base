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

namespace Serialize.Convert {

    internal Case detect_case (string str) {
        for (uint i = 0; i < str.char_count (); i++) {
            unichar c = str.get_char (i);

            switch (c) {
                case '_':
                    return SNAKE;
                case '-':
                    return KEBAB;
            }

            if (c.isupper ()) {
                if (i == 0) {
                    return PASCAL;
                } else {
                    return CAMEL;
                }
            }
        }

        return KEBAB;
    }

    /**
     * Convert `сamelCase` to `kebab-case` string
     *
     * @param camel_string correct `сamelCase` string
     *
     * @return `kebab-case` string
     */
    [Version (since = "6.0")]
    public string camel2kebab (string camel_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < camel_string.length) {
            if (camel_string[i].isupper ()) {
                builder.append_c ('-');
                builder.append_c (camel_string[i].tolower ());
            } else {
                builder.append_c (camel_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `сamelCase` to `snake_case` string
     *
     * @param camel_string correct `сamelCase` string
     *
     * @return `snake_case` string
     */
    [Version (since = "6.0")]
    public string camel2snake (string camel_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < camel_string.length) {
            if (camel_string[i].isupper ()) {
                builder.append_c ('_');
                builder.append_c (camel_string[i].tolower ());
            } else {
                builder.append_c (camel_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `сamelCase` to `PascalCase` string
     *
     * @param camel_string correct `сamelCase` string
     *
     * @return `PascalCase` string
     */
    [Version (since = "7.5")]
    public string camel2pascal (string camel_string) {
        var builder = new StringBuilder ();

        builder.append_c (camel_string[0].toupper ());
        builder.append (camel_string[1:camel_string.length]);

        return builder.free_and_steal ();
    }

    /**
     * Convert `kebab-case` to `сamelCase` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `сamelCase` string
     */
    [Version (since = "6.0")]
    public string kebab2camel (string kebab_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < kebab_string.length) {
            if (kebab_string[i] == '-') {
                i += 1;
                builder.append_c (kebab_string[i].toupper ());
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `kebab-case` to `snake_case` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `snake_case` string
     */
    [Version (since = "6.0")]
    public string kebab2snake (string kebab_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < kebab_string.length) {
            if (kebab_string[i] == '-') {
                builder.append_c ('_');
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `kebab-case` to `PascalCase` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `PascalCase` string
     */
    [Version (since = "7.5")]
    public string kebab2pascal (string kebab_string) {
        var builder = new StringBuilder ();

        bool first_passed = false;
        int i = 0;
        while (i < kebab_string.length) {
            if (!first_passed) {
                if (kebab_string[i] != '-') {
                    builder.append_c (kebab_string[i].toupper ());
                    first_passed = true;
                }
            } else if (kebab_string[i] == '-') {
                i += 1;
                builder.append_c (kebab_string[i].toupper ());
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `snake_case` to `kebab-case` string
     *
     * @param snake_string correct `snake_case` string
     *
     * @return `kebab-case` string
     */
    [Version (since = "6.0")]
    public string snake2kebab (string snake_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < snake_string.length) {
            if (snake_string[i] == '_') {
                builder.append_c ('-');
            } else {
                builder.append_c (snake_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `snake_case` to `сamelCase` string
     *
     * @param snake_string correct `snake_case` string
     *
     * @return `сamelCase` string
     */
    [Version (since = "6.0")]
    public string snake2camel (string snake_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < snake_string.length) {
            if (snake_string[i] == '_') {
                i += 1;
                builder.append_c (snake_string[i].toupper ());
            } else {
                builder.append_c (snake_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `snake_case` to `PascalCase` string
     *
     * @param snake_string correct `snake_case` string
     *
     * @return `PascalCase` string
     */
    [Version (since = "7.5")]
    public string snake2pascal (string snake_string) {
        var builder = new StringBuilder ();

        bool first_passed = false;
        int i = 0;
        while (i < snake_string.length) {
            if (!first_passed) {
                if (snake_string[i] != '_') {
                    builder.append_c (snake_string[i].toupper ());
                    first_passed = true;
                }
            } else if (snake_string[i] == '_') {
                i += 1;
                builder.append_c (snake_string[i].toupper ());
            } else {
                builder.append_c (snake_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `PascalCase` to `kebab-case` string
     *
     * @param pascal_string correct `PascalCase` string
     *
     * @return `kebab-case` string
     */
    [Version (since = "7.5")]
    public string pascal2kebab (string pascal_string) {
        var builder = new StringBuilder ();

        builder.append_c (pascal_string[0].tolower ());
        int i = 1;
        while (i < pascal_string.length) {
            if (pascal_string[i].isupper ()) {
                builder.append_c ('-');
                builder.append_c (pascal_string[i].tolower ());
            } else {
                builder.append_c (pascal_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `PascalCase` to `snake_case` string
     *
     * @param pascal_string correct `PascalCase` string
     *
     * @return `snake_case` string
     */
    [Version (since = "7.5")]
    public string pascal2snake (string pascal_string) {
        var builder = new StringBuilder ();

        builder.append_c (pascal_string[0].tolower ());
        int i = 1;
        while (i < pascal_string.length) {
            if (pascal_string[i].isupper ()) {
                builder.append_c ('_');
                builder.append_c (pascal_string[i].tolower ());
            } else {
                builder.append_c (pascal_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `PascalCase` to `сamelCase` string
     *
     * @param pascal_string correct `PascalCase` string
     *
     * @return `сamelCase` string
     */
    [Version (since = "7.5")]
    public string pascal2camel (string pascal_string) {
        var builder = new StringBuilder ();

        builder.append_c (pascal_string[0].tolower ());
        builder.append (pascal_string[1:pascal_string.length]);

        return builder.free_and_steal ();
    }

    /**
     * Convert any case string to kebab-case
     *
     * @param str   String
     *
     * @return Kebab string
     */
    [Version (since = "6.0")]
    public string cany2kebab (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return camel2kebab (str);
            case Case.PASCAL:
                return pascal2kebab (str);
            case Case.SNAKE:
                return snake2kebab (str);
            case Case.KEBAB:
                return str;
            case Case.AUTO:
                return any2kebab (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert any case string to snake_case
     *
     * @param str   String
     *
     * @return Snake string
     */
    [Version (since = "6.0")]
    public string cany2snake (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return camel2snake (str);
            case Case.PASCAL:
                return pascal2snake (str);
            case Case.SNAKE:
                return str;
            case Case.KEBAB:
                return kebab2snake (str);
            case Case.AUTO:
                return any2snake (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert any case string to camelCase
     *
     * @param str   String
     *
     * @return Camel string
     */
    [Version (since = "6.0")]
    public string cany2camel (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return str;
            case Case.PASCAL:
                return pascal2camel (str);
            case Case.SNAKE:
                return snake2camel (str);
            case Case.KEBAB:
                return kebab2camel (str);
            case Case.AUTO:
                return any2camel (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert any case string to PascalCase
     *
     * @param str   String
     *
     * @return Pascal string
     */
    [Version (since = "7.5")]
    public string cany2pascal (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return camel2pascal (str);
            case Case.PASCAL:
                return str;
            case Case.SNAKE:
                return snake2pascal (str);
            case Case.KEBAB:
                return kebab2pascal (str);
            case Case.AUTO:
                return any2pascal (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert any case string to kebab-case
     *
     * @param str   String
     *
     * @return Kebab string
     */
    [Version (since = "6.0")]
    public string any2kebab (string str) {
        var str_case = detect_case (str);
        return cany2kebab (str, str_case);
    }

    /**
     * Convert any case string to snake_case
     *
     * @param str   String
     *
     * @return Snake string
     */
    [Version (since = "6.0")]
    public string any2snake (string str) {
        var str_case = detect_case (str);
        return cany2snake (str, str_case);
    }

    /**
     * Convert any case string to camelCase
     *
     * @param str   String
     *
     * @return Camel string
     */
    [Version (since = "6.0")]
    public string any2camel (string str) {
        var str_case = detect_case (str);
        return cany2camel (str, str_case);
    }

    /**
     * Convert any case string to PascalCase
     *
     * @param str   String
     *
     * @return Pascal string
     */
    [Version (since = "7.5")]
    public string any2pascal (string str) {
        var str_case = detect_case (str);
        return cany2pascal (str, str_case);
    }

    /**
     * Convert kebab-case to specified case
     *
     * @param str   String
     * @param case_ Case, using KEBAB if AUTO
     *
     * @return Specified case string
     */
    [Version (since = "6.0")]
    public string kebab2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return kebab2camel (str);
            case Case.PASCAL:
                return kebab2pascal (str);
            case Case.SNAKE:
                return kebab2snake (str);
            case Case.AUTO:
            case Case.KEBAB:
                return str;
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert snake_case to specified case
     *
     * @param str   String
     * @param case_ Case, using KEBAB if AUTO
     *
     * @return Specified case string
     */
    [Version (since = "6.0")]
    public string snake2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return snake2camel (str);
            case Case.PASCAL:
                return snake2pascal (str);
            case Case.SNAKE:
                return str;
            case Case.AUTO:
            case Case.KEBAB:
                return snake2kebab (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert camelCase to specified case
     *
     * @param str   String
     * @param case_ Case, using KEBAB if AUTO
     *
     * @return Specified case string
     */
    [Version (since = "6.0")]
    public string camel2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return str;
            case Case.PASCAL:
                return camel2pascal (str);
            case Case.SNAKE:
                return camel2snake (str);
            case Case.AUTO:
            case Case.KEBAB:
                return camel2kebab (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Convert PascalCase to specified case
     *
     * @param str   String
     * @param case_ Case, using KEBAB if AUTO
     *
     * @return Specified case string
     */
    [Version (since = "7.5")]
    public string pascal2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return pascal2camel (str);
            case Case.PASCAL:
                return str;
            case Case.SNAKE:
                return pascal2snake (str);
            case Case.AUTO:
            case Case.KEBAB:
                return pascal2kebab (str);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Converts between formats
     */
    [Version (since = "7.5", deprecated = true, deprecated_since = "7.8", replacement = "convert_data")]
    public string data2data (
        string data,
        DictSupport from,
        ConvertableDataType to,
        Settings? settings = null
    ) throws Serialize.Error {
        var dict = from.deserialize ();

        switch (to) {
            case JSON:
                return JsonWorker.serialize (dict, settings);
            case YAML:
                return YamlWorker.serialize (dict, settings);
            default:
                assert_not_reached ();
        }
    }

    /**
     * Converts between formats
     */
    [Version (since = "7.8")]
    public string convert_data (
        string data,
        ConvertableDataType from,
        ConvertableDataType to,
        Settings? settings = null
    ) throws Serialize.Error {
        Dict<Value?> dict;

        switch (from) {
            case JSON:
                dict = JsonWorker.simple_deserialize (data, null, settings);
                break;
            case YAML:
                dict = YamlWorker.simple_deserialize (data, null, settings);
                break;
            default:
                assert_not_reached ();
        }

        switch (to) {
            case JSON:
                return JsonWorker.serialize (dict, settings);
            case YAML:
                return YamlWorker.serialize (dict, settings);
            default:
                assert_not_reached ();
        }
    }

    [Version (since = "6.0")]
    public Datalist<T> dict2datalist<T> (Dict<T> hash_map) {
        var dl = Datalist<T> ();

        foreach (var entry in hash_map) {
            dl.set_data (entry.key, entry.value);
        }

        return dl;
    }

    [Version (since = "6.0")]
    public Dict<T> datalist2dict<T> (Datalist<T> datalist) {
        var hash_map = new Dict<T> ();

        datalist.foreach ((key_quark, value) => {
            hash_map.set (key_quark.to_string (), value);
        });

        return hash_map;
    }

    /**
     * Convert to desired type when possible
     */
    [Version (since = "7.0")]
    public bool value2value (ref Value source_value, ref Value target_value) {

        //  Check if type equal
        if (source_value.holds (target_value.type ())) {
            source_value.copy (ref target_value);
            return true;
        }

        //  Auto transformation between enums and strings is not what we want
        if (source_value.holds (Type.ENUM)) {
            if (target_value.holds (Type.STRING)) {
                target_value.set_string (
                    Enum.get_nick_gtype (source_value.type (), source_value.get_enum (), Case.SNAKE)
                );
                return true;
            }
        }

        if (source_value.holds (Type.STRING)) {
            if (target_value.holds (Type.ENUM)) {
                target_value.set_enum (
                    Enum.get_by_nick_gtype (target_value.type (), source_value.get_string ().down ())
                );
                return true;

            } else if (target_value.holds (Type.INT64)) {
                int64 res;
                if (int64.try_parse (source_value.get_string (), out res)) {
                    target_value.set_int64 (res);
                    return true;
                }
            } else if (target_value.holds (Type.INT)) {
                int res;
                if (int.try_parse (source_value.get_string (), out res)) {
                    target_value.set_int (res);
                    return true;
                }
            } else if (target_value.holds (Type.DOUBLE)) {
                double res;
                if (double.try_parse (source_value.get_string (), out res)) {
                    target_value.set_double (res);
                    return true;
                }
            } else if (target_value.holds (Type.BOOLEAN)) {
                bool res;
                if (bool.try_parse (source_value.get_string (), out res)) {
                    target_value.set_boolean (res);
                    return true;
                }
            } else if (target_value.holds (typeof (DateTime))) {
                var dt = new DateTime.from_iso8601 (source_value.get_string (), new TimeZone.utc ());
                if (dt != null) {
                    target_value.set_boxed (dt);
                    return true;
                }
                int64 res;
                if (int64.try_parse (source_value.get_string (), out res)) {
                    dt = new DateTime.from_unix_utc (res);
                    if (dt != null) {
                        target_value.set_boxed (dt);
                        return true;
                    }
                }
            }
        } else if (source_value.holds (Type.INT64)) {
            if (target_value.holds (typeof (DateTime))) {
                var dt = new DateTime.from_unix_utc (source_value.get_int64 ());
                if (dt != null) {
                    target_value.set_boxed (dt);
                    return true;
                }
            }
        }

        if (source_value.transform (ref target_value)) {
            return true;
        }

        if (source_value.holds (typeof (DateTime))) {
            var dt = (DateTime) source_value.get_boxed ();
            if (target_value.holds (Type.INT64)) {
                target_value.set_int64 (dt.to_unix ());
                return true;

            } else if (target_value.holds (Type.STRING)) {
                target_value.set_string (dt.format_iso8601 ());
                return true;
            }
        }

        warning ("Failed to convert '%s' to '%s'", source_value.type ().name (), target_value.type ().name ());

        return false;
    }
}
