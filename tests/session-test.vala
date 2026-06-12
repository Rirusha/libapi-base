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

using ApiBase;
using Serialize;

class UserAgentInfo : DataObject {
    public string user_agent { get; set; }
}

class CookiesInfo : DataObject {
    public Serialize.Dict<string> cookies { get; set; default = new Serialize.Dict<string> (); }
}

//  A test server so that the tests do not depend on an external API
class TestServer : Object {
    public Soup.Server server { get; private set; }
    public uint16 port { get; private set; }

    public TestServer () throws GLib.Error {
        server = (Soup.Server) Object.new (typeof (Soup.Server));

        //  GET /get
        server.add_handler ("/get", (srv, msg, path, query) => {
            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            var body = "{\"args\":{},\"headers\":{},\"url\":\"http://127.0.0.1/get\"}";
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  GET /json
        server.add_handler ("/json", (srv, msg, path, query) => {
            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            var body = """{
  "slideshow": {
    "author": "Yours Truly",
    "date": "date of publication",
    "slides": [
      {
        "title": "Title exists!",
        "type": "all"
      },
      {
        "items": [
          "Item 1",
          "Item 2"
        ],
        "title": "Overview",
        "type": "all"
      }
    ],
    "title": "Sample Slide Show"
  }
}""";
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  GET /user-agent
        server.add_handler ("/user-agent", (srv, msg, path, query) => {
            var user_agent = msg.get_request_headers ().get_one ("User-Agent") ?? "unknown";
            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            var body = "{\"user_agent\":\"" + user_agent + "\"}";
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  GET /robots.txt
        server.add_handler ("/robots.txt", (srv, msg, path, query) => {
            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("text/plain", null);
            var body = "User-agent: *\nDisallow: /deny";
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  GET /status/500
        server.add_handler ("/status/500", (srv, msg, path, query) => {
            msg.set_status (500, "Internal Server Error");
        });

        //  DELETE /delete
        server.add_handler ("/delete", (srv, msg, path, query) => {
            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            var body = "{\"method\":\"DELETE\"}";
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  PATCH /patch
        server.add_handler ("/patch", (srv, msg, path, query) => {
            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            var body = "{\"method\":\"PATCH\"}";
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  POST /post
        server.add_handler ("/post", (srv, msg, path, query) => {
            var body_data = (string) msg.get_request_body ().data;
            var headers = msg.get_request_headers ();
            var content_type = headers.get_content_type (null);
            string body;

            if (content_type == "application/x-www-form-urlencoded") {
                body = "{\"args\":{},\"data\":\"\",\"files\":{},\"form\":" + parse_form_data (body_data) + "}";
            } else {
                body = "{\"method\":\"POST\"}";
            }

            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        //  PUT /put
        server.add_handler ("/put", (srv, msg, path, query) => {
            var body_data = (string) msg.get_request_body ().data;
            var headers = msg.get_request_headers ();
            var content_type = headers.get_content_type (null);
            string body;

            if (content_type == "application/x-www-form-urlencoded") {
                body = "{\"args\":{},\"data\":\"\",\"files\":{},\"form\":" + parse_form_data (body_data) + "}";
            } else {
                body = "{\"method\":\"PUT\"}";
            }

            msg.set_status (200, "OK");
            msg.get_response_headers ().set_content_type ("application/json", null);
            msg.get_response_body ().append_take ((uint8[]) body.data);
        });

        if (!server.listen_local (0, Soup.ServerListenOptions.IPV4_ONLY)) {
            throw new GLib.Error (GLib.Quark.from_string ("TestServer"), 0, "Failed to start server");
        }

        var uris = server.get_uris ();
        if (uris != null && uris.length () > 0) {
            var uri = uris.nth_data (0);
            port = (uint16) uri.get_port ();
        } else {
            throw new GLib.Error (GLib.Quark.from_string ("TestServer"), 0, "Failed to get server port");
        }
    }

    string parse_form_data (string data) {
        var result = new StringBuilder ("{");
        var pairs = data.split ("&");
        var keys = new Gee.ArrayList<string> ();
        var values = new Gee.HashMap<string, string> ();
        foreach (var pair in pairs) {
            var kv = pair.split ("=");
            if (kv.length == 2) {
                var key = Uri.unescape_string (kv[0]) ?? kv[0];
                var value = Uri.unescape_string (kv[1]) ?? kv[1];
                keys.add (key);
                values.set (key, value);
            }
        }
        keys.sort (str_cmp);
        bool first = true;
        foreach (var key in keys) {
            if (!first) {
                result.append_c (',');
            }
            first = false;
            result.append_c ('"');
            result.append (key);
            result.append_c ('"');
            result.append_c (':');
            result.append_c ('"');
            result.append (values.get (key));
            result.append_c ('"');
        }
        result.append_c ('}');
        return result.str;
    }

    int str_cmp (string a, string b) {
        return strcmp (a, b);
    }

    public void stop () {
        server.disconnect ();
    }
}

Bytes? send_and_read_in_thread (Session session, Request request) throws GLib.Error {
    Bytes? result = null;
    GLib.Error? err = null;
    var loop = new MainLoop ();
    new Thread<void*> ("client", () => {
        try {
            result = session.send_and_read (request);
        } catch (GLib.Error e) {
            err = e;
        }
        loop.quit ();
        return null;
    });
    loop.run ();
    if (err != null) {
        throw err;
    }
    return result;
}

Bytes? simple_send_and_read_in_thread (Request request) throws GLib.Error {
    Bytes? result = null;
    GLib.Error? err = null;
    var loop = new MainLoop ();
    new Thread<void*> ("client", () => {
        try {
            result = request.simple_send_and_read ();
        } catch (GLib.Error e) {
            err = e;
        }
        loop.quit ();
        return null;
    });
    loop.run ();
    if (err != null) {
        throw err;
    }
    return result;
}

const string EXPECTED_JSON = """{
  "slideshow": {
    "author": "Yours Truly",
    "date": "date of publication",
    "slides": [
      {
        "title": "Title exists!",
        "type": "all"
      },
      {
        "items": [
          "Item 1",
          "Item 2"
        ],
        "title": "Overview",
        "type": "all"
      }
    ],
    "title": "Sample Slide Show"
  }
}""";

const string EXPECTED_ROBOTS = """User-agent: *
Disallow: /deny""";

const string EXPECTED_CONTENT_START = """{"args":{},"data":"","files":{},"form":{"comments":"FAST","custemail":"rirusha@altlinux.org","custname":"Rirusha","custtel":"666666","delivery":"","size":"large"}""";

const string USER_AGENT = "TEST USER AGENT";

string TEST_BASE_URL;
string BAD_BASE_URL;

void test_soup_wrapper_get () {
    try {
        var session = new Session ();
        session.add_base_url (TEST_BASE_URL);
        var request = new Request.GET ("/get");
        send_and_read_in_thread (session, request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_get_error () {
    try {
        var session = new Session ();
        session.add_base_url (BAD_BASE_URL);
        var request = new Request.GET ("/get");
        var response = send_and_read_in_thread (session, request);
        if (response != null) {
            Test.fail_printf ("No Error");
        }
    } catch (GLib.Error e) {
        debug ("%s: %s", e.domain.to_string (), e.message);
    }
}

void test_soup_wrapper_get_base_urls () {
    try {
        var session = new Session ();
        session.add_base_url (BAD_BASE_URL);
        session.add_base_url (TEST_BASE_URL);
        var request = new Request.GET ("/get");
        send_and_read_in_thread (session, request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_get_base_url () {
    try {
        var session = new Session ();
        session.add_base_url ("gsdgsdgdnsjkgnwenvkuesbvur");
        var request = new Request.GET (TEST_BASE_URL + "/get");
        send_and_read_in_thread (session, request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_get_json () {
    try {
        var soup_wrapper = new Session () { user_agent = USER_AGENT };
        var request = new Request.GET (TEST_BASE_URL + "/json");
        var response = (string) (send_and_read_in_thread (soup_wrapper, request).get_data ());

        if (response.strip () != EXPECTED_JSON.strip ()) {
            Test.fail_printf ("Wrong result: \n%s", response);
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_delete () {
    try {
        var request = new Request.DELETE (TEST_BASE_URL + "/delete");
        simple_send_and_read_in_thread (request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_patch () {
    try {
        var request = new Request.PATCH (TEST_BASE_URL + "/patch");
        simple_send_and_read_in_thread (request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_post () {
    try {
        var request = new Request.POST (TEST_BASE_URL + "/post");
        simple_send_and_read_in_thread (request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_put () {
    try {
        var request = new Request.PUT (TEST_BASE_URL + "/put");
        simple_send_and_read_in_thread (request);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_error_status () {
    try {
        var request = new Request.GET (TEST_BASE_URL + "/status/500");
        simple_send_and_read_in_thread (request);
    } catch (BadStatusCodeError status_code) {
        if (status_code.code == 500) {
            return;
        }
        Test.fail_printf ("Error: \n%s", status_code.message);
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_user_agent () {
    try {
        var soup_wrapper = new Session () { user_agent = USER_AGENT };
        var request = new Request.GET (TEST_BASE_URL + "/user-agent");

        var respone = send_and_read_in_thread (soup_wrapper, request);

        var jsoner = new JsonWorker.from_bytes (respone);

        var obj = jsoner.deserialize_object<UserAgentInfo> ();

        if (obj.user_agent != USER_AGENT) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_post_data_dict () {
    try {
        var request = new Request.POST (TEST_BASE_URL + "/post");

        Content content = { X_WWW_FORM_URLENCODED };

        var dict = new Serialize.Dict<string> ();
        dict["custname"] = "Rirusha";
        dict["custtel"] = "666666";
        dict["custemail"] = "rirusha@altlinux.org";
        dict["size"] = "large";
        dict["delivery"] = "";
        dict["comments"] = "FAST";

        content.set_dict (dict);
        request.add_content (content);
        var response = (string) (simple_send_and_read_in_thread (request).get_data ());

        if (!(response.strip ().has_prefix (EXPECTED_CONTENT_START))) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_post_data_datalist () {
    try {
        var request = new Request.POST (TEST_BASE_URL + "/post");

        Content content = { X_WWW_FORM_URLENCODED };

        var datalist = Datalist<string> ();
        datalist.set_data ("custname", "Rirusha");
        datalist.set_data ("custtel", "666666");
        datalist.set_data ("custemail", "rirusha@altlinux.org");
        datalist.set_data ("size", "large");
        datalist.set_data ("delivery", "");
        datalist.set_data ("comments", "FAST");

        content.set_datalist (datalist);
        request.add_content (content);
        var response = (string) (simple_send_and_read_in_thread (request).get_data ());

        if (!(response.strip ().has_prefix (EXPECTED_CONTENT_START))) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_put_data_dict () {
    try {
        var request = new Request.PUT (TEST_BASE_URL + "/put");

        Content content = { X_WWW_FORM_URLENCODED };

        var dict = new Serialize.Dict<string> ();
        dict["custname"] = "Rirusha";
        dict["custtel"] = "666666";
        dict["custemail"] = "rirusha@altlinux.org";
        dict["size"] = "large";
        dict["delivery"] = "";
        dict["comments"] = "FAST";

        content.set_dict (dict);
        request.add_content (content);
        var response = (string) (simple_send_and_read_in_thread (request).get_data ());

        if (!(response.strip ().has_prefix (EXPECTED_CONTENT_START))) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_put_data_datalist () {
    try {
        var request = new Request.PUT (TEST_BASE_URL + "/put");

        Content content = { X_WWW_FORM_URLENCODED };

        var datalist = Datalist<string> ();
        datalist.set_data ("custname", "Rirusha");
        datalist.set_data ("custtel", "666666");
        datalist.set_data ("custemail", "rirusha@altlinux.org");
        datalist.set_data ("size", "large");
        datalist.set_data ("delivery", "");
        datalist.set_data ("comments", "FAST");

        content.set_datalist (datalist);
        request.add_content (content);
        var response = (string) (simple_send_and_read_in_thread (request).get_data ());

        if (!(response.strip ().has_prefix (EXPECTED_CONTENT_START))) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_header () {
    try {
        var request = new Request.GET (TEST_BASE_URL + "/robots.txt");
        request.add_header ("accept", "text/plain");

        var response = (string) (simple_send_and_read_in_thread (request).get_data ());

        if (!(response.strip () == EXPECTED_ROBOTS)) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

void test_soup_wrapper_headers_preset () {
    try {
        var session = new Session ();
        session.add_headers_preset ("test", {
            { "accept", "text/plain" }
        });

        var request = new Request.GET (TEST_BASE_URL + "/robots.txt");
        request.add_header ("accept", "text/plain");

        var response = (string) (send_and_read_in_thread (session, request).get_data ());

        if (!(response.strip () == EXPECTED_ROBOTS)) {
            Test.fail ();
        }
    } catch (GLib.Error e) {
        Test.fail_printf ("Error: \n%s", e.message);
    }
}

public int main (string[] args) {
    Test.init (ref args);

    TestServer? test_server = null;
    try {
        test_server = new TestServer ();
        TEST_BASE_URL = "http://127.0.0.1:%u".printf (test_server.port);
        BAD_BASE_URL = "http://127.0.0.1:1";
    } catch (GLib.Error e) {
        error ("Failed to start test server: %s", e.message);
    }

    Test.add_func ("/soup-wrapper/get", test_soup_wrapper_get);
    Test.add_func ("/soup-wrapper/get/error", test_soup_wrapper_get_error);
    Test.add_func ("/soup-wrapper/get/base-urls", test_soup_wrapper_get_base_urls);
    Test.add_func ("/soup-wrapper/get/base-url", test_soup_wrapper_get_base_url);
    Test.add_func ("/soup-wrapper/get/json", test_soup_wrapper_get_json);
    Test.add_func ("/soup-wrapper/delete", test_soup_wrapper_delete);
    Test.add_func ("/soup-wrapper/patch", test_soup_wrapper_patch);
    Test.add_func ("/soup-wrapper/post", test_soup_wrapper_post);
    Test.add_func ("/soup-wrapper/put", test_soup_wrapper_put);
    Test.add_func ("/soup-wrapper/error-status", test_soup_wrapper_error_status);
    Test.add_func ("/soup-wrapper/user-agent", test_soup_wrapper_user_agent);
    Test.add_func ("/soup-wrapper/post/data/dict", test_soup_wrapper_post_data_dict);
    Test.add_func ("/soup-wrapper/post/data/datalist", test_soup_wrapper_post_data_datalist);
    Test.add_func ("/soup-wrapper/put/data/dict", test_soup_wrapper_put_data_dict);
    Test.add_func ("/soup-wrapper/put/data/datalist", test_soup_wrapper_put_data_datalist);
    Test.add_func ("/soup-wrapper/header", test_soup_wrapper_header);
    Test.add_func ("/soup-wrapper/headers-preset", test_soup_wrapper_headers_preset);

    var result = Test.run ();

    if (test_server != null) {
        test_server.stop ();
    }

    return result;
}
