/*
 * Copyright (C) 2025-2026 Vladimir Romanov <rirusha@altlinux.org>
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

/**
 * Request object. Can handle parameters, headers, content.
 * {@link Session.exec} and {@link Session.exec_async}
 * form message via {@link form_message} and set this to readonly
 */
[Version (since = "3.0")]
public class ApiBase.Request : Object {

    public HttpMethod method { get; construct; }

    public string uri { get; construct; }

    public int port { get; set; default = -1; }

    internal Soup.Message? message { get; private set; }

    Gee.HashSet<Header?> headers = new Gee.HashSet<Header?> (
        (el) => {
            return str_hash (el.name);
        },
        (el1, el2) => {
            return str_equal (el1.name, el2.name);
        }
    );

    Gee.HashSet<Param?> parameters = new Gee.HashSet<Param?> (
        (el) => {
            return str_hash (el.name);
        },
        (el1, el2) => {
            return str_equal (el1.name, el2.name);
        }
    );

    Gee.HashSet<string> _presets = new Gee.HashSet<string> ();
    public string[] presets {
        owned get {
            return _presets.to_array ();
        }
        set {
            _presets.clear ();
            _presets.add_all_array (value);
        }
    }

    Content? content = null;

    Request (HttpMethod method, string uri) {
        Object (
            method: method,
            uri: uri
        );
    }

    public Request.GET (string uri) {
        this (HttpMethod.GET, uri);
    }

    public Request.HEAD (string uri) {
        this (HttpMethod.HEAD, uri);
    }

    public Request.OPTIONS (string uri) {
        this (HttpMethod.OPTIONS, uri);
    }

    public Request.TRACE (string uri) {
        this (HttpMethod.TRACE, uri);
    }

    public Request.PUT (string uri) {
        this (HttpMethod.PUT, uri);
    }

    public Request.DELETE (string uri) {
        this (HttpMethod.DELETE, uri);
    }

    public Request.POST (string uri) {
        this (HttpMethod.POST, uri);
    }

    public Request.PATCH (string uri) {
        this (HttpMethod.PATCH, uri);
    }

    public Request.CONNECT (string uri) {
        this (HttpMethod.CONNECT, uri);
    }

    construct {
        headers = new Gee.HashSet<Header?> (
            (el) => {
                return str_hash (el.name);
            },
            (el1, el2) => {
                return str_equal (el1.name, el2.name);
            }
        );
    }

    /**
     * Add header with header object
     *
     * @param header    Header object
     * @param replace   Replace existing header with equal name or not
     */
    [Version (since = "4.0")]
    public void add_header (string name, string value, bool replace = true) {
        add_header_struct ({ name, value }, replace);
    }

    void add_header_struct (Header header, bool replace = true) {
        if (header in headers && !replace) {
            return;
        }
        headers.add (header);
    }

    /**
     * Add header with header objects array
     *
     * @param headers   Header objects array
     * @param replace   Replace existing header with equal name or not
     */
    [Version (since = "3.0")]
    public void add_headers (Header[] headers, bool replace = true) {
        foreach (var header in headers) {
            add_header_struct (header, replace);
        }
    }

    /**
     * Add parameter with parameter data
     *
     * @param name      Parameter name
     * @param value     Parameter value
     */
    [Version (since = "4.0")]
    public void add_param (string name, string value) {
        add_param_struct ({ name, value });
    }

    void add_param_struct (Param parameter) {
        parameters.add (parameter);
    }

    /**
     * Add parameters with an array
     *
     * @param parameters Parameter objeccts array
     */
    [Version (since = "3.0")]
    public void add_parameters (Param[] parameters) {
        foreach (var parameter in parameters) {
            add_param_struct (parameter);
        }
    }

    /**
     * Add content to request
     *
     * @param content  Content object
     */
    [Version (since = "6.0")]
    public void add_content (Content content) {
        this.content = content;
    }

    /**
     * Get status code from internal {@link Soup.Message}.
     * Must be run after {@link form_message} or
     * {@link Session.exec}/{@link Session.exec_async}
     *
     * @return  Status
     */
    [Version (since = "3.0")]
    public Soup.Status? get_status_code () {
        return message?.get_status ();
    }

    /**
     * Get formed message object
     * @return  Response body
     */
    [Version (since = "5.0", deprecated = true, deprecated_since = "7.4")]
    public Soup.Message? form_message (string? base_url = null) {
        init_message (base_url);
        return message;
    }

