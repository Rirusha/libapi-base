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

namespace ApiBase.Convert {

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
                return CAMEL;
            }
        }

        return KEBAB;
    }

    internal string strip (string str, char ch) {
        int start = 0;
        int end = str.length;

        while (str[start] == ch) {
            start++;
        }

        while (str[end - 1] == ch) {
            end--;
        }

        return str[start:end];
    }

    [Version (since = "0.1.0")]
    /**
     * Convert `сamelCase` to `kebab-case` string
     *
     * @param camel_string correct `сamelCase` string
     *
     * @return `kebab-case` string
     */
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

    [Version (since = "6.0")]
    /**
     * Convert `сamelCase` to `snake_case` string
     *
     * @param camel_string correct `сamelCase` string
     *
     * @return `snake_case` string
     */
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

    [Version (since = "0.1.0")]
    /**
     * Convert `kebab-case` to `сamelCase` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `сamelCase` string
     */
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

    [Version (since = "0.1.0")]
    /**
     * Convert `kebab-case` to `snake_case` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `snake_case` string
     */
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

    [Version (since = "0.1.0")]
    /**
     * Convert `snake_case` to `kebab-case` string
     *
     * @param snake_string correct `snake_case` string
     *
     * @return `kebab-case` string
     */
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

    [Version (since = "6.0")]
    /**
     * Convert `snake_case` to `сamelCase` string
     *
     * @param snake_string correct `snake_case` string
     *
     * @return `сamelCase` string
     */
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

    [Version (since = "3.0")]
    /**
     * Convert any case string to kebab-case
     *
     * @param str   String
     *
     * @return Kebab string
     */
    public string any2kebab (string str) {
        var str_case = detect_case (str);

        switch (str_case) {
            case Case.CAMEL:
                return camel2kebab (str);
            case Case.SNAKE:
                return snake2kebab (str);
            case Case.KEBAB:
                return str;
            default:
                assert_not_reached ();
        }
    }

    [Version (since = "6.0")]
    /**
     * Convert any case string to snake_case
     *
     * @param str   String
     *
     * @return Snake string
     */
    public string any2snake (string str) {
        var str_case = detect_case (str);

        switch (str_case) {
            case Case.CAMEL:
                return camel2snake (str);
            case Case.SNAKE:
                return str;
            case Case.KEBAB:
                return kebab2snake (str);
            default:
                assert_not_reached ();
        }
    }

    [Version (since = "6.0")]
    /**
     * Convert any case string to camelCase
     *
     * @param str   String
     *
     * @return Camel string
     */
    public string any2camel (string str) {
        var str_case = detect_case (str);

        switch (str_case) {
            case Case.CAMEL:
                return str;
            case Case.SNAKE:
                return snake2camel (str);
            case Case.KEBAB:
                return kebab2camel (str);
            default:
                assert_not_reached ();
        }
    }

    [Version (since = "6.0")]
    /**
     * Convert kebab-case to specified case
     *
     * @param str   String
     * @param case_ Case
     *
     * @return Specified case string
     */
    public string kebab2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return kebab2camel (str);
            case Case.SNAKE:
                return kebab2snake (str);
            case Case.KEBAB:
                return str;
            default:
                assert_not_reached ();
        }
    }

    [Version (since = "6.0")]
    /**
     * Convert snake_case to specified case
     *
     * @param str   String
     * @param case_ Case
     *
     * @return Specified case string
     */
    public string snake2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return snake2camel (str);
            case Case.SNAKE:
                return str;
            case Case.KEBAB:
                return snake2kebab (str);
            default:
                assert_not_reached ();
        }
    }

    [Version (since = "6.0")]
    /**
     * Convert camelCase to specified case
     *
     * @param str   String
     * @param case_ Case
     *
     * @return Specified case string
     */
    public string camel2any (string str, Case case_) {
        switch (case_) {
            case Case.CAMEL:
                return str;
            case Case.SNAKE:
                return camel2snake (str);
            case Case.KEBAB:
                return camel2kebab (str);
            default:
                assert_not_reached ();
        }
    }
}
