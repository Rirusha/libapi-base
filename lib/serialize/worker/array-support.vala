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
public interface Serialize.ArraySupport : Worker {

    /**
     * Method for deserializing the {@link Array}
     *
     * @param collection_hierarchy A function for creating subsets in the case of arrays in an array
     *
     * @throws Serialize.Error    Error with json string
     */
    [Version (since = "7.5")]
    public virtual inline Array<T> deserialize_array<T> (
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        var array = new Array<T> ();
        deserialize_array_into (array, collection_hierarchy);
        return array;
    }

    /**
     * Method for deserializing the {@link Array}
     *
     * @param array        Array
     * @param collection_hierarchy A function for creating subsets in the case of arrays in an array
     *
     * @throws Serialize.Error    Error with json string
     */
    [Version (since = "7.5")]
    public abstract inline void deserialize_array_into (
        Array array,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error;

    /**
     * Asynchronous version of method {@link deserialize_array}
     *
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws Serialize.Error    Error with json string
     */
    [Version (since = "7.5")]
    public async virtual Array<T> deserialize_array_async<T> (
        CollectionFactory[] collection_factories = {}
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Array<T>?> (null, () => {
            Array<T>? result = null;

            try {
                result = deserialize_array<T> (collection_factories);
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_array_async.callback);
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
     * Asynchronous version of method {@link deserialize_array_into}
     *
     * @param array        Array
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws Serialize.Error    Error with json string
     */
    [Version (since = "7.5")]
    public async virtual inline void deserialize_array_into_async (
        Array array,
        CollectionFactory[] collection_factories = {}
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_array_into (array, collection_factories);
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_array_into_async.callback);
            return;
        });

        yield;
        thread.join ();

        if (error != null) {
            throw error;
        }
    }
}
