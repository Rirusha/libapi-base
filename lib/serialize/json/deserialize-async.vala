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

namespace Serialize.JsonDeserializeAsync {

    async static T simple_from_json<T> (
        string json,
        string[]? sub_members,
        Serialize.Settings? settings
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = JsonDeserializeSync.simple_from_json<T> (
                    json,
                    sub_members,
                    settings
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_from_json.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }

    async static Array<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members,
        Serialize.Settings? settings
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Array<T>?> (null, () => {
            Array<T>? result = null;

            try {
                result = JsonDeserializeSync.simple_array_from_json<T> (
                    json,
                    sub_members,
                    settings
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_array_from_json.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }

    async static Dict<T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members,
        Serialize.Settings? settings
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Dict<T>?> (null, () => {
            Dict<T>? result = null;

            try {
                result = JsonDeserializeSync.simple_dict_from_json<T> (
                    json,
                    sub_members,
                    settings
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_dict_from_json.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }
}
