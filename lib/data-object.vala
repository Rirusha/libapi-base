/*
 * Copyright (C) 2025 Vladimir Vaskov <rirusha@altlinux.org>
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

public abstract class ApiBase.DataObject : Object {

    public void fill_from_json (
        string json,
        string[]? sub_members = null,
        ApiBase.Case names_case = ApiBase.Case.KEBAB
    ) throws ApiBase.CommonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        jsoner.deserialize_object_into (this);
    }

    public string to_json (ApiBase.Case names_case = ApiBase.Case.KEBAB) {
        return Jsoner.serialize (this, names_case);
    }

    public static T from_json<T> (
        string json,
        string[]? sub_members = null,
        ApiBase.Case names_case = ApiBase.Case.KEBAB
    ) throws ApiBase.CommonError {
        var type_ = typeof (T);
        assert (type_.is_a (typeof (DataObject)));

        var obj = (DataObject) Object.new (type_);
        obj.fill_from_json (json, sub_members, names_case);

        return (T) obj;
    }
}
