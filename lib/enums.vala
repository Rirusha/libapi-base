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
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace ApiBase.Enum {

    [Version (since = "5.1")]
    /**
     * @param nick              String enum in snake case
     *
     * @return                  Enum
     */
    public EnumType get_by_nick<EnumType> (string nick) {
        assert (typeof (EnumType).is_enum ());
        return get_by_nick_gtype (typeof (EnumType), nick);
    }

    [Version (since = "5.1")]
    /**
     * @param enum_             Enum
     *
     * @return                  Nick
     */
    public string get_nick<EnumType> (EnumType enum_) {
        assert (typeof (EnumType).is_enum ());
        return get_nick_gtype (typeof (EnumType), (int) enum_);
    }

    internal EnumClass get_class<EnumType> () {
        assert (typeof (EnumType).is_enum ());
        return get_class_gtype (typeof (EnumType));
    }

    internal EnumClass get_class_gtype (Type enum_type) {
        return (EnumClass) enum_type.class_ref ();
    }

    public int get_by_nick_gtype (Type enum_type, string nick) {
        var enum_class = get_class_gtype (enum_type);
        return enum_class.get_value_by_nick (Convert.snake2kebab (nick)).value;
    }

    public string get_nick_gtype (Type enum_type, int enum_) {
        var enum_class = get_class_gtype (enum_type);
        var enum_value = enum_class.get_value (enum_);

        return Convert.kebab2snake (enum_value.value_nick);
    }
}

public enum ApiBase.HttpMethod {
    GET,
    HEAD,
    OPTIONS,
    TRACE,
    PUT,
    DELETE,
    POST,
    PATCH,
    CONNECT;

    public string to_string () {
        return Enum.get_class<HttpMethod> ().get_value (this).value_nick.up ();
    }
}

/**
 * Supported content types
 */
public enum ApiBase.ContentType {
    X_WWW_FORM_URLENCODED,
    JSON;

    public string to_string () {
        switch (this) {
            case X_WWW_FORM_URLENCODED:
                return "application/x-www-form-urlencoded";
            case JSON:
                return "application/json";
            default:
                assert_not_reached ();
        }
    }

    public static ContentType from_string (string str) {
        switch (str) {
            case "application/x-www-form-urlencoded":
                return X_WWW_FORM_URLENCODED;
            case "application/json":
                return JSON;
            default:
                assert_not_reached ();
        }
    }
}

/**
 * Name cases. With AUTO {@link Jsoner} will try detect name case for every member of
 * json object. Useful for working with bad API developers
 */
public enum ApiBase.Case {
    AUTO,
    SNAKE,
    KEBAB,
    CAMEL;
}

/**
 * Type of cookie jar to create
 */
public enum ApiBase.CookieJarType {
    NONE,
    DB,
    TEXT;
}
