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

namespace Serialize {

    internal static Serialize.Settings settings;

    public void set_settings (Serialize.Settings settings) {
        Serialize.settings = settings;
    }

    public Serialize.Settings get_settings () {
        if (Serialize.settings == null) {
            Serialize.settings = new Serialize.Settings ();
        }
        return Serialize.settings;
    }
}

[Version (since = "7.0")]
public sealed class Serialize.Settings : Object {

    public EnumSerializeMethod enum_serialize_method { get; set; default = STRING; }

    public EnumSerializeCase enum_serialize_case { get; set; default = SNAKE; }

    public DateTimeSerializeMethod date_time_serialize_method { get; set; default = ISO8601; }

    public Case names_case { get; set; default = AUTO; }

    public bool pretty { get; set; default = false; }

    public bool ignore_default { get; set; default = false; }
}
