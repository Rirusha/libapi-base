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

public class SimpleObject : DataObject {
    public string string_value { get; set; }
    public int int_value { get; set; }
    public bool bool_value { get; set; }
}

public class TestObjectArrayString : DataObject {
    public Serialize.Array<string> value { get; set; default = new Serialize.Array<string> (); }
}

public class TestObjectArrayStringStrv : DataObject {
    public string[] value { get; set; }
}

public class TestObjectDictString : DataObject {
    public Serialize.Dict<string> value { get; set; default = new Serialize.Dict<string> (); }
}

public class TestObjectArrayObject : DataObject {
    public Serialize.Array<SimpleObject> value { get; set; default = new Serialize.Array<SimpleObject> (); }
}

public class TestObjectArrayArray : Object, HasComplexCollections {
    public Serialize.Array<Serialize.Array<SimpleObject>> value { get; set; default = new Serialize.Array<Serialize.Array<SimpleObject>> (); }

    public CollectionFactory[] collection_factories (string property_name) {
        if (property_name == "value") {
            return {
                new Serialize.Array<Serialize.Array> (),
                new Serialize.Array<SimpleObject> ()
            };
        }
        return {};
    }
}

public class TestObjectAlbum : DataObject, HasComplexCollections {
    public Serialize.Array<Serialize.Array<TestObjectInt>> value { get; set; default = new Serialize.Array<Serialize.Array<TestObjectInt>> (); }

    public CollectionFactory[] collection_factories (string property_name) {
        if (property_name == "value") {
            return {
                new Serialize.Array<Serialize.Array> (),
                new Serialize.Array<TestObjectInt> ()
            };
        }
        return {};
    }
}

public class TestObjectAlbum2 : DataObject, HasComplexCollections {
    public Serialize.Array<Serialize.Array<Serialize.Dict<int>>> value { get; set; }

    public CollectionFactory[] collection_factories (string property_name) {
        if (property_name == "value") {
            return {
                new Serialize.Array<Serialize.Array> (),
                new Serialize.Array<Serialize.Dict> (),
                new Serialize.Dict<int> ()
            };
        }
        return {};
    }
}

public class TestObjectFamilyParent : Object, YamlTypeFamily {
    public GLib.Type match_type_yaml (Serialize.YamlValue node) {
        foreach (var pair in node.mapping_pairs) {
            if (pair.key.node_type == Yaml.NodeType.SCALAR && pair.key.scalar == "type") {
                if (pair.value.node_type == Yaml.NodeType.SCALAR && pair.value.scalar == "child") {
                    return typeof (TestObjectFamilyChild);
                }
                break;
            }
        }
        return typeof (TestObjectFamilyParent);
    }
}

public class TestObjectFamilyChild : TestObjectFamilyParent {}

public class TestObjectDeserializeFallback : Object, HasFallback {
    public string string_val { get; set; }
    public int64 int64_val { get; set; }
    public Dict<Value?> serialize_fallback { get; set; }
}

public class TestObjectWithNestedObjects : Object {
    public TestObjectWithNestedObjects child_typed { get; set; }
    public Object child_any { get; set; }
}

public class TestObjectString : DataObject {
    public string? value { get; set; }
}

public class TestObjectInt : DataObject {
    public int value { get; set; }
}

public class TestObjectDouble : DataObject {
    public double value { get; set; }
}

public class TestObjectEnum : Object {
    public TestEnum value { get; set; }
}

public class TestObjectStringCamel : Object {
    public string string_value { get; set; }
}

public class TestObjectStringCamelW : Object {
    [Description (nick="string-value")]
    public string string_value_ { get; set; }
}

