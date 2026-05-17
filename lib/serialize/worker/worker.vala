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

[Version (since = "7.5")]
public abstract class Serialize.Worker : Object {

    [Version (since = "7.5")]
    public Serialize.Settings settings { get; construct; }

    /**
     * Method for deserializing the {@link GLib.Object}
     *
     * @return  Deserialized object
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public inline T deserialize_object<T> () throws Serialize.Error {
        return deserialize_object_by_type (typeof (T));
    }

    /**
     * Method for deserializing the {@link GLib.Object} with {@link GLib.Type}
     *
     * @param obj_type          Type of objects
     *
     * @return  Deserialized object
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public abstract inline Object deserialize_object_by_type (
        GLib.Type obj_type
    ) throws Serialize.Error;

    /**
     * Method for deserializing into existing object
     *
     * @param obj               Object
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public abstract inline void deserialize_object_into (
        Object obj
    ) throws Serialize.Error;

    /**
     * Asynchronous version of method {@link deserialize_object}
     *
     * @return  Deserialized object
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public async inline T deserialize_object_async<T> () throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = deserialize_object<T> ();
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_object_async.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }

    /**
     * Asynchronous version of method {@link deserialize_object_by_type}
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public async inline Object deserialize_object_by_type_async (
        GLib.Type obj_type
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Object?> (null, () => {
            Object? result = null;

            try {
                result = deserialize_object_by_type (obj_type);
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_object_by_type_async.callback);
            return result;
        });

        yield;
        var result = thread.join ();

        if (error != null) {
            throw error;
        }

        return result;
    }

    /**
     * Asynchronous version of method {@link deserialize_object_into}
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public async inline void deserialize_object_into_async (
        Object obj
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_object_into (obj);
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_object_into_async.callback);
            return;
        });

        yield;
        thread.join ();

        if (error != null) {
            throw error;
        }
    }
}
