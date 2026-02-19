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

namespace Serialize.Enum {

    /**
     * @param nick              String enum in snake case
     *
     * @return                  Enum
     */
    [Version (since = "6.0")]
    public EnumType get_by_nick<EnumType> (string nick) {
        assert (typeof (EnumType).is_enum ());
        return get_by_nick_gtype (typeof (EnumType), nick);
    }

    /**
     * @param enum_             Enum
     *
     * @return                  Nick
     */
    [Version (since = "6.0")]
    public string get_nick<EnumType> (EnumType enum_, Case case_) {
        assert (typeof (EnumType).is_enum ());
        return get_nick_gtype (typeof (EnumType), (int) enum_, case_);
    }

    [Version (since = "6.0")]
    public EnumClass get_class<EnumType> () {
        assert (typeof (EnumType).is_enum ());
        return get_class_gtype (typeof (EnumType));
    }

    [Version (since = "6.0")]
    public EnumClass get_class_gtype (Type enum_type) {
        return (EnumClass) enum_type.class_ref ();
    }

    [Version (since = "6.0")]
    public int get_by_nick_gtype (Type enum_type, string nick) {
        var enum_class = get_class_gtype (enum_type);
        return enum_class.get_value_by_nick (Convert.any2kebab (nick)).value;
    }

    [Version (since = "6.0")]
    public string get_nick_gtype (Type enum_type, int enum_, Case case_) {
        var enum_class = get_class_gtype (enum_type);
        var enum_value = enum_class.get_value (enum_);

        return Convert.kebab2any (enum_value.value_nick, case_);
    }
}

/**
 * Name cases. With AUTO {@link Jsoner} will try detect name case for every member of
 * json object. Useful for working with bad API developers
 */
[Version (since = "6.0")]
public enum Serialize.Case {
    AUTO,
    SNAKE,
    KEBAB,
    CAMEL;
}