public class TestObjectDateTime : Object {
    public DateTime value { get; set; }
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

string double_to_str (double d) {
    return "%.15g".printf (d);
}

string get_exp_yaml (Case c) {
    return string.joinv ("\n", {
        "application:",
        @"  $(get_name_with_c (STRING_VAL_NAME, c)): $STRING_VAL",
        @"  $(get_name_with_c (INT64_VAL_NAME, c)): $INT64_VAL",
        @"  $(get_name_with_c (INT_VAL_NAME, c)): $INT_VAL",
        @"  $(get_name_with_c (DOUBLE_VAL_NAME, c)): $(double_to_str (DOUBLE_VAL))",
        @"  $(get_name_with_c (BOOL_VAL_NAME, c)): $BOOL_VAL",
        "context:",
        @"  $(get_name_with_c (STRINGS_VAL_NAME, c)):",
        @"  - $(STRINGS_VAL[0])",
        @"  - $(STRINGS_VAL[1])",
        @"  - $(STRINGS_VAL[2])",
        @"  $(get_name_with_c (ENUM_VAL_NAME, c)): 1",
        @"  $(get_name_with_c (TYPE__NAME, c)): $TYPE_",
        "",
    });
}

string get_exp_yaml2 (Case c) {
    return string.joinv ("\n", {
        "application:",
        @"  $(get_name_with_c (STRING_VAL_NAME, c)): $STRING_VAL",
        @"  $(get_name_with_c (INT64_VAL_NAME, c)): $INT64_VAL",
        @"  $(get_name_with_c (INT_VAL_NAME, c)): $INT_VAL",
        @"  $(get_name_with_c (DOUBLE_VAL_NAME, c)): $(double_to_str (DOUBLE_VAL))",
        @"  $(get_name_with_c (BOOL_VAL_NAME, c)): $BOOL_VAL",
        "context:",
        @"  $(get_name_with_c (STRINGS_VAL_NAME, c)):",
        @"  - $(STRINGS_VAL[0])",
        @"  - $(STRINGS_VAL[1])",
        @"  - $(STRINGS_VAL[2])",
        @"  $(get_name_with_c (ENUM_VAL_NAME, c)): value2",
        @"  $(get_name_with_c (TYPE__NAME, c)): $TYPE_",
        "",
    });
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/yaml/serialize/values", () => {
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

            string expectation = get_exp_yaml (c);
            var result = YamlWorker.serialize (test_object, new Serialize.Settings () {
                names_case = c
            });

            if (result != expectation) {
                Test.fail_printf (result + "\n!=\n" + expectation);
            }
        }
    });

    Test.add_func ("/yaml/serialize/values2", () => {
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

            string expectation = get_exp_yaml2 (c);
            var result = YamlWorker.serialize (test_object, new Serialize.Settings () {
                names_case = c,
                enum_serialize_method = STRING,
                enum_serialize_case = CAMEL
            });

            if (result != expectation) {
                Test.fail_printf (result + "\n!=\n" + expectation);
            }
        }
    });

    Test.add_func ("/yaml/deserialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            string yaml = get_exp_yaml (c);

            ValuesData result;

            try {
                result = YamlWorker.simple_from_yaml<ValuesData> (yaml, null, new Serialize.Settings () { names_case = c });
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

    // === Array<string> tests ===

    Test.add_func ("/yaml/serialize/array/string", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = string.joinv ("\n", {
            "value:",
            "- everything that lives is designed to end",
            "- we are perpetually trapped in a neverending spyral of life and death",
            "- is this a curse?",
            "- or some kind of punishment?",
            "- i often thinking about the god who blessed us with this cryptic puzzle",
            "- and wonder if we'll ever have a chance to kill him",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/deserialize/array/string", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- kekw",
                "- yes",
                "- no",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectArrayString> ();

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/string/strv", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- kekw",
                "- yes",
                "- no",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectArrayStringStrv> ();

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/string/strv/empty", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectArrayStringStrv> ();

            if (result.value.length != 0) {
                Test.fail_printf (string.joinv (", ", result.value) + " != ");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/string/strv/not-present", () => {
        try {
            var yaml = string.joinv ("\n", {
                "other: value",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectArrayStringStrv> ();

            if (result.value.length != 0) {
                Test.fail_printf (string.joinv (", ", result.value) + " != ");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Dict<string> tests ===

    Test.add_func ("/yaml/serialize/dict/string", () => {
        var expected_yaml = string.joinv ("\n", {
            "value:",
            "  kekw: yes",
            "  kek: no",
            "",
        });

        var obj = new TestObjectDictString ();
        obj.value.set ("kekw", "yes");
        obj.value.set ("kek", "no");

        var result = YamlWorker.serialize (obj);

        if (result != expected_yaml) {
            Test.fail_printf (@"$result != $expected_yaml");
        }
    });

    Test.add_func ("/yaml/deserialize/dict/string", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "  kekw: yes",
                "  kek: no",
                "",
            });

            var result = YamlWorker.simple_from_yaml<TestObjectDictString> (yaml);

            if (result.value["kekw"] != "yes" || result.value["kek"] != "no") {
                Test.fail_printf ("");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Array<SimpleObject> tests ===

    Test.add_func ("/yaml/serialize/array/object", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new SimpleObject () { bool_value = false });
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "kekw" });
        test_object.value.add (new SimpleObject ());

        string expectation = string.joinv ("\n", {
            "value:",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: why are we still here",
            "  int-value: 42",
            "  bool-value: false",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: kekw",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/deserialize/array/object", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- string-value: Baby one more time",
                "  int-value: 42",
                "  bool-value: true",
                "- string-value: I want it that way",
                "  int-value: 17",
                "  bool-value: false",
                "- string-value: Gonna make you sweat",
                "  int-value: 99",
                "  bool-value: true",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectArrayObject> ();

            if (result.value[0].string_value != "Baby one more time" || result.value[1].int_value != 17 || result.value[2].bool_value != true) {
                Test.fail_printf (
                    result.value[0].string_value + " != Baby one more time\n" +
                    result.value[1].int_value.to_string () + " != 17\n" +
                    result.value[2].bool_value.to_string () + " != true"
                );
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Array<Array<SimpleObject>> tests ===

    Test.add_func ("/yaml/serialize/array/array", () => {
        var test_object = new TestObjectArrayArray ();
        test_object.value.add (new Serialize.Array<SimpleObject> ());
        test_object.value.add (new Serialize.Array<SimpleObject> ());
        test_object.value.add (new Serialize.Array<SimpleObject> ());
        test_object.value[0].add (new SimpleObject ());
        test_object.value[0].add (new SimpleObject ());
        test_object.value[1].add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value[1].add (new SimpleObject () { bool_value = false });
        test_object.value[1].add (new SimpleObject () { string_value = "kekw" });
        test_object.value[2].add (new SimpleObject () { int_value = 56 });

        string expectation = string.joinv ("\n", {
            "value:",
            "- - string-value: null",
            "    int-value: 0",
            "    bool-value: false",
            "  - string-value: null",
            "    int-value: 0",
            "    bool-value: false",
            "- - string-value: why are we still here",
            "    int-value: 42",
            "    bool-value: false",
            "  - string-value: null",
            "    int-value: 0",
            "    bool-value: false",
            "  - string-value: kekw",
            "    int-value: 0",
            "    bool-value: false",
            "- - string-value: null",
            "    int-value: 56",
            "    bool-value: false",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    // === HasComplexCollections tests ===

    Test.add_func ("/yaml/deserialize/array/array/album", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- - value: 7",
                "- - value: 98",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectAlbum> ();

            if (result.value[0][0].value != 7 || result.value[1][0].value != 98) {
                Test.fail_printf (
                    result.value[0][0].value.to_string () + " != 7 || " +
                    result.value[1][0].value.to_string () + " != 98\n"
                );
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/array/album2", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- - value: 7",
                "- - value: 98",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectAlbum2> ();

            if (result.value[0][0]["value"] != 7 || result.value[1][0]["value"] != 98) {
                Test.fail_printf (
                    result.value[0][0]["value"].to_string () + " != 7\n" +
                    result.value[1][0]["value"].to_string () + " != 98\n"
                );
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === TypeFamily tests ===

    Test.add_func ("/yaml/deserialize/object/runtime_type/child", () => {
        try {
            var yaml = string.joinv ("\n", {
                "type: child",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectFamilyParent> ();

            if (!(result is TestObjectFamilyChild)) {
                Test.fail_printf ("%s != %s", result.get_type ().name (), typeof(TestObjectFamilyChild).name());
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/object/runtime_type/parent", () => {
        try {
            var yaml = string.joinv ("\n", {
                "type: any-other-thing",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectFamilyParent> ();

            if (!(result is TestObjectFamilyParent)) {
                Test.fail_printf ("%s != %s", result.get_type ().name (), typeof(TestObjectFamilyParent).name());
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === HasFallback tests ===

    Test.add_func ("/yaml/deserialize/object/fallback", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            string yaml = get_exp_yaml (c);

            TestObjectDeserializeFallback result;

            try {
                result = YamlWorker.simple_from_yaml<TestObjectDeserializeFallback> (yaml, null, new Serialize.Settings () { names_case = c });
            } catch (GLib.Error e) {
                Test.fail_printf (e.message);
                return;
            }
            var result_ser = YamlWorker.serialize (result, new Serialize.Settings () { names_case = c });

            // Compare by splitting into lines and checking each expected line is present
            var expectation_lines = yaml.split ("\n");
            var result_lines = result_ser.split ("\n");

            foreach (var line in expectation_lines) {
                if (line.length > 0 && !(line in result_lines)) {
                    Test.fail_printf (result_ser + " != " + yaml + " (missing: " + line + ")");
                }
            }
        }
    });

    // === Nested objects tests ===

    Test.add_func ("/yaml/serialize/object-with-nested-childs", () => {
        var test_object = new TestObjectWithNestedObjects () {
            child_typed = new TestObjectWithNestedObjects () {
                child_any = new TestObjectWithNestedObjects ()
            }
        };
        string expectation = string.joinv ("\n", {
            "child-typed:",
            "  child-typed: null",
            "  child-any:",
            "    child-typed: null",
            "    child-any: null",
            "child-any: null",
            "",
        });
        string result = YamlWorker.serialize (test_object, new Serialize.Settings ());
        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    // === Data conversion tests ===

    Test.add_func ("/yaml/deserialize/int_to_string", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: 6",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectString> ();

            if (result.value != "6") {
                Test.fail_printf (result.value + " != \"6\"");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/int_to_double", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: 6",
                "",
            });

            var result = YamlWorker.simple_from_yaml<TestObjectDouble> (yaml);

            if (result.value != 6.0) {
                Test.fail_printf (@"$(result.value) != 6.0");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Enum deserialization tests ===

    Test.add_func ("/yaml/deserialize/enum", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: value_2",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectEnum> ();

            if (result.value != TestEnum.VALUE_2) {
                Test.fail_printf (result.value.to_string () + " != " + TestEnum.VALUE_2.to_string ());
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Null handling tests ===

    Test.add_func ("/yaml/serialize/null", () => {
        var test_object = new TestObjectString ();
        test_object.value = null;

        string expectation = string.joinv ("\n", {
            "value: null",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    // === Error handling tests ===

    Test.add_func ("/yaml/deserialize/empty", () => {
        try {
            var worker = new YamlWorker ("");
            Test.fail_printf ("Should have thrown EMPTY error");
        } catch (Serialize.Error e) {
            if (e is Serialize.Error.EMPTY) {
                // Expected
            } else {
                Test.fail_printf ("Expected EMPTY error, got: " + e.message);
            }
        }
    });

    Test.add_func ("/yaml/deserialize/not_valid_path", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var worker = new YamlWorker (yaml, {"value1"});
            worker.deserialize_value ();

            Test.fail_printf ("Value parsed without error");
        } catch (Serialize.Error e) {
            // Expected
        }
    });

    // === Serialize simple object tests ===

    Test.add_func ("/yaml/serialize/yam_obj", () => {
        var test_object = new SimpleObject ();
        test_object.string_value = "test";
        test_object.int_value = 42;
        test_object.bool_value = true;

        string expectation = string.joinv ("\n", {
            "string-value: test",
            "int-value: 42",
            "bool-value: true",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/yam_obj/uni", () => {
        var test_object = new Dict<Value?> ();
        test_object["string-value"] = "test";
        test_object["int-value"] = 42;
        test_object["bool-value"] = true;

        string expectation = string.joinv ("\n", {
            "string-value: test",
            "int-value: 42",
            "bool-value: true",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        var expectation_lines = expectation.split ("\n");
        var result_lines = result.split ("\n");

        foreach (var line in expectation_lines) {
            if (line.length > 0 && !(line in result_lines)) {
                Test.fail_printf (result + " != " + expectation + " (missing: " + line + ")");
            }
        }
    });

    // === Serialize string[] tests ===

    Test.add_func ("/yaml/serialize/array/string/strv", () => {
        var test_object = new TestObjectArrayStringStrv ();
        test_object.value = {
            "everything that lives is designed to end",
            "we are perpetually trapped in a neverending spyral of life and death",
            "is this a curse?",
            "or some kind of punishment?",
            "i often thinking about the god who blessed us with this cryptic puzzle",
            "and wonder if we'll ever have a chance to kill him"
        };

        string expectation = string.joinv ("\n", {
            "value:",
            "- everything that lives is designed to end",
            "- we are perpetually trapped in a neverending spyral of life and death",
            "- is this a curse?",
            "- or some kind of punishment?",
            "- i often thinking about the god who blessed us with this cryptic puzzle",
            "- and wonder if we'll ever have a chance to kill him",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/array/string/strv/empty", () => {
        var test_object = new TestObjectArrayStringStrv ();
        test_object.value = {};

        string expectation = string.joinv ("\n", {
            "value: []",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/array/string/strv/non-present", () => {
        var test_object = new TestObjectArrayStringStrv ();

        string expectation = string.joinv ("\n", {
            "value: []",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/array/object2", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new SimpleObject () { bool_value = false });
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "kekw" });
        test_object.value.add (new SimpleObject ());

        string expectation = string.joinv ("\n", {
            "value:",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: why are we still here",
            "  int-value: 42",
            "  bool-value: false",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: kekw",
            "  int-value: 0",
            "  bool-value: false",
            "- string-value: null",
            "  int-value: 0",
            "  bool-value: false",
            "",
        });
        string result = test_object.to_yaml ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/array/array/without-default", () => {
        var test_object = new TestObjectArrayArray ();
        test_object.value.add (new Serialize.Array<SimpleObject> ());
        test_object.value.add (new Serialize.Array<SimpleObject> ());
        test_object.value.add (new Serialize.Array<SimpleObject> ());
        test_object.value[0].add (new SimpleObject ());
        test_object.value[0].add (new SimpleObject ());
        test_object.value[1].add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value[1].add (new SimpleObject () { bool_value = false });
        test_object.value[1].add (new SimpleObject () { string_value = "kekw" });
        test_object.value[2].add (new SimpleObject () { int_value = 56 });

        string expectation = string.joinv ("\n", {
            "value:",
            "- - {}",
            "  - {}",
            "- - string-value: why are we still here",
            "    int-value: 42",
            "  - {}",
            "  - string-value: kekw",
            "- - int-value: 56",
            "",
        });
        string result = YamlWorker.serialize (test_object, new Serialize.Settings () { ignore_default = true });

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/object/fallback/empty", () => {
        string expected_yaml = string.joinv ("\n", {
            "stringVal: test",
            "int64Val: 54",
            "",
        });

        TestObjectDeserializeFallback result = new TestObjectDeserializeFallback ();
        result.string_val = "test";
        result.int64_val = 54;

        var result_ser = YamlWorker.serialize (result, new Serialize.Settings () { names_case = CAMEL });

        var expectation_lines = expected_yaml.split ("\n");
        var result_lines = result_ser.split ("\n");

        foreach (var line in expectation_lines) {
            if (line.length > 0 && !(line in result_lines)) {
                Test.fail_printf (result_ser + " != " + expected_yaml + " (missing: " + line + ")");
            }
        }
    });

    // === Bad yaml tests ===

    Test.add_func ("/yaml/deserialize/bad-yaml", () => {
        try {
            var worker = new YamlWorker ("{not_valid: yaml");
            worker.deserialize_value ();

            Test.fail_printf ("Value parsed without error");
        } catch (Serialize.Error e) {
            // Expected
        }
    });

    // === Deserialize value tests ===

    Test.add_func ("/yaml/deserialize/value", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var worker = new YamlWorker (yaml, {"value"});

            string result = worker.deserialize_value ().get_string ();

            if (result != "test") {
                Test.fail_printf (result + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Camel case tests ===

    Test.add_func ("/yaml/deserialize/object_camel", () => {
        try {
            var yaml = string.joinv ("\n", {
                "stringValue: test",
                "",
            });
            var worker = new YamlWorker (yaml, null, new Serialize.Settings () { names_case = Case.CAMEL });
            var result = worker.deserialize_object<TestObjectStringCamel> ();

            if (result.string_value != "test") {
                Test.fail_printf (result.string_value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/object_camel_", () => {
        try {
            var yaml = string.joinv ("\n", {
                "stringValue: test",
                "",
            });
            var worker = new YamlWorker (yaml, null, new Serialize.Settings () { names_case = Case.CAMEL });
            var result = worker.deserialize_object<TestObjectStringCamelW> ();

            if (result.string_value_ != "test") {
                Test.fail_printf (result.string_value_ + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Direct array/dict deserialization tests ===

    Test.add_func ("/yaml/deserialize/array/direct", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- kekw",
                "- yes",
                "- no",
                "",
            });
            var worker = new YamlWorker (yaml, {"value"});
            var array = worker.deserialize_array<string> ();

            if (array[0] != "kekw" || array[1] != "yes" || array[2] != "no") {
                Test.fail_printf (string.joinv (", ", array.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/object/uni", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize ();

            if (result["value"].get_string () != "test") {
                Test.fail_printf (result["value"].get_string () + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/object2", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var result = YamlWorker.simple_from_yaml<TestObjectString> (yaml);

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/object2", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- string-value: Baby one more time",
                "  int-value: 42",
                "  bool-value: true",
                "- string-value: I want it that way",
                "  int-value: 17",
                "  bool-value: false",
                "- string-value: Gonna make you sweat",
                "  int-value: 99",
                "  bool-value: true",
                "",
            });
            var result = YamlWorker.simple_from_yaml<TestObjectArrayObject> (yaml);

            if (result.value[0].string_value != "Baby one more time" || result.value[1].int_value != 17 || result.value[2].bool_value != true) {
                Test.fail_printf (
                    result.value[0].string_value + " != Baby one more time\n" +
                    result.value[1].int_value.to_string () + " != 17 || " +
                    result.value[2].bool_value.to_string () + " != true"
                );
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/array", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- - string-value: null",
                "    int-value: 0",
                "    bool-value: false",
                "  - string-value: null",
                "    int-value: 0",
                "    bool-value: false",
                "- - string-value: why are we still here",
                "    int-value: 42",
                "    bool-value: false",
                "  - string-value: null",
                "    int-value: 0",
                "    bool-value: false",
                "  - string-value: kekw",
                "    int-value: 0",
                "    bool-value: false",
                "- - string-value: null",
                "    int-value: 56",
                "    bool-value: false",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectArrayArray> ();

            if (result.value[0][0].string_value != null || result.value[1][0].string_value != "why are we still here" || result.value[2][0].int_value != 56) {
                Test.fail_printf (
                    result.value[0][0].string_value + " != null || " +
                    result.value[1][0].string_value + " != why are we still here || " +
                    result.value[2][0].int_value.to_string () + " != 56"
                );
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/dict/string/direct", () => {
        try {
            var yaml = string.joinv ("\n", {
                "kekw: yes",
                "kek: no",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_dict<string> ();

            if (result["kekw"] != "yes" || result["kek"] != "no") {
                Test.fail_printf ("");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/simple_deserialize", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var result = YamlWorker.simple_deserialize (yaml);

            if (result["value"].get_string () != "test") {
                Test.fail_printf (result["value"].get_string () + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/simple_array", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- kekw",
                "- yes",
                "- no",
                "",
            });
            var result = YamlWorker.simple_array_from_yaml<string> (yaml, {"value"});

            if (result[0] != "kekw" || result[1] != "yes" || result[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/simple_dict", () => {
        try {
            var yaml = string.joinv ("\n", {
                "kekw: yes",
                "kek: no",
                "",
            });
            var result = YamlWorker.simple_dict_from_yaml<string> (yaml);

            if (result["kekw"] != "yes" || result["kek"] != "no") {
                Test.fail_printf ("");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === Constructor tests ===

    Test.add_func ("/yaml/deserialize/from_bytes", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var bytes = new Bytes (yaml.data);
            var worker = new YamlWorker.from_bytes (bytes);
            var result = worker.deserialize_object<TestObjectString> ();

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/from_data", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var worker = new YamlWorker.from_data (yaml.data);
            var result = worker.deserialize_object<TestObjectString> ();

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    // === DateTime tests ===

    Test.add_func ("/yaml/deserialize/datetime", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: 2024-01-15T10:30:00Z",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectDateTime> ();

            var expected = new DateTime.from_iso8601 ("2024-01-15T10:30:00Z", new TimeZone.utc ());
            if (result.value == null || result.value.to_unix () != expected.to_unix ()) {
                Test.fail_printf ("DateTime deserialization failed");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/serialize/datetime", () => {
        var test_object = new TestObjectDateTime ();
        test_object.value = new DateTime.from_iso8601 ("2024-01-15T10:30:00Z", new TimeZone.utc ());

        string expectation = string.joinv ("\n", {
            "value: 2024-01-15T10:30:00Z",
            "",
        });
        string result = YamlWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    // === Missing JSON parity tests ===

    Test.add_func ("/yaml/deserialize/object", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value: test",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize_object<TestObjectString> ();

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/string2", () => {
        try {
            var result = YamlWorker.simple_from_yaml<TestObjectArrayString> (string.joinv ("\n", {
                "value:",
                "- kekw",
                "- yes",
                "- no",
                "",
            }));

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/array/string/uni", () => {
        try {
            var yaml = string.joinv ("\n", {
                "value:",
                "- kekw",
                "- yes",
                "- no",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize ();

            var arr = (Serialize.Array<Value?>) result["value"].get_object ();

            if (arr[0].get_string () != "kekw" || arr[1].get_string () != "yes" || arr[2].get_string () != "no") {
                Test.fail_printf ("Failed");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/serialize/array/string2", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = string.joinv ("\n", {
            "value:",
            "- everything that lives is designed to end",
            "- we are perpetually trapped in a neverending spyral of life and death",
            "- is this a curse?",
            "- or some kind of punishment?",
            "- i often thinking about the god who blessed us with this cryptic puzzle",
            "- and wonder if we'll ever have a chance to kill him",
            "",
        });
        string result = test_object.to_yaml ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/yaml/serialize/dict/string/direct", () => {
        var expected_yaml = string.joinv ("\n", {
            "kekw: yes",
            "kek: no",
            "",
        });

        var obj = new Serialize.Dict<string> ();
        obj.set ("kekw", "yes");
        obj.set ("kek", "no");

        var result = YamlWorker.serialize (obj);

        if (result != expected_yaml) {
            Test.fail_printf (@"$result != $expected_yaml");
        }
    });

    // === Anchor tests ===

    Test.add_func ("/yaml/deserialize/anchor", () => {
        try {
            var yaml = string.joinv ("\n", {
                "foo: &bar",
                "  x: 1",
                "  y: 2",
                "baz: *bar",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize ();

            var foo = result["foo"].get_object () as Dict<Value?>;
            var baz = result["baz"].get_object () as Dict<Value?>;

            if (foo == null || baz == null) {
                Test.fail_printf ("foo or baz is null");
                return;
            }

            if (foo["x"].get_string () != "1" || baz["x"].get_string () != "1") {
                Test.fail_printf ("anchor values mismatch");
            }
            if (foo["y"].get_string () != "2" || baz["y"].get_string () != "2") {
                Test.fail_printf ("anchor values mismatch");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/yaml/deserialize/anchor/circular", () => {
        try {
            var yaml = string.joinv ("\n", {
                "foo: &bar",
                "  self: *bar",
                "",
            });
            var worker = new YamlWorker (yaml);
            var result = worker.deserialize ();

            //  Circular references are currently not supported.
            //  If we reach here without error, it means the circular
            //  reference was handled gracefully (best effort).
            var foo = result["foo"].get_object () as Dict<Value?>;
            if (foo == null) {
                Test.fail_printf ("foo is null");
                return;
            }
        } catch (Serialize.Error e) {
            //  Expected: circular references cause INVALID or EMPTY error
            //  instead of a crash
            if (!(e is Serialize.Error.INVALID) && !(e is Serialize.Error.EMPTY)) {
                Test.fail_printf (e.domain.to_string () + ": " + e.message);
            }
        }
    });

    return Test.run ();
}
