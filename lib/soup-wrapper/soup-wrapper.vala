/*
 * Copyright (C) 2024 Vladimir Vaskov
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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Soup;

public sealed class ApiBase.SoupWrapper : Object {

    public CookieJarType cookie_jar_type { get; construct; }

    Gee.HashMap<string, Headers> presets_table = new Gee.HashMap<string, Headers> ();

    Soup.Session session = new Soup.Session () {
        timeout = GLOBAL_TIMEOUT
    };

    public string? user_agent {
        construct {
            if (value != null) {
                session.user_agent = value;
            }
        }
    }

    string? _cookies_file_path;
    public string? cookies_file_path {
        private get {
            return _cookies_file_path;
        }
        construct {
            _cookies_file_path = value;

            reload_cookies ();
        }
    }

    public SoupWrapper (
        CookieJarType cookie_jar_type = NONE,
        string? user_agent = null,
        string? cookies_file_path = null
    ) {
        Object (
            cookie_jar_type: cookie_jar_type,
            user_agent: user_agent,
            cookies_file_path: cookies_file_path
        );
    }

    construct {
        var logger = new Soup.Logger (BODY);

        logger.set_printer ((logger, level, direction, data) => {
            switch (direction) {
                case '<':
                case '>':
                    debug ("%c %s", direction, data);
                    break;

                default:
                    debug ("");
                    break;
            }
        });

        session.add_feature (logger);
    }

    public void reload_cookies () {
        Type? feature_type;

        switch (cookie_jar_type) {
            case DB:
                feature_type = typeof (Soup.CookieJarDB);
                break;

            case TEXT:
                feature_type = typeof (Soup.CookieJarText);
                break;

            case NONE:
                feature_type = null;
                break;

            default:
                assert_not_reached ();
        }

        if (feature_type != null) {
            if (session.has_feature (feature_type)) {
                session.remove_feature_by_type (feature_type);
            }
        }

        if (cookies_file_path != null) {
            Soup.SessionFeature cookie_jar;

            switch (cookie_jar_type) {
                case DB:
                    cookie_jar = new Soup.CookieJarDB (cookies_file_path, false);
                    break;

                case TEXT:
                    cookie_jar = new Soup.CookieJarText (cookies_file_path, false);
                    break;

                default:
                    assert_not_reached ();
            }

            session.add_feature (cookie_jar);
            debug ("Cookies updated. New cookies file: \"%s\"", cookies_file_path);
        }
    }

    public void add_headers_preset (string preset_name, Header[] headers_arr) {
        var headers = new Headers ();
        headers.set_headers (headers_arr);
        presets_table.set (preset_name, headers);
    }

    void append_headers_with_preset_to (Soup.Message msg, string preset_name) {
        Headers? headers = presets_table.get (preset_name);
        if (headers != null) {
            append_headers_to (msg, headers.get_headers ());
        }
    }

    void append_headers_to (Soup.Message msg, Header[] headers_arr) {
        foreach (Header header in headers_arr) {
            msg.request_headers.append (header.name, header.value);
        }
    }

    void add_params_to_uri (string[,]? parameters, ref string uri) {
        string[] parameters_pairs = new string[parameters.length[0]];

        for (int i = 0; i < parameters.length[0]; i++) {
            parameters_pairs[i] = parameters[i, 0] + "=" + Uri.escape_string (parameters[i, 1]);
        }

        uri += "?" + string.joinv ("&", parameters_pairs);
    }

    Soup.Message message_get (
        owned string uri,
        string[]? header_preset_names = null,
        string[,]? parameters = null,
        Header[]? headers = null
    ) {
        if (parameters != null) {
            add_params_to_uri (parameters, ref uri);
        }

        var msg = new Soup.Message (GET, uri);

        if (header_preset_names != null) {
            foreach (string preset_name in header_preset_names) {
                append_headers_with_preset_to (msg, preset_name);
            }
        }
        if (headers != null) {
            append_headers_to (msg, headers);
        }

        return msg;
    }

    Soup.Message message_post (
        owned string uri,
        string[]? header_preset_names = null,
        PostContent? post_content = null,
        string[,]? parameters = null,
        Header[]? headers = null
    ) {
        if (parameters != null) {
            add_params_to_uri (parameters, ref uri);
        }

        var msg = new Soup.Message (POST, uri);

        if (post_content != null) {
            msg.set_request_body_from_bytes (
                post_content.get_content_type_string (),
                post_content.get_bytes ()
            );
        }

        if (header_preset_names != null) {
            foreach (string preset_name in header_preset_names) {
                append_headers_with_preset_to (msg, preset_name);
            }
        }

        if (headers != null) {
            append_headers_to (msg, headers);
        }

        return msg;
    }

    void check_status_code (Soup.Message msg, Bytes bytes) throws CommonError, BadStatusCodeError {
        if (msg.status_code == Soup.Status.OK) {
            return;
        }

        ApiError error = new ApiError ();

        try {
            var jsoner = Jsoner.from_bytes (bytes, { "error" }, Case.CAMEL);
            if (jsoner.root.get_node_type () == Json.NodeType.OBJECT) {
                error = (ApiError) jsoner.deserialize_object (typeof (ApiError));

            } else {
                jsoner = Jsoner.from_bytes (bytes, null, Case.SNAKE);
                error = (ApiError) jsoner.deserialize_object (typeof (ApiError));
            }
        } catch (CommonError e) {}

        error.status_code = msg.status_code;

        switch (msg.status_code) {
            case Soup.Status.BAD_REQUEST:
                throw new BadStatusCodeError.BAD_REQUEST (error.msg);

            case Soup.Status.NOT_FOUND:
                throw new BadStatusCodeError.NOT_FOUND (error.msg);

            case Soup.Status.FORBIDDEN:
                throw new BadStatusCodeError.FORBIDDEN (error.msg);

            default:
                throw new BadStatusCodeError.UNKNOWN (msg.status_code.to_string () + ": " + error.msg);
        }
    }

    GLib.Bytes run (
        Soup.Message msg,
        Cancellable? cancellable = null
    ) throws CommonError, BadStatusCodeError {
        GLib.Bytes bytes = null;

        try {
            bytes = session.send_and_read (msg, cancellable);

        } catch (Error e) {
            throw new CommonError.SOUP ("%s %s: %s".printf (msg.method, msg.uri.to_string (), e.message));
        }

        check_status_code (msg, bytes);

        return bytes;
    }

    public new GLib.Bytes @get (
        owned string uri,
        string[]? header_preset_names = null,
        string[,]? parameters = null,
        Header[]? headers = null,
        Cancellable? cancellable = null
    ) throws CommonError, BadStatusCodeError {
        var msg = message_get (
            uri,
            header_preset_names,
            parameters,
            headers
        );

        return run (msg, cancellable);
    }

    public GLib.Bytes post (
        owned string uri,
        string[]? header_preset_names = null,
        PostContent? post_content = null,
        string[,]? parameters = null,
        Header[]? headers = null,
        Cancellable? cancellable = null
    ) throws CommonError, BadStatusCodeError {
        var msg = message_post (
            uri,
            header_preset_names,
            post_content,
            parameters,
            headers
        );

        return run (msg, cancellable);
    }

    // ASYNC

    async void check_status_code_async (Soup.Message msg, Bytes bytes) throws CommonError, BadStatusCodeError {
        if (msg.status_code == Soup.Status.OK) {
            return;
        }

        ApiError error = new ApiError ();

        try {
            var jsoner = Jsoner.from_bytes (bytes, { "error" }, Case.CAMEL);
            if (jsoner.root.get_node_type () == Json.NodeType.OBJECT) {
                error = (ApiError) yield jsoner.deserialize_object_async (typeof (ApiError));

            } else {
                jsoner = Jsoner.from_bytes (bytes, null, Case.SNAKE);
                error = (ApiError) yield jsoner.deserialize_object_async (typeof (ApiError));
            }
        } catch (CommonError e) {}

        error.status_code = msg.status_code;

        switch (msg.status_code) {
            case Soup.Status.BAD_REQUEST:
                throw new BadStatusCodeError.BAD_REQUEST (error.msg);

            case Soup.Status.NOT_FOUND:
                throw new BadStatusCodeError.NOT_FOUND (error.msg);

            case Soup.Status.FORBIDDEN:
                throw new BadStatusCodeError.FORBIDDEN (error.msg);

            default:
                throw new BadStatusCodeError.UNKNOWN (msg.status_code.to_string () + ": " + error.msg);
        }
    }

    async GLib.Bytes run_async (
        Soup.Message msg,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws CommonError, BadStatusCodeError {
        GLib.Bytes bytes = null;

        try {
            bytes = yield session.send_and_read_async (msg, priority, cancellable);

        } catch (Error e) {
            throw new CommonError.SOUP ("%s %s: %s".printf (msg.method, msg.uri.to_string (), e.message));
        }

        yield check_status_code_async (msg, bytes);

        return bytes;
    }

    public async new GLib.Bytes get_async (
        owned string uri,
        string[]? header_preset_names = null,
        string[,]? parameters = null,
        Header[]? headers = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws CommonError, BadStatusCodeError {
        var msg = message_get (
            uri,
            header_preset_names,
            parameters,
            headers
        );

        return yield run_async (msg, priority, cancellable);
    }

    public async GLib.Bytes post_async (
        owned string uri,
        string[]? header_preset_names = null,
        PostContent? post_content = null,
        string[,]? parameters = null,
        Header[]? headers = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws CommonError, BadStatusCodeError {
        var msg = message_post (
            uri,
            header_preset_names,
            post_content,
            parameters,
            headers
        );

        return yield run_async (msg, priority, cancellable);
    }
}
