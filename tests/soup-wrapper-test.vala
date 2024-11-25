// ind-check=skip-file
// vala-lint=skip-file

using ApiBase;

class TestObject : Object {

    public string success { get; set; }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/soup-wrapper/get", () => {
        var soup_wrapper = new SoupWrapper ();
        var response = (string) (soup_wrapper.get ("https://rirusha.space/").get_data ());

        if (!("Rirusha Here!" in response)) {
            Test.fail_printf ("Wrong result: \n%s", response);
        }
    });

    Test.add_func ("/soup-wrapper/get/json", () => {
        var soup_wrapper = new SoupWrapper (NONE, "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 YaBrowser/24.10.0.0 Safari/537.36");
        var response = soup_wrapper.get ("https://reqbin.com/echo/get/json");
        var jsoner = new Jsoner.from_bytes (response);

        var obj = (TestObject) jsoner.deserialize_object (typeof (TestObject));

        if (obj.success != "true") {
            Test.fail_printf ("Wrong result: \n%s", (string) (response.get_data ()));
        }
    });

    return Test.run ();
}
