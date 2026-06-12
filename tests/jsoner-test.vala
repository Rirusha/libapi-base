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

// ind-check=skip-file
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
const string ENUM_VAL_NAME = "enum-val";
const TestEnum ENUM_VAL = VALUE_2;
const string TYPE__NAME = "type";
const string TYPE_ = "some text";
const string ERROR_CODE_NAME = "error-code";
const int ERROR_CODE = 6;
const string CUSTOM_NICK_VAL_NAME = "renamed-val";
const string CUSTOM_NICK_VAL = "renamed";

public class ValuesData : DataObject {
    public string string_val { get; set; }
    public int64 int64_val { get; set; }
    public int int_val { get; set; }
    public double double_val { get; set; }
    public bool bool_val { get; set; }
    public TestEnum enum_val { get; set; }

    // Strange names

    // Property with 'type' name cannot exists
    [Description (nick="type")]
    public string type_ { get; set; }
    // The issue is lost, but there was an error about incorrect deserialization of "error_code"
    public int error_code { get; set; }

    // Property with custom nick
    [Description (nick="renamed-val")]
    public string custom_nick_val { get; set; }
}

public class TestObjectString : DataObject {
    public string? value { get; set; }
}

public class TestObjectStringCamel : Object {
    public string string_value { get; set; }
}

public class TestObjectStringCamelW : Object {
    [Description (nick="string-value")]
    public string string_value_ { get; set; }
}

public class TestObjectInt64 : Object {
    public int64 value { get; set; }
}

public class TestObjectInt : DataObject {
    public int value { get; set; }
}

public class TestObjectBool : Object {
    public bool value { get; set; }
}

public class TestObjectDouble : DataObject {
    public double value { get; set; }
}

public enum TestEnum {
    VALUE1 = 0,
    VALUE_2 = 1,
}

public class TestObjectEnum : Object {
    public TestEnum value { get; set; }
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

public class TestObjectArrayArray : Object {
    public Serialize.Array<Serialize.Array<SimpleObject>> value { get; set; default = new Serialize.Array<Serialize.Array<SimpleObject>> (); }
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

public class TestObjectFamilyParent: Object, JsonTypeFamily {
    public GLib.Type match_type_json (Json.Node node) {
        switch (node.get_object ().get_string_member ("type")) {
            case "child":
                return typeof (TestObjectFamilyChild);
            default:
                return typeof (TestObjectFamilyParent);
        }
    }
}
public class TestObjectFamilyChild: TestObjectFamilyParent {}

public class TestObjectDeserializeFallback: Object, HasFallback {
    // Fields that should be deserialized successfuly
    public string string_val { get; set; }
    public int64 int64_val { get; set; }
    // Other (fallback) fields
    public Dict<Value?> serialize_fallback { get; set; }
}

public class TestObjectWithNestedObjects: Object {
    public TestObjectWithNestedObjects child_typed { get; set; }
    public Object child_any { get; set; }
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

string get_exp_json (Case c) {
    return "{%s}".printf (string.joinv (",", {
        @"\"$(get_name_with_c (STRING_VAL_NAME, c))\":\"$STRING_VAL\"",
        @"\"$(get_name_with_c (INT64_VAL_NAME, c))\":$INT64_VAL",
        @"\"$(get_name_with_c (INT_VAL_NAME, c))\":$INT_VAL",
        @"\"$(get_name_with_c (DOUBLE_VAL_NAME, c))\":$DOUBLE_VAL",
        @"\"$(get_name_with_c (BOOL_VAL_NAME, c))\":$BOOL_VAL",
        @"\"$(get_name_with_c (ENUM_VAL_NAME, c))\":1",
        @"\"$(get_name_with_c (TYPE__NAME, c))\":\"$TYPE_\"",
        @"\"$(get_name_with_c (ERROR_CODE_NAME, c))\":$ERROR_CODE",
        @"\"$(get_name_with_c (CUSTOM_NICK_VAL_NAME, c))\":\"$CUSTOM_NICK_VAL\"",
    }));
}

string get_exp_json2 (Case c) {
    return "{%s}".printf (string.joinv (",", {
        @"\"$(get_name_with_c (STRING_VAL_NAME, c))\":\"$STRING_VAL\"",
        @"\"$(get_name_with_c (INT64_VAL_NAME, c))\":$INT64_VAL",
        @"\"$(get_name_with_c (INT_VAL_NAME, c))\":$INT_VAL",
        @"\"$(get_name_with_c (DOUBLE_VAL_NAME, c))\":$DOUBLE_VAL",
        @"\"$(get_name_with_c (BOOL_VAL_NAME, c))\":$BOOL_VAL",
        @"\"$(get_name_with_c (ENUM_VAL_NAME, c))\":\"value2\"",
        @"\"$(get_name_with_c (TYPE__NAME, c))\":\"$TYPE_\"",
        @"\"$(get_name_with_c (ERROR_CODE_NAME, c))\":$ERROR_CODE",
        @"\"$(get_name_with_c (CUSTOM_NICK_VAL_NAME, c))\":\"$CUSTOM_NICK_VAL\"",
    }));
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/json/serialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var test_object = new ValuesData ();

            test_object.string_val = STRING_VAL;
            test_object.int64_val = INT64_VAL;
            test_object.int_val = INT_VAL;
            test_object.double_val = DOUBLE_VAL;
            test_object.bool_val = BOOL_VAL;
            test_object.enum_val = ENUM_VAL;
            test_object.type_ = TYPE_;
            test_object.error_code = ERROR_CODE;
            test_object.custom_nick_val = CUSTOM_NICK_VAL;

            string expectation = get_exp_json (c);
            var result = JsonWorker.serialize (test_object, new Serialize.Settings () {
                names_case = c
            });

            if (result != expectation) {
                Test.fail_printf (result + "\n!=\n" + expectation);
            }
        }
    });

