// ind-check=skip-file
// vala-lint=skip-file

using ApiBase;

public class ValuesData : DataObject {
    public string string_val { get; set; }
    public int64 int64_val { get; set; }
    public int int_val { get; set; }
    public double double_val { get; set; }
    public bool bool_val { get; set; }
    public TestEnum enum_val { get; set; }

    //  Strange names

    // Property with 'type' name cannot exists
    public string type_ { get; set; }
}


public class TestObjectString : DataObject {
    public string? value { get; set; }
}

public class TestObjectStringCamel : Object {
    public string string_value { get; set; }
}

public class TestObjectStringCamelW : Object {
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
    VALUE_1,
    VALUE_2,
}

public class TestObjectEnum : Object {
    public TestEnum value { get; set; }
}

public class TestObjectObject : Object {
    public string string_value { get; set; }
    public int int_value { get; set; }
    public bool bool_value { get; set; }
}

public class TestObjectArrayString : DataObject {
    public Gee.ArrayList<string> value { get; set; default = new Gee.ArrayList<string> (); }
}

public class TestObjectDictString : DataObject {
    public Gee.HashMap<string, string> value { get; set; default = new Gee.HashMap<string, string> (); }
}

public class TestObjectArrayObject : DataObject {
    public Gee.ArrayList<TestObjectObject> value { get; set; default = new Gee.ArrayList<TestObjectObject> (); }
}

public class TestObjectArrayArray : Object {
    public Gee.ArrayList<Gee.ArrayList<TestObjectObject>> value { get; set; default = new Gee.ArrayList<Gee.ArrayList<TestObjectObject>> (); }
}

public class TestObjectAlbum : Object {
    public Gee.ArrayList<Gee.ArrayList<TestObjectInt>> value { get; set; default = new Gee.ArrayList<Gee.ArrayList<TestObjectInt>> (); }

