/*
 * Copyright (C) 2024 Vladimir Vaskov
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

namespace ApiBase {

    /**
     * 
     */
    public delegate bool SubArrayCreationFunc (out Gee.ArrayList array, Type element_type);

    internal const string GET = "GET";
    internal const string POST = "POST";
    internal const int GLOBAL_TIMEOUT = 10;

    /**
     * Supported post content types
     */
    public enum PostContentType {
        X_WWW_FORM_URLENCODED,
        JSON
    }

    /**
     * Name cases
     */
    public enum Case {
        SNAKE,
        KEBAB,
        CAMEL,
    }

    /**
     * Type of cookie jar to create
     */
    public enum CookieJarType {
        NONE,
        DB,
        TEXT,
    }

    /**
     * Common library error
     */
    public errordomain CommonError {
        /**
         * Can't parse json
         */
        PARSE_JSON,

        /**
         * Request send failed
         */
        SOUP,

        /**
         * Error from api get
         */
        ANSWER,

        /**
         * Authentication error
         */
        AUTH_ERROR,
    }

    /**
     * Bad status codes error
     */
    public errordomain BadStatusCodeError {

        BAD_REQUEST = 400,
        UNAUTHORIZED = 401,
        FORBIDDEN = 403,
        NOT_FOUND = 404,
        METHOD_NOT_ALLOWED = 405,
        REQUEST_TIMEOUT = 408,
        CONFLICT = 409,
        GONE = 410,
        PAYLOAD_TOO_LARGE = 413,
        UNSUPPORTED_MEDIA_TYPE = 415,
        TOO_MANY_REQUESTS = 429,

        INTERNAL_SERVER_ERROR = 500,
        NOT_IMPLEMENTED = 501,
        BAD_GATEWAY = 502,
        SERVICE_UNAVAILABLE = 503,
        GATEWAY_TIMEOUT = 504,

        UNKNOWN = 0
    }

    public BadStatusCodeError get_error (uint status_code, string error_response) {
        switch (status_code) {
            case Soup.Status.BAD_REQUEST:
                return new BadStatusCodeError.BAD_REQUEST (error_response);
            case Soup.Status.UNAUTHORIZED:
                return new BadStatusCodeError.UNAUTHORIZED (error_response);
            case Soup.Status.FORBIDDEN:
                return new BadStatusCodeError.FORBIDDEN (error_response);
            case Soup.Status.NOT_FOUND:
                return new BadStatusCodeError.NOT_FOUND (error_response);
            case Soup.Status.METHOD_NOT_ALLOWED:
                return new BadStatusCodeError.METHOD_NOT_ALLOWED (error_response);
            case Soup.Status.REQUEST_TIMEOUT:
                return new BadStatusCodeError.REQUEST_TIMEOUT (error_response);
            case Soup.Status.CONFLICT:
                return new BadStatusCodeError.CONFLICT (error_response);
            case Soup.Status.GONE:
                return new BadStatusCodeError.GONE (error_response);
            case Soup.Status.REQUEST_ENTITY_TOO_LARGE:
                return new BadStatusCodeError.PAYLOAD_TOO_LARGE (error_response);
            case Soup.Status.UNSUPPORTED_MEDIA_TYPE:
                return new BadStatusCodeError.UNSUPPORTED_MEDIA_TYPE (error_response);
            case 429:
                return new BadStatusCodeError.TOO_MANY_REQUESTS (error_response);
            case Soup.Status.INTERNAL_SERVER_ERROR:
                return new BadStatusCodeError.INTERNAL_SERVER_ERROR (error_response);
            case Soup.Status.NOT_IMPLEMENTED:
                return new BadStatusCodeError.NOT_IMPLEMENTED (error_response);
            case Soup.Status.BAD_GATEWAY:
                return new BadStatusCodeError.BAD_GATEWAY (error_response);
            case Soup.Status.SERVICE_UNAVAILABLE:
                return new BadStatusCodeError.SERVICE_UNAVAILABLE (error_response);
            case Soup.Status.GATEWAY_TIMEOUT:
                return new BadStatusCodeError.GATEWAY_TIMEOUT (error_response);
            default:
                return new BadStatusCodeError.UNKNOWN (status_code.to_string () + ": " + error_response);
        }
    }

    public string get_enum_nick (Type enum_type, int enum_) {
        var enum_class = (EnumClass) enum_type.class_ref ();
        var enum_value = enum_class.get_value (enum_);

        return kebab2snake (enum_value.value_nick.down ());
    }

    /**
     * Delete all {@link char} from start and end of {@link string}
     *
     * @param str  string to be stripped
     * @param ch   char to strip
     *
     * @return     stripped string
     *
     * @since 0.1.0
     */
    public string strip (string str, char ch) {
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

    /**
     * Convert ``сamelCase`` to ``kebab-case`` string
     *
     * @param camel_string correct ``сamelCase`` string
     *
     * @return ``kebab-case`` string
     *
     * @since 0.1.0
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

    /**
     * Convert ``kebab-case`` to ``сamelCase`` string
     *
     * @param kebab_string correct ``kebab-case`` string
     *
     * @return ``сamelCase`` string
     *
     * @since 0.1.0
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

    /**
     * Convert ``kebab-case`` to ``snake_case`` string
     *
     * @param kebab_string correct ``kebab-case`` string
     *
     * @return ``snake_case`` string
     *
     * @since 0.1.0
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

    /**
     * Convert ``snake_case`` to ``kebab-case`` string
     *
     * @param snake_string correct ``snake_case`` string
     *
     * @return ``kebab-case`` string
     *
     * @since 0.1.0
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
}
