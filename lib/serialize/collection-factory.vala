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

[Version (since = "6.0")]
public abstract class Serialize.CollectionFactory<T> : Object {

    public Type element_type {
        get {
            return typeof (T);
        }
    }

    public abstract Gee.Traversable<T> build ();
}

[Version (since = "6.0")]
public sealed class Serialize.ArrayFactory<T> : Serialize.CollectionFactory<T> {

    unowned Gee.EqualDataFunc? equal_func;

    public ArrayFactory (Gee.EqualDataFunc? equal_data_func = null) {
        this.equal_func = equal_data_func;
    }

    public override Gee.Traversable<T> build () {
        return new Gee.ArrayList<T> (equal_func);
    }
}

[Version (since = "6.0")]
public sealed class Serialize.DictFactory<T> : Serialize.CollectionFactory<T> {

    unowned Gee.EqualDataFunc? equal_data_func;

    public DictFactory (Gee.EqualDataFunc? equal_func = null) {
        this.equal_data_func = equal_func;
    }

    public override Gee.Traversable<T> build () {
        return new Gee.HashMap<string, T> (null, equal_data_func);
    }
}
