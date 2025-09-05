/*
 * Copyright 2024 Vladimir Vaskov
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

public sealed class ApiBase.Parameter : Object {

    public string name { get; construct; }
    public string value { get; construct; }

    public Parameter (string name, string? value) {
        Object (
            name: name,
            value: value
        );
    }

    public string to_string () {
        return "%s=%s".printf (
            name,
            Uri.escape_string (value)
        );
    }
}
