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
public interface Serialize.DictSupport : Worker {

    /**
     * Method for deserializing to {@link Dict}
     *
     * @return                  Deserialized {@link Dict}
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public virtual inline Dict<Value?> deserialize () throws Serialize.Error {
        var dict = new Dict<Value?> ();
        deserialize_dict_into (dict, {});
        return dict;
    }

    /**
     * Method for deserializing the {@link Dict}
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public virtual inline Dict<T> deserialize_dict<T> (
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error {
        var dict = new Dict<T> ();
        deserialize_dict_into (dict, collection_hierarchy);
        return dict;
    }

    /**
     * Method for deserializing the {@link Dict}
     *
     * @param dict              Dict
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "7.5")]
    public abstract inline void deserialize_dict_into (
        Dict dict,
        CollectionFactory[] collection_hierarchy = {}
    ) throws Serialize.Error;

    /**
     * Asynchronous version of method {@link deserialize_dict}
     *
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws Serialize.Error    Error with data string
     */
    [Version (since = "6.0")]
    public virtual async inline Dict<T> deserialize_dict_async<T> (
        CollectionFactory[] collection_factories = {}
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<Dict<T>?> (null, () => {
            Dict<T>? result = null;

            try {
                result = deserialize_dict<T> (collection_factories);
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_dict_async.callback);
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
     * Asynchronous version of method {@link deserialize_dict_into}
     *
     * @param dict                  Dict
     * @param collection_factories  {@link CollectionFactory} array of hierarchy for
     *                              collection deserialization
     *
     * @throws Serialize.Error      Error with data string
     */
    [Version (since = "6.0")]
    public virtual async void deserialize_dict_into_async (
        Dict dict,
        CollectionFactory[] collection_factories = {}
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_dict_into (dict, collection_factories);
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (deserialize_dict_into_async.callback);
            return;
        });

        yield;
        thread.join ();

        if (error != null) {
            throw error;
        }
    }
}
