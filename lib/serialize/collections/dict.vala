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

public class Serialize.Dict<T> : Gee.HashMap<string, T>, CollectionFactory<T> {

    public Dict (owned Gee.EqualDataFunc<V>? value_equal_func = null) {
        base (null, null, value_equal_func);
    }

    /**
     * Create new empty Dict
     */
    public CollectionFactory<T> build () {
        return new Dict<T> (value_equal_func);
    }
}