    internal void init_message (string? base_url = null) {
        message = null;

        string scheme;
        string? host;
        string path;

        try {
            if (Uri.peek_scheme (uri) == null && base_url != null) {
                var base_url_obj = Uri.parse (base_url, NONE);
                scheme = base_url_obj.get_scheme ();
                host = base_url_obj.get_host ();
                path = Path.build_filename (base_url_obj.get_path (), uri);

            } else {
                var cur_uri_obj = Uri.parse (uri, NONE);
                scheme = cur_uri_obj.get_scheme ();
                host = cur_uri_obj.get_host ();
                path = cur_uri_obj.get_path ();
            }
        } catch (UriError e) {
            warning ("Can't create Soup.Message: %s", e.message);
            return;
        }

        var new_uri = Uri.join (
            NONE,
            scheme,
            null,
            host,
            port,
            path,
            get_query (),
            null
        );

        message = new Soup.Message (method.to_string (), new_uri);

        if (message == null) {
            warning ("Can't form %s message with '%s'", method.to_string (), new_uri);
            return;
        }

        if (content != null) {
            message.set_request_body_from_bytes (
                content.content_type.to_string (),
                content.get_bytes ()
            );
        }

        if (headers.size != 0) {
            foreach (var header in headers) {
                message.request_headers.append (header.name, header.value);
            }
        }
    }

    internal void check_status_code (
        InputStream? error_stream,
        Cancellable? cancellable = null
    ) throws IOError, BadStatusCodeError {
        var status_code = get_status_code ();
        if (status_code == Soup.Status.OK || status_code == null) {
            return;
        }

        if (error_stream == null) {
            return;
        }

        string error_message = "No error message";
        var out_stream = new MemoryOutputStream.resizable ();
        if (out_stream.splice (error_stream, CLOSE_TARGET | CLOSE_SOURCE, null) != -1) {
            error_message = (string) (out_stream.steal_as_bytes ().get_data ()) ?? "";
        }

        throw get_error (status_code, error_message);
    }

    internal void peak_presets_from (Session session) {
        foreach (var preset_name in presets) {
            Array<Header> headers = session.presets_table.get (preset_name);
            if (headers != null) {
                add_headers ((Header[]) headers.data, false);
            }
        }
    }

    string? get_query () {
        if (parameters.size == 0) {
            return null;
        }

        var final_parameters = new Serialize.Array<string> ();
        final_parameters.add_all_iterator (parameters.map<string> ((el) => {
            return el.to_string ();
        }));

        return string.joinv ("&", final_parameters.to_array ());
    }

    /**
     * Simple request execution.
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    [Version (since = "3.0", deprecated = true, deprecated_since = "7.4", replacement = "simple_send_and_read")]
    public GLib.Bytes simple_exec (
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return soup_wrapper.exec (this, cancellable);
    }

    /**
     * Asynchronious version of {@link simple_exec}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    [Version (since = "3.0", deprecated = true, deprecated_since = "7.4", replacement = "simple_send_and_read_async")]
    public async GLib.Bytes simple_exec_async (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return yield soup_wrapper.exec_async (this, priority, cancellable);
    }

    /**
     * Simple request send.
     *
     * @throws {@link Soup.SessionError}    Session error from libsoup
     * @throws {@link IOError}              Error from reading stream or reqeust cancellation
     * @throws {@link TlsError}             An error code from a TLS-related routine.
     * @throws {@link BadStatusCodeError}   Bad status code
     */
    [Version (since = "7.4")]
    public InputStream? simple_send (
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return soup_wrapper.send (this, cancellable);
    }

    /**
     * Simple send and read.
     *
     * @throws {@link Soup.SessionError}    Session error from libsoup
     * @throws {@link IOError}              Error from reading stream or reqeust cancellation
     * @throws {@link TlsError}             An error code from a TLS-related routine.
     * @throws {@link BadStatusCodeError}   Bad status code
     */
    [Version (since = "7.4")]
    public GLib.Bytes? simple_send_and_read (
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return soup_wrapper.send_and_read (this, cancellable);
    }

    /**
     * Asynchronious version of {@link simple_send}.
     *
     * @throws {@link Soup.SessionError}    Session error from libsoup
     * @throws {@link IOError}              Error from reading stream or reqeust cancellation
     * @throws {@link TlsError}             An error code from a TLS-related routine.
     * @throws {@link BadStatusCodeError}   Bad status code
     */
    [Version (since = "7.4")]
    public async InputStream? simple_send_async (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return yield soup_wrapper.send_async (this, priority, cancellable);
    }

    /**
     * Asynchronious version of {@link simple_send_and_read}.
     *
     * @throws {@link Soup.SessionError}    Session error from libsoup
     * @throws {@link IOError}              Error from reading stream or reqeust cancellation
     * @throws {@link TlsError}             An error code from a TLS-related routine.
     * @throws {@link BadStatusCodeError}   Bad status code
     */
    [Version (since = "7.4")]
    public async GLib.Bytes? simple_send_and_read_async (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return yield soup_wrapper.send_and_read_async (this, priority, cancellable);
    }
}
