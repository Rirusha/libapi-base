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

[Version (since = "3.0")]
/**
 * Request object. Can handle parameters, headers, content.
 * {@link Session.exec} and {@link Session.exec_async}
 * form message via {@link form_message} and set this to readonly
 */
public class ApiBase.Request : Object {

    public HttpMethod method { get; construct; }

    public string uri { get; construct; }

    Soup.Message message;

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

    [Version (since = "4.0")]
    /**
     * Add header with header object
     *
     * @param header    Header object
     * @param replace   Replace existing header with equal name or not
     */
    public void add_header (string name, string value, bool replace = true) {
        add_header_struct ({ name, value }, replace);
    }

    void add_header_struct (Header header, bool replace = true) {
        assert (message == null);

        if (header in headers && !replace) {
            return;
        }
        headers.add (header);
    }

    [Version (since = "3.0")]
    /**
     * Add header with header objects array
     *
     * @param headers   Header objects array
     * @param replace   Replace existing header with equal name or not
     */
    public void add_headers (Header[] headers, bool replace = true) {
        foreach (var header in headers) {
            add_header_struct (header, replace);
        }
    }

    [Version (since = "4.0")]
    /**
     * Add parameter with parameter data
     *
     * @param name      Parameter name
     * @param value     Parameter value
     */
    public void add_param (string name, string value) {
        add_param_struct ({ name, value });
    }

    void add_param_struct (Param parameter) {
        assert (message == null);

        parameters.add (parameter);
    }

    [Version (since = "3.0")]
    /**
     * Add parameters with an array
     *
     * @param parameters Parameter objeccts array
     */
    public void add_parameters (Param[] parameters) {
        foreach (var parameter in parameters) {
            add_param_struct (parameter);
        }
    }

    [Version (since = "6.0")]
    /**
     * Add content to request
     *
     * @param content  Content object
     */
    public void add_content (Content content) {
        assert (message == null);
        assert (method == HttpMethod.POST || method == HttpMethod.PUT);

        this.content = content;
    }

    [Version (since = "3.0")]
    /**
     * Get status code from internal {@link Soup.Message}.
     * Must be run after {@link form_message} or
     * {@link Session.exec}/{@link Session.exec_async}
     *
     * @return  Status
     */
    public Soup.Status get_status_code () {
        assert (message != null);

        return message.get_status ();
    }

    [Version (since = "5.0")]
    /**
     * Get formed message object
     * @return  Response body
     */
    public Soup.Message form_message () {
        if (message != null) {
            return message;
        }

        string new_uri;

        if (parameters.size != 0) {
            new_uri = form_paramed_uri ();
        } else {
            new_uri = uri;
        }

        message = new Soup.Message (method.to_string (), new_uri);

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

        return message;
    }

    string form_paramed_uri () {
        var final_parameters = new Gee.ArrayList<string> ();
        final_parameters.add_all_iterator (parameters.map<string> ((el) => {
            return el.to_string ();
        }));

        var new_uri = "%s?%s".printf (uri, string.joinv ("&", final_parameters.to_array ()));

        return new_uri;
    }

    [Version (since = "3.0")]
    /**
     * Simple request execution.
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    public GLib.Bytes simple_exec (
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return soup_wrapper.exec (this, cancellable);
    }

    [Version (since = "3.0")]
    /**
     * Asynchronious version of {@link simple_exec}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    public async GLib.Bytes simple_exec_async (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return yield soup_wrapper.exec_async (this, priority, cancellable);
    }
}
