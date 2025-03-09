// ind-check=skip-file
// vala-lint=skip-file

using ApiBase;

public class TestObjectString : Object {
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

public class TestObjectInt : Object {
    public int value { get; set; }
}

public class TestObjectBool : Object {
    public bool value { get; set; }
}

public class TestObjectDouble : Object {
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

public class TestObjectArrayString : Object {
    public Gee.ArrayList<string> value { get; set; default = new Gee.ArrayList<string> (); }
}

public class TestObjectArrayObject : Object {
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

    Test.add_func ("/jsoner/serialize/string", () => {
        var test_object = new TestObjectString ();
        test_object.value = "test";

        string expectation = "{\"value\":\"test\"}";
        var result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/int", () => {
        var test_object = new TestObjectInt ();
        test_object.value = 42;

        string expectation = "{\"value\":42}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/int64", () => {
        var test_object = new TestObjectInt64 ();
        test_object.value = 3636346346363452;

        string expectation = "{\"value\":3636346346363452}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/bool", () => {
        var test_object = new TestObjectBool ();
        test_object.value = true;

        string expectation = "{\"value\":true}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/double", () => {
        var test_object = new TestObjectDouble () { value = 42.5 };
        test_object.value = 42.5;

        string expectation = "{\"value\":42.5}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/enum", () => {
        var test_object = new TestObjectEnum ();
        test_object.value = TestEnum.VALUE_2;

        string expectation = "{\"value\":\"VALUE-2\"}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/null", () => {
        var test_object = new TestObjectString ();
        test_object.value = null;

        string expectation = "{\"value\":null}";
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
            var jsoner = new Jsoner ("{\"value\":\"VALUE-2\"}");
            var result = (TestObjectEnum) jsoner.deserialize_object (typeof (TestObjectEnum));

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
            var result = (TestObjectString) jsoner.deserialize_object (typeof (TestObjectString));

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
            var result = (TestObjectStringCamel) jsoner.deserialize_object (typeof (TestObjectStringCamel));

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
            var result = (TestObjectStringCamelW) jsoner.deserialize_object (typeof (TestObjectStringCamelW));

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
            var result = (TestObjectString) jsoner.deserialize_object (typeof (TestObjectString));

            if (result.value != "6") {
                Test.fail_printf (result.value + " != \"6\"");
            }
        } catch (CommonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/string", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");
            var result = (TestObjectArrayString) jsoner.deserialize_object (typeof (TestObjectArrayString));

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
            jsoner.deserialize_array (array);

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
            var result = (TestObjectArrayObject) jsoner.deserialize_object (typeof (TestObjectArrayObject));

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
            var result = (TestObjectAlbum) jsoner.deserialize_object (typeof (TestObjectAlbum), null, (out array, type) => {
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
