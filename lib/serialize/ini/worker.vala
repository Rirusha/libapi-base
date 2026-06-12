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

/**
 * Ini helper for de/serialization
 */
[Version (since = "7.5")]
public sealed class Serialize.IniWorker : Worker {

    internal KeyFile keyfile { get; private set; }

    /**
     * Performs initialization for deserialization. Accepts a ini string. In case of
     * a parsing error
     *
     * @param ini_string    Correct ini string
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with ini or sub_members
     */
    [Version (since = "7.5")]
    public IniWorker (
        string ini_string,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        if (ini_string.length < 1) {
            throw new Serialize.Error.EMPTY ("Ini string is empty");
        }

        KeyFile? kf;

        try {
            kf = new KeyFile ();
            kf.load_from_data (ini_string, -1, GLib.KeyFileFlags.NONE);

        } catch (GLib.Error e) {
            throw new Serialize.Error.INVALID ("'%s' is not correct ini string: %s", ini_string, e.message);
        }

        if (kf == null) {
            throw new Serialize.Error.EMPTY ("Ini string is empty");
        }

        debug (
            "IniWorker initted for deserialize with:\n%s",
            ini_string
        );

        Object (
            settings: settings == null ? get_settings () : settings
        );

        keyfile = kf;
    }

    /**
     * Performs initialization for deserialization. Accepts a ini string in the
     * form of bytes, the object {@link GLib.Bytes}. In case of a parsing error
     *
     * @param bytes         Ini string in the form of bytes, the object {@link GLib.Bytes}
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with ini or sub_members
     */
    [Version (since = "7.5")]
    public IniWorker.from_bytes (
        Bytes bytes,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        if (bytes.length == 0) {
            throw new Serialize.Error.EMPTY ("Ini string is empty");
        }

        this.from_data (bytes.get_data (), settings);
    }

    /**
     * Performs initialization for deserialization. Accepts a ini string in the form of bytes,
     * an {@link uint8} array. In case of a parsing error
     *
     * @param data          Ini string in the form of bytes, {@link uint8} array
     * @param settings      Settings
     *
     * @throws Serialize.Error    Error with ini or sub_members
     */
    [Version (since = "7.5")]
    public IniWorker.from_data (
        owned uint8[] data,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        //  Fix not NUL-terminated
        if (data[data.length - 1] != 0) {
            data.resize (data.length + 1);
            data[data.length - 1] = 0;
        }

        this ((string) data, settings);
    }

    /**
     * Serialize {@link GLib.Object} into a correct ini string
     *
     * @param obj               {@link GLib.Object}
     * @param settings          Settings
     *
     * @return                  Ini string
     */
    [Version (since = "7.5")]
    public static inline string serialize (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        return IniSerializeSync.serialize (obj, settings);
    }

    /**
     * Object creation method from ini
     * via {@link Worker.deserialize_object}
     * Simple version for fast deserialization without
     * manual {@link IniWorker} instance creation
     *
     * @param ini              Ini string
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with ini
     */
    [Version (since = "7.5")]
    public static inline T simple_from_ini<T> (
        string ini,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        var worker = new IniWorker (ini, settings);
        return worker.deserialize_object<T> ();
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.5")]
    public override inline Object deserialize_object_by_type (
        GLib.Type obj_type
    ) throws Serialize.Error {
        return IniDeserializeSync.deserialize_object_by_type (this, obj_type);
    }

    /**
     * {@inheritDoc}
     */
    [Version (since = "7.5")]
    public override inline void deserialize_object_into (
        Object obj
    ) throws Serialize.Error {
        IniDeserializeSync.deserialize_object_into (this, obj);
    }

    /**
     * Asynchronous version of method {@link serialize}
     */
    [Version (since = "7.5")]
    public static inline async string serialize_async (
        Object obj,
        Serialize.Settings? settings = null
    ) {
        var thread = new Thread<string> (null, () => {
            var result = serialize (obj, settings);

            Idle.add (serialize_async.callback);
            return result;
        });

        yield;

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link simple_from_ini}
     *
     * @param ini               Ini string
     * @param settings          Settings
     *
     * @return                  Deserialized object
     *
     * @throws Serialize.Error        Error with ini
     */
    [Version (since = "7.5")]
    public async static inline T simple_from_ini_async<T> (
        string ini,
        Serialize.Settings? settings = null
    ) throws Serialize.Error {
        Serialize.Error? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = simple_from_ini<T> (
                    ini,
                    settings
                );
            } catch (Serialize.Error e) {
                error = e;
            }

            Idle.add (simple_from_ini_async.callback);
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
