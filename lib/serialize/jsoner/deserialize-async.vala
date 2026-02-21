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

namespace Serialize.JsonerDeserializeAsync {

    internal async static T simple_from_json<T> (
        string json,
        string[]? sub_members,
        Case names_case
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = JsonerDeserializeSync.simple_from_json<T> (
                    json,
                    sub_members,
                    names_case
                );
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (simple_from_json.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async static Array<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members,
        Case names_case
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<Array<T>?> (null, () => {
            Array<T>? result = null;

            try {
                result = JsonerDeserializeSync.simple_array_from_json<T> (
                    json,
                    sub_members,
                    names_case
                );
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (simple_array_from_json.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async static Dict<T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members,
        Case names_case
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<Dict<T>?> (null, () => {
            Dict<T>? result = null;

            try {
                result = JsonerDeserializeSync.simple_dict_from_json<T> (
                    json,
                    sub_members,
                    names_case
                );
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (simple_dict_from_json.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async T deserialize_object<T> (
        Jsoner self
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = JsonerDeserializeSync.deserialize_object<T> (self);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_object.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async Object deserialize_object_by_type (
        Jsoner self,
        GLib.Type obj_type
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<Object?> (null, () => {
            Object? result = null;

            try {
                result = JsonerDeserializeSync.deserialize_object_by_type (self, obj_type);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_object_by_type.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async void deserialize_object_into (
        Jsoner self,
        Object obj
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                JsonerDeserializeSync.deserialize_object_into (self, obj);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_object_into.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }

    internal async Array<T> deserialize_array<T> (
        Jsoner self,
        CollectionFactory[] collection_factories
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<Array<T>?> (null, () => {
            Array<T>? result = null;

            try {
                result = JsonerDeserializeSync.deserialize_array<T> (self, collection_factories);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_array.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async void deserialize_array_into (
        Jsoner self,
        Array array_list,
        CollectionFactory[] collection_factories
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                JsonerDeserializeSync.deserialize_array_into (self, array_list, collection_factories);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_array_into.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }

    internal async Dict<T> deserialize_dict<T> (
        Jsoner self,
        CollectionFactory[] collection_factories
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<Dict<T>?> (null, () => {
            Dict<T>? result = null;

            try {
                result = JsonerDeserializeSync.deserialize_dict<T> (self, collection_factories);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_dict.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    internal async void deserialize_dict_into (
        Jsoner self,
        Dict dict,
        CollectionFactory[] collection_factories
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                JsonerDeserializeSync.deserialize_dict_into (self, dict, collection_factories);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_dict_into.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }
}
