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

// vala-lint=skip-file

using Serialize;

const string STRING_VAL_NAME = "string-val";
const string STRING_VAL = "test";
const string INT64_VAL_NAME = "int64-val";
const int64 INT64_VAL = 1234;
const string INT_VAL_NAME = "int-val";
const int INT_VAL = 1234;
const string DOUBLE_VAL_NAME = "double-val";
const double DOUBLE_VAL = 45.1;
const string BOOL_VAL_NAME = "bool-val";
const bool BOOL_VAL = true;
const string STRINGS_VAL_NAME = "strings-val";
const string[] STRINGS_VAL = {"a", "b", "c"};
const string ENUM_VAL_NAME = "enum-val";
const TestEnum ENUM_VAL = VALUE_2;
const string TYPE__NAME = "type";
const string TYPE_ = "some text";

public enum TestEnum {
    VALUE1 = 0,
    VALUE_2 = 1,
}

public class ValuesData : DataObject {
    public ApplcationData application { get; set; }
    public ContextData context { get; set; }
}

public class ApplcationData : DataObject {
    public string string_val { get; set; }
    public int64 int64_val { get; set; }
    public int int_val { get; set; }
    public double double_val { get; set; }
    public bool bool_val { get; set; }
}

public class ContextData : DataObject {
    public string[] strings_val { get; set; }
    public TestEnum enum_val { get; set; }

    // Strange names

    // Property with 'type' name cannot exists
    [Description (nick="type")]
    public string type_ { get; set; }
}

string get_name_with_c (string name, Case c) {
    switch (c) {
        case KEBAB:
            return name;
        case SNAKE:
            return Convert.kebab2snake (name);
        case CAMEL:
            return Convert.kebab2camel (name);
        default:
            assert_not_reached ();
    }
}

string get_exp_ini (Case c) {
    return string.joinv ("\n", {
        "[Application]",
        @"$(get_name_with_c (STRING_VAL_NAME, c))=$STRING_VAL",
        @"$(get_name_with_c (INT64_VAL_NAME, c))=$INT64_VAL",
        @"$(get_name_with_c (INT_VAL_NAME, c))=$INT_VAL",
        @"$(get_name_with_c (DOUBLE_VAL_NAME, c))=$DOUBLE_VAL",
        @"$(get_name_with_c (BOOL_VAL_NAME, c))=$BOOL_VAL",
        "",
        "[Context]",
        @"$(get_name_with_c (STRINGS_VAL_NAME, c))=$(string.joinv (";", STRINGS_VAL));",
        @"$(get_name_with_c (ENUM_VAL_NAME, c))=1",
        @"$(get_name_with_c (TYPE__NAME, c))=$TYPE_",
        "",
    });
}

string get_exp_ini2 (Case c) {
    return string.joinv ("\n", {
        "[Application]",
        @"$(get_name_with_c (STRING_VAL_NAME, c))=$STRING_VAL",
        @"$(get_name_with_c (INT64_VAL_NAME, c))=$INT64_VAL",
        @"$(get_name_with_c (INT_VAL_NAME, c))=$INT_VAL",
        @"$(get_name_with_c (DOUBLE_VAL_NAME, c))=$DOUBLE_VAL",
        @"$(get_name_with_c (BOOL_VAL_NAME, c))=$BOOL_VAL",
        "",
        "[Context]",
        @"$(get_name_with_c (STRINGS_VAL_NAME, c))=$(string.joinv (";", STRINGS_VAL));",
        @"$(get_name_with_c (ENUM_VAL_NAME, c))=value2",
        @"$(get_name_with_c (TYPE__NAME, c))=$TYPE_",
        "",
    });
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/ini/serialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var test_object = new ValuesData ();
            test_object.application = new ApplcationData ();
            test_object.context = new ContextData ();

            test_object.application.string_val = STRING_VAL;
            test_object.application.int64_val = INT64_VAL;
            test_object.application.int_val = INT_VAL;
            test_object.application.double_val = DOUBLE_VAL;
            test_object.application.bool_val = BOOL_VAL;
            test_object.context.strings_val = STRINGS_VAL;
            test_object.context.enum_val = ENUM_VAL;
            test_object.context.type_ = TYPE_;

            string expectation = get_exp_ini (c);
            var result = IniWorker.serialize (test_object, new Serialize.Settings () {
                names_case = c
            });

            if (result != expectation) {
                Test.fail_printf (result + "\n!=\n" + expectation);
            }
        }
    });

    Test.add_func ("/ini/serialize/values2", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var test_object = new ValuesData ();
            test_object.application = new ApplcationData ();
            test_object.context = new ContextData ();

            test_object.application.string_val = STRING_VAL;
            test_object.application.int64_val = INT64_VAL;
            test_object.application.int_val = INT_VAL;
            test_object.application.double_val = DOUBLE_VAL;
            test_object.application.bool_val = BOOL_VAL;
            test_object.context.strings_val = STRINGS_VAL;
            test_object.context.enum_val = ENUM_VAL;
            test_object.context.type_ = TYPE_;

            string expectation = get_exp_ini2 (c);
            var result = IniWorker.serialize (test_object, new Serialize.Settings () {
                names_case = c,
                enum_serialize_method = STRING,
                enum_serialize_case = CAMEL
            });

            if (result != expectation) {
                Test.fail_printf (result + "\n!=\n" + expectation);
            }
        }
    });

    Test.add_func ("/ini/deserialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            string ini = get_exp_ini (c);

            ValuesData result;

            try {
                result = IniWorker.simple_from_ini<ValuesData> (ini, new Serialize.Settings () { names_case = c });
            } catch (GLib.Error e) {
                Test.fail_printf (e.message);
                return;
            }

            if (result.application.string_val != STRING_VAL) {
                Test.fail_printf (@"$(result.application.string_val) != $(STRING_VAL)");
            }
            if (result.application.int64_val != INT64_VAL) {
                Test.fail_printf (@"$(result.application.int64_val) != $(INT64_VAL)");
            }
            if (result.application.int_val != INT64_VAL) {
                Test.fail_printf (@"$(result.application.int_val) != $(INT64_VAL)");
            }
            if (result.application.double_val != DOUBLE_VAL) {
                Test.fail_printf (@"$(result.application.double_val) != $(DOUBLE_VAL)");
            }
            if (result.application.bool_val != BOOL_VAL) {
                Test.fail_printf (@"$(result.application.bool_val) != $(BOOL_VAL)");
            }
            if (result.context.enum_val != ENUM_VAL) {
                Test.fail_printf (@"$(result.context.enum_val) != $(ENUM_VAL)");
            }
            var rstrv = string.joinv (";", result.context.strings_val);
            var estrv = string.joinv (";", STRINGS_VAL);
            if (rstrv != estrv) {
                Test.fail_printf (@"$(rstrv) != $(estrv)");
            }
            if (result.context.type_ != TYPE_) {
                Test.fail_printf (@"$(result.context.type_) != $(TYPE_)");
            }
        }
    });

    return Test.run ();
}