    Test.add_func ("/json/deserialize/big", () => {
        try {
            var res = resources_lookup_data ("/test-data/big.json", ResourceLookupFlags.NONE);
            var worker = new JsonWorker.from_bytes (res);
            var result = worker.deserialize ();
            JsonWorker.serialize (result);
        } catch (GLib.Error e) {
            Test.fail_printf (e.message);
        }
    });

    Test.add_func ("/json/serialize/values2", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var test_object = new ValuesData ();

            test_object.string_val = STRING_VAL;
            test_object.int64_val = INT64_VAL;
            test_object.int_val = INT_VAL;
            test_object.double_val = DOUBLE_VAL;
            test_object.bool_val = BOOL_VAL;
            test_object.enum_val = ENUM_VAL;
            test_object.type_ = TYPE_;
            test_object.error_code = ERROR_CODE;
            test_object.custom_nick_val = CUSTOM_NICK_VAL;

            string expectation = get_exp_json2 (c);
            var result = JsonWorker.serialize (test_object, new Serialize.Settings () {
                names_case = c,
                enum_serialize_method = STRING,
                enum_serialize_case = CAMEL
            });

            if (result != expectation) {
                Test.fail_printf (result + "\n!=\n" + expectation);
            }
        }
    });

    Test.add_func ("/json/deserialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            string json = get_exp_json (c);

            ValuesData result;

            try {
                result = JsonWorker.simple_from_json<ValuesData> (json, null, new Serialize.Settings () { names_case = c });
            } catch (GLib.Error e) {
                Test.fail_printf (e.message);
                return;
            }

            if (result.string_val != STRING_VAL) {
                Test.fail_printf (@"$(result.string_val) != $(STRING_VAL)");
            }
            if (result.int64_val != INT64_VAL) {
                Test.fail_printf (@"$(result.int64_val) != $(INT64_VAL)");
            }
            if (result.int_val != INT64_VAL) {
                Test.fail_printf (@"$(result.int_val) != $(INT64_VAL)");
            }
            if (result.double_val != DOUBLE_VAL) {
                Test.fail_printf (@"$(result.double_val) != $(DOUBLE_VAL)");
            }
            if (result.bool_val != BOOL_VAL) {
                Test.fail_printf (@"$(result.bool_val) != $(BOOL_VAL)");
            }
            if (result.enum_val != ENUM_VAL) {
                Test.fail_printf (@"$(result.enum_val) != $(ENUM_VAL)");
            }
            if (result.type_ != TYPE_) {
                Test.fail_printf (@"$(result.type_) != $(TYPE_)");
            }
            if (result.error_code != ERROR_CODE) {
                Test.fail_printf (@"$(result.error_code) != $(ERROR_CODE)");
            }
            if (result.custom_nick_val != CUSTOM_NICK_VAL) {
                Test.fail_printf (@"$(result.custom_nick_val) != $(CUSTOM_NICK_VAL)");
            }
        }
    });

    Test.add_func ("/json/serialize/null", () => {
        var test_object = new TestObjectString ();
        test_object.value = null;

        string expectation = "{\"value\":null}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/yam_obj", () => {
        var test_object = new SimpleObject ();
        test_object.string_value = "test";
        test_object.int_value = 42;
        test_object.bool_value = true;

        string expectation = "{\"string-value\":\"test\",\"int-value\":42,\"bool-value\":true}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/yam_obj/uni", () => {
        var test_object = new Dict<Value?> ();
        test_object["string-value"] = "test";
        test_object["int-value"] = 42;
        test_object["bool-value"] = true;

        string expectation = "{\"string-value\":\"test\",\"int-value\":42,\"bool-value\":true}";
        string result = JsonWorker.serialize (test_object);

        var expectation_arr = expectation[1:expectation.length - 1].split (",");
        var result_arr = result[1:result.length - 1].split (",");

        foreach (var pair in expectation_arr) {
            if (!(pair in result_arr)) {
                Test.fail_printf (result + " != " + expectation);
            }
        }
    });

    Test.add_func ("/json/deserialize/bad-json", () => {
        var json = "{\"string-value\":\"test\",\"int_value\":42,\"boolValue\":true}";

        SimpleObject obj;
        try {
            obj = JsonWorker.simple_from_json<SimpleObject> (json);
        } catch (Serialize.Error e) {
            Test.skip (e.domain.to_string () + ": " + e.message);
            return;
        }

        if (
            obj.string_value != "test" ||
            obj.int_value != 42 ||
            obj.bool_value != true
        ) {
            Test.fail ();
        }
    });

    Test.add_func ("/json/serialize/array/string", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = "{\"value\":[\"everything that lives is designed to end\",\"we are perpetually trapped in a neverending spyral of life and death\",\"is this a curse?\",\"or some kind of punishment?\",\"i often thinking about the god who blessed us with this cryptic puzzle\",\"and wonder if we'll ever have a chance to kill him\"]}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/string/strv", () => {
        var test_object = new TestObjectArrayStringStrv ();
        test_object.value = {
            "everything that lives is designed to end",
            "we are perpetually trapped in a neverending spyral of life and death",
            "is this a curse?",
            "or some kind of punishment?",
            "i often thinking about the god who blessed us with this cryptic puzzle",
            "and wonder if we'll ever have a chance to kill him"
        };

        string expectation = "{\"value\":[\"everything that lives is designed to end\",\"we are perpetually trapped in a neverending spyral of life and death\",\"is this a curse?\",\"or some kind of punishment?\",\"i often thinking about the god who blessed us with this cryptic puzzle\",\"and wonder if we'll ever have a chance to kill him\"]}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/string/strv/empty", () => {
        var test_object = new TestObjectArrayStringStrv ();
        test_object.value = {};

        string expectation = "{\"value\":[]}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/string/strv/non-present", () => {
        var test_object = new TestObjectArrayStringStrv ();

        string expectation = "{\"value\":[]}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/dict/string", () => {
        var expected_json = "{\"value\":{\"kekw\":\"yes\",\"kek\":\"no\"}}";

        var obj = new TestObjectDictString ();
        obj.value.set ("kekw", "yes");
        obj.value.set ("kek", "no");

        var result = obj.to_json ();

        if (result != expected_json) {
            Test.fail_printf (@"$result != $expected_json");
        }
    });

    Test.add_func ("/json/serialize/dict/string/direct", () => {
        var expected_json = "{\"kekw\":\"yes\",\"kek\":\"no\"}";

        var obj = new Serialize.Dict<string> ();
        obj.set ("kekw", "yes");
        obj.set ("kek", "no");

        var result = JsonWorker.serialize (obj);

        if (result != expected_json) {
            Test.fail_printf (@"$result != $expected_json");
        }
    });

    Test.add_func ("/json/serialize/array/string2", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = "{\"value\":[\"everything that lives is designed to end\",\"we are perpetually trapped in a neverending spyral of life and death\",\"is this a curse?\",\"or some kind of punishment?\",\"i often thinking about the god who blessed us with this cryptic puzzle\",\"and wonder if we'll ever have a chance to kill him\"]}";
        string result = test_object.to_json ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/object", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new SimpleObject () { bool_value = false });
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "kekw" });
        test_object.value.add (new SimpleObject ());

        string expectation = "{\"value\":[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}]}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/object2", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new SimpleObject () { bool_value = false });
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "kekw" });
        test_object.value.add (new SimpleObject ());

        string expectation = "{\"value\":[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}]}";
        string result = test_object.to_json ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/array", () => {
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

        string expectation = "{\"value\":[[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}],[{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false}],[{\"string-value\":null,\"int-value\":56,\"bool-value\":false}]]}";
        string result = JsonWorker.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/array/array/without-default", () => {
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

        string expectation = "{\"value\":[[{},{}],[{\"string-value\":\"why are we still here\",\"int-value\":42},{},{\"string-value\":\"kekw\"}],[{\"int-value\":56}]]}";
        string result = JsonWorker.serialize (test_object, new Serialize.Settings () { ignore_default = true });

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/serialize/object-with-nested-childs", () => {
        var test_object = new TestObjectWithNestedObjects () {
            child_typed = new TestObjectWithNestedObjects () {
                child_any = new TestObjectWithNestedObjects ()
                // test_typed should be null
            }
            // test_any should be null
        };
        string expectation = "{\"child-typed\":{\"child-typed\":null,\"child-any\":{\"child-typed\":null,\"child-any\":null}},\"child-any\":null}";
        string result = JsonWorker.serialize (test_object, new Serialize.Settings ());
        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/json/deserialize/enum", () => {
        try {
            var worker = new JsonWorker ("{\"value\":\"value_2\"}");
            var result = worker.deserialize_object<TestObjectEnum> ();

            if (result.value != TestEnum.VALUE_2) {
                Test.fail_printf (result.value.to_string () + " != " + TestEnum.VALUE_2.to_string ());
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/value", () => {
        try {
            var worker = new JsonWorker ("{\"value\":\"test\"}", {"value"});

            string result = worker.deserialize_value ().get_string ();

            if (result != "test") {
                Test.fail_printf (result + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/not_valid_path", () => {
        try {
            var worker = new JsonWorker ("{\"value\":\"test\"}", {"value1"});
            worker.deserialize_value ();

            Test.fail_printf ("Value parsed without error");
        } catch (Serialize.Error e) {
            Test.skip (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object", () => {
        try {
            var worker = new JsonWorker ("{\"value\":\"test\"}");
            var result = worker.deserialize_object<TestObjectString> ();

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object/uni", () => {
        try {
            var worker = new JsonWorker ("{\"value\":\"test\"}");
            var result = worker.deserialize ();

            if (result["value"].get_string () != "test") {
                Test.fail_printf (result["value"].get_string () + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object2", () => {
        try {
            var result = JsonWorker.simple_from_json<TestObjectString> ("{\"value\":\"test\"}");

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object_camel", () => {
        try {
            var worker = new JsonWorker ("{\"stringValue\":\"test\"}", null, new Serialize.Settings () { names_case = Case.CAMEL });
            var result = worker.deserialize_object<TestObjectStringCamel> ();

            if (result.string_value != "test") {
                Test.fail_printf (result.string_value + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object_camel_", () => {
        try {
            var worker = new JsonWorker ("{\"stringValue\":\"test\"}", null, new Serialize.Settings () { names_case = Case.CAMEL });
            var result = worker.deserialize_object<TestObjectStringCamelW> ();

            if (result.string_value_ != "test") {
                Test.fail_printf (result.string_value_ + " != test");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/int_to_string", () => {
        try {
            var worker = new JsonWorker ("{\"value\":6}");
            var result = worker.deserialize_object<TestObjectString> ();

            if (result.value != "6") {
                Test.fail_printf (result.value + " != \"6\"");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/int_to_double", () => {
        try {
            var json = "{\"value\":6}";

            var result = JsonWorker.simple_from_json<TestObjectDouble> (json);

            if (result.value != 6.0) {
                Test.fail_printf (@"$(result.value) != 6.0");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/string", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");
            var result = worker.deserialize_object<TestObjectArrayString> ();

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/string/strv", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");
            var result = worker.deserialize_object<TestObjectArrayStringStrv> ();

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/string/strv/empty", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[]}");
            var result = worker.deserialize_object<TestObjectArrayStringStrv> ();

            if (result.value.length != 0) {
                Test.fail_printf (string.joinv (", ", result.value) + " != ");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/string/strv/not-present", () => {
        try {
            var worker = new JsonWorker ("{}");
            var result = worker.deserialize_object<TestObjectArrayStringStrv> ();

            if (result.value.length != 0) {
                Test.fail_printf (string.joinv (", ", result.value) + " != ");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/string/uni", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");
            var result = worker.deserialize ();

            var arr = (Serialize.Array<Value?>) result["value"].get_object ();

            if (arr[0].get_string () != "kekw" || arr[1].get_string () != "yes" || arr[2].get_string () != "no") {
                Test.fail_printf ("Failed");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/dict/string", () => {
        try {
            var json = "{\"value\":{\"kekw\":\"yes\",\"kek\":\"no\"}}";

            var result = JsonWorker.simple_from_json<TestObjectDictString> (json);

            if (result.value["kekw"] != "yes" || result.value["kek"] != "no") {
                Test.fail_printf ("");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/string2", () => {
        try {
            var result = JsonWorker.simple_from_json<TestObjectArrayString> ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/direct", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[\"kekw\",\"yes\",\"no\"]}", {"value"});
            var array = worker.deserialize_array<string> ();

            if (array[0] != "kekw" || array[1] != "yes" || array[2] != "no") {
                Test.fail_printf (string.joinv (", ", array.to_array ()) + " != kekw, yes, no");
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/array/object", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[{\"string-value\":\"Baby one more time\",\"int-value\":42,\"bool-value\":true},{\"string-value\":\"I want it that way\",\"int-value\":17,\"bool-value\":false},{\"string-value\":\"Gonna make you sweat\",\"int-value\":99,\"bool-value\":true}]}");
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

    Test.add_func ("/json/deserialize/array/object2", () => {
        try {
            var result = JsonWorker.simple_from_json<TestObjectArrayObject> ("{\"value\":[{\"string-value\":\"Baby one more time\",\"int-value\":42,\"bool-value\":true},{\"string-value\":\"I want it that way\",\"int-value\":17,\"bool-value\":false},{\"string-value\":\"Gonna make you sweat\",\"int-value\":99,\"bool-value\":true}]}");

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

    Test.add_func ("/json/deserialize/array/array", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[[{\"value\":7}],[{\"value\":98}]]}");
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

    Test.add_func ("/json/deserialize/array/array2", () => {
        try {
            var worker = new JsonWorker ("{\"value\":[[{\"value\":7}],[{\"value\":98}]]}");
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

    Test.add_func ("/json/deserialize/object/runtime_type/child", () => {
        try {
            var worker = new JsonWorker ("{\"type\":\"child\"}");
            var result = worker.deserialize_object<TestObjectFamilyParent> ();

            if (!(result is TestObjectFamilyChild)) {
                Test.fail_printf ("%s != %s", result.get_type ().name (), typeof(TestObjectFamilyChild).name());
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object/runtime_type/parent", () => {
        try {
            var worker = new JsonWorker ("{\"type\":\"any-other-thing\"}");
            var result = worker.deserialize_object<TestObjectFamilyParent> ();

            if (!(result is TestObjectFamilyParent)) {
                Test.fail_printf ("%s != %s", result.get_type ().name (), typeof(TestObjectFamilyParent).name());
            }
        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/json/deserialize/object/fallback", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            string json = get_exp_json (c);

            TestObjectDeserializeFallback result;

            try {
                result = JsonWorker.simple_from_json<TestObjectDeserializeFallback> (json, null, new Serialize.Settings () { names_case = c });
            } catch (GLib.Error e) {
                Test.fail_printf (e.message);
                return;
            }
            var result_ser = JsonWorker.serialize (result, new Serialize.Settings () { names_case = c });

            var expectation_arr = json[1:json.length - 1].split (",");
            var result_arr = result_ser[1:result_ser.length - 1].split (",");

            foreach (var pair in expectation_arr) {
                if (!(pair in result_arr)) {
                    Test.fail_printf (result_ser + " != " + json);
                }
            }
        }
    });

    Test.add_func ("/json/serialize/object/fallback/empty", () => {
        string json = "{\"stringVal\":\"test\",\"int64Val\":54}";

        TestObjectDeserializeFallback result = new TestObjectDeserializeFallback ();
        result.string_val = "test";
        result.int64_val = 54;
        
        var result_ser = JsonWorker.serialize (result, new Serialize.Settings () { names_case = CAMEL });

        var expectation_arr = json[1:json.length - 1].split (",");
        var result_arr = result_ser[1:result_ser.length - 1].split (",");

        foreach (var pair in expectation_arr) {
            if (!(pair in result_arr)) {
                Test.fail_printf (result_ser + " != " + json);
            }
        }
    });

    return Test.run ();
}