    construct {
        value.add (new Gee.ArrayList<TestObjectInt> ());
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/jsoner/serialize/values", () => {
        string test_string_val = "test";
        int64 test_int64_val = 1234;
        int test_int_val = 1234;
        double test_double_val = 45.1;
        bool test_bool_val = true;
        TestEnum test_enum_val = VALUE_2;
        string test_type_ = "some text";

        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var test_object = new ValuesData ();

            test_object.string_val = test_string_val;
            test_object.int64_val = test_int64_val;
            test_object.int_val = test_int_val;
            test_object.double_val = test_double_val;
            test_object.bool_val = test_bool_val;
            test_object.enum_val = test_enum_val;
            test_object.type_ = test_type_;

            var enum_expected_val = get_enum_nick (typeof (TestEnum), test_enum_val);

            string expectation = "";

            switch (c) {
                case KEBAB:
                    expectation = @"{\"string-val\":\"$test_string_val\",\"int64-val\":$test_int64_val,\"int-val\":$test_int_val,\"double-val\":$test_double_val,\"bool-val\":$test_bool_val,\"enum-val\":\"$(enum_expected_val)\",\"type\":\"$test_type_\"}";
                    break;
                case SNAKE:
                    expectation = @"{\"string_val\":\"$test_string_val\",\"int64_val\":$test_int64_val,\"int_val\":$test_int_val,\"double_val\":$test_double_val,\"bool_val\":$test_bool_val,\"enum_val\":\"$(enum_expected_val)\",\"type\":\"$test_type_\"}";
                    break;
                case CAMEL:
                    expectation = @"{\"stringVal\":\"$test_string_val\",\"int64Val\":$test_int64_val,\"intVal\":$test_int_val,\"doubleVal\":$test_double_val,\"boolVal\":$test_bool_val,\"enumVal\":\"$(enum_expected_val)\",\"type\":\"$test_type_\"}";
                    break;
            }

            var result = Jsoner.serialize (test_object, c);

            if (result != expectation) {
                Test.fail_printf (result + " != " + expectation);
            }
        }
    });

    Test.add_func ("/jsoner/deserialize/values", () => {
        string test_string_val = "test";
        int64 test_int64_val = 1234;
        int test_int_val = 1234;
        double test_double_val = 45.1;
        bool test_bool_val = true;
        TestEnum test_enum_val = VALUE_2;
        string test_type_ = "some text";

        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var enum_expected_val = get_enum_nick (typeof (TestEnum), test_enum_val);

            string json = "";

            switch (c) {
                case KEBAB:
                    json = @"{\"string-val\":\"$test_string_val\",\"int64-val\":$test_int64_val,\"int-val\":$test_int_val,\"double-val\":$test_double_val,\"bool-val\":$test_bool_val,\"enum-val\":\"$(enum_expected_val)\",\"type\":\"$test_type_\"}";
                    break;
                case SNAKE:
                    json = @"{\"string_val\":\"$test_string_val\",\"int64_val\":$test_int64_val,\"int_val\":$test_int_val,\"double_val\":$test_double_val,\"bool_val\":$test_bool_val,\"enum_val\":\"$(enum_expected_val)\",\"type\":\"$test_type_\"}";
                    break;
                case CAMEL:
                    json = @"{\"stringVal\":\"$test_string_val\",\"int64Val\":$test_int64_val,\"intVal\":$test_int_val,\"doubleVal\":$test_double_val,\"boolVal\":$test_bool_val,\"enumVal\":\"$(enum_expected_val)\",\"type\":\"$test_type_\"}";
                    break;
            }

            var result = DataObject.from_json<ValuesData> (json, null, c);

            if (result.string_val != test_string_val) {
                Test.fail_printf (@"$(result.string_val) != $(test_string_val)");
            }
            if (result.int64_val != test_int64_val) {
                Test.fail_printf (@"$(result.int64_val) != $(test_int64_val)");
            }
            if (result.int_val != test_int_val) {
                Test.fail_printf (@"$(result.int_val) != $(test_int_val)");
            }
            if (result.double_val != test_double_val) {
                Test.fail_printf (@"$(result.double_val) != $(test_double_val)");
            }
            if (result.bool_val != test_bool_val) {
                Test.fail_printf (@"$(result.bool_val) != $(test_bool_val)");
            }
            if (result.enum_val != test_enum_val) {
                Test.fail_printf (@"$(result.enum_val) != $(test_enum_val)");
            }
            if (result.type_ != test_type_) {
                Test.fail_printf (@"$(result.type_) != $(test_type_)");
            }
        }
    });

    Test.add_func ("/jsoner/serialize/null", () => {
        var test_object = new TestObjectString ();
        test_object.value = null;

        string expectation = "{\"value\":null}";
        message ("kek");
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/yam_obj", () => {
        var test_object = new TestObjectObject ();
        test_object.string_value = "test";
        test_object.int_value = 42;
        test_object.bool_value = true;

        string expectation = "{\"string-value\":\"test\",\"int-value\":42,\"bool-value\":true}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/array/string", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = "{\"value\":[\"everything that lives is designed to end\",\"we are perpetually trapped in a neverending spyral of life and death\",\"is this a curse?\",\"or some kind of punishment?\",\"i often thinking about the god who blessed us with this cryptic puzzle\",\"and wonder if we'll ever have a chance to kill him\"]}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/dict/string", () => {
        try {
            var expected_json = "{\"value\":{\"kekw\":\"yes\",\"kek\":\"no\"}}";

            var obj = new TestObjectDictString ();
            obj.value.set ("kekw", "yes");
            obj.value.set ("kek", "no");

            var result = obj.to_json ();

            if (result != expected_json) {
                Test.fail_printf (@"$result != $expected_json");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/serialize/array/string2", () => {
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

    Test.add_func ("/jsoner/serialize/array/object", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new TestObjectObject ());
        test_object.value.add (new TestObjectObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new TestObjectObject () { bool_value = false });
        test_object.value.add (new TestObjectObject ());
        test_object.value.add (new TestObjectObject () { string_value = "kekw" });
        test_object.value.add (new TestObjectObject ());

        string expectation = "{\"value\":[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}]}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/array/object2", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new TestObjectObject ());
        test_object.value.add (new TestObjectObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new TestObjectObject () { bool_value = false });
        test_object.value.add (new TestObjectObject ());
        test_object.value.add (new TestObjectObject () { string_value = "kekw" });
        test_object.value.add (new TestObjectObject ());

        string expectation = "{\"value\":[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}]}";
        string result = test_object.to_json ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/array/array", () => {
        var test_object = new TestObjectArrayArray ();
        test_object.value.add (new Gee.ArrayList<TestObjectObject> ());
        test_object.value.add (new Gee.ArrayList<TestObjectObject> ());
        test_object.value.add (new Gee.ArrayList<TestObjectObject> ());
        test_object.value[0].add (new TestObjectObject ());
        test_object.value[0].add (new TestObjectObject ());
        test_object.value[1].add (new TestObjectObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value[1].add (new TestObjectObject () { bool_value = false });
        test_object.value[1].add (new TestObjectObject () { string_value = "kekw" });
        test_object.value[2].add (new TestObjectObject () { int_value = 56 });

        string expectation = "{\"value\":[[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}],[{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false}],[{\"string-value\":null,\"int-value\":56,\"bool-value\":false}]]}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/deserialize/enum", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"value_2\"}");
            var result = jsoner.deserialize_object<TestObjectEnum> ();

            if (result.value != TestEnum.VALUE_2) {
                Test.fail_printf (result.value.to_string () + " != " + TestEnum.VALUE_2.to_string ());
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/value", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"test\"}", {"value"});

            string result = jsoner.deserialize_value ().get_string ();

            if (result != "test") {
                Test.fail_printf (result + " != test");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/not_valid_path", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"test\"}", {"value1"});
            jsoner.deserialize_value ();

            Test.fail_printf ("Value parsed without error");
        } catch (CommonError e) {
            Test.skip (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"test\"}");
            var result = jsoner.deserialize_object<TestObjectString> ();

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object2", () => {
        try {
            var result = new TestObjectString ();
            result.fill_from_json ("{\"value\":\"test\"}");

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object_camel", () => {
        try {
            var jsoner = new Jsoner ("{\"stringValue\":\"test\"}", null, Case.CAMEL);
            var result = jsoner.deserialize_object<TestObjectStringCamel> ();

            if (result.string_value != "test") {
                Test.fail_printf (result.string_value + " != test");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object_camel_", () => {
        try {
            var jsoner = new Jsoner ("{\"stringValue\":\"test\"}", null, Case.CAMEL);
            var result = jsoner.deserialize_object<TestObjectStringCamelW> ();

            if (result.string_value_ != "test") {
                Test.fail_printf (result.string_value_ + " != test");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/int_to_string", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":6}");
            var result = jsoner.deserialize_object<TestObjectString> ();

            if (result.value != "6") {
                Test.fail_printf (result.value + " != \"6\"");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/int_to_double", () => {
        try {
            var json = "{\"value\":6}";

            var result = DataObject.from_json<TestObjectDouble> (json);

            if (result.value != 6.0) {
                Test.fail_printf (@"$(result.value) != 6.0");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/string", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");
            var result = jsoner.deserialize_object<TestObjectArrayString> ();

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/dict/string", () => {
        try {
            var json = "{\"value\":{\"kekw\":\"yes\",\"kek\":\"no\"}}";

            var result = DataObject.from_json<TestObjectDictString> (json);

            if (result.value["kekw"] != "yes" || result.value["kek"] != "no") {
                Test.fail_printf ("");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/string2", () => {
        try {
            var result = new TestObjectArrayString ();
            result.fill_from_json ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/direct", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[\"kekw\",\"yes\",\"no\"]}", {"value"});
            var array = new Gee.ArrayList<string> ();
            jsoner.deserialize_array_into (array);

            if (array[0] != "kekw" || array[1] != "yes" || array[2] != "no") {
                Test.fail_printf (string.joinv (", ", array.to_array ()) + " != kekw, yes, no");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/object", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[{\"string-value\":\"Baby one more time\",\"int-value\":42,\"bool-value\":true},{\"string-value\":\"I want it that way\",\"int-value\":17,\"bool-value\":false},{\"string-value\":\"Gonna make you sweat\",\"int-value\":99,\"bool-value\":true}]}");
            var result = jsoner.deserialize_object<TestObjectArrayObject> ();

            if (result.value[0].string_value != "Baby one more time" || result.value[1].int_value != 17 || result.value[2].bool_value != true) {
                Test.fail_printf (
                    result.value[0].string_value + " != Baby one more time\n" +
                    result.value[1].int_value.to_string () + " != 17\n" +
                    result.value[2].bool_value.to_string () + " != true"
                );
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/object2", () => {
        try {
            var result = new TestObjectArrayObject ();
            result.fill_from_json ("{\"value\":[{\"string-value\":\"Baby one more time\",\"int-value\":42,\"bool-value\":true},{\"string-value\":\"I want it that way\",\"int-value\":17,\"bool-value\":false},{\"string-value\":\"Gonna make you sweat\",\"int-value\":99,\"bool-value\":true}]}");

            if (result.value[0].string_value != "Baby one more time" || result.value[1].int_value != 17 || result.value[2].bool_value != true) {
                Test.fail_printf (
                    result.value[0].string_value + " != Baby one more time\n" +
                    result.value[1].int_value.to_string () + " != 17\n" +
                    result.value[2].bool_value.to_string () + " != true"
                );
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/array", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[[{\"value\":7}],[{\"value\":98}]]}");
            var result = jsoner.deserialize_object<TestObjectAlbum> ((out array, type) => {
                if (type == typeof (TestObjectInt)) {
                    array = new Gee.ArrayList<TestObjectInt> ();
                    return true;
                }

                return false;
            });

            if (result.value[0][0].value != 7 || result.value[1][0].value != 98) {
                Test.fail_printf (
                    result.value[0][0].value.to_string () + " != 7\n" +
                    result.value[1][0].value.to_string () + " != 98\n"
                );
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    return Test.run ();
}
