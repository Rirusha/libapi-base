/*
 * Copyright (C) 2025 Vladimir Vaskov <rirusha@altlinux.org>
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
 * Request object. Can handle parameters, headers, post content.
 * {@link Session.exec} and {@link Session.exec_async}
 * form message via {@link form_message} and set {@link this} to readonly
 *
 * @since 3.0
 */
public sealed class ApiBase.Request : Object {

    public HttpMethod method { get; construct; }

    public string uri { get; construct; }

    Soup.Message message;

    bool readonly = false;

    Gee.HashSet<Header> headers = new Gee.HashSet<Header> (
        (el) => {
            return str_hash (el.name);
        },
        (el1, el2) => {
            return str_equal (el1.name, el2.name);
        }
    );

    Gee.HashSet<ApiBase.Parameter> parameters = new Gee.HashSet<ApiBase.Parameter> (
        (el) => {
            return str_hash (el.name);
        },
        (el1, el2) => {
            return str_equal (el1.name, el2.name);
        }
    );

    Gee.HashSet<string> presets = new Gee.HashSet<string> ();

    PostContent? post_content = null;

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
        headers = new Gee.HashSet<Header> (
            (el) => {
                return str_hash (el.name);
            },
            (el1, el2) => {
                return str_equal (el1.name, el2.name);
            }
        );
    }

    /**
     * Add header with header data
     *
     * @param name      Header name
     * @param value     Header value
     * @param replace   Replace existing header with equal name or not
     *
     * @since 3.0
     */
    public void add_header_simple (string name, string value, bool replace = true) {
        add_header (new Header (name, value), replace);
    }

    /**
     * Add header with header object
     *
     * @param header    Header object
     * @param replace   Replace existing header with equal name or not
     *
     * @since 3.0
     */
    public void add_header (Header header, bool replace = true) {
        assert (!readonly);

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
     *
     * @since 3.0
     */
    public void add_headers (Header[] headers, bool replace = true) {
        foreach (var header in headers) {
            add_header (header, replace);
        }
    }

    /**
     * Add header preset name. Presets can be set via {@link Session.add_headers_preset} and used only with {@link Session}
     *
     * @param preset_name   Name of preset
     *
     * @since 3.0
     */
    public void add_preset_name (string preset_name) {
        assert (!readonly);

        presets.add (preset_name);
    }

    internal string[] get_presets () {
        return presets.to_array ();
    }

    /**
     * Add parameter with parameter data
     *
     * @param name      Parameter name
     * @param value     Parameter value
     *
     * @since 3.0
     */
    public void add_parameter_simple (string name, string value) {
        add_parameter (new ApiBase.Parameter (name, value));
    }

    /**
     * Add parameter with parameter object
     *
     * @param parameter Parameter objecct
     *
     * @since 3.0
     */
    public void add_parameter (ApiBase.Parameter parameter) {
        assert (!readonly);

        parameters.add (parameter);
    }

    /**
     * Add parameters with an array
     *
     * @param parameters Parameter objeccts array
     *
     * @since 3.0
     */
    public void add_parameters (ApiBase.Parameter[] parameters) {
        foreach (var parameter in parameters) {
            add_parameter (parameter);
        }
    }

    /**
     * Add post content to request
     *
     * @param post_content  Post content object
     *
     * @since 3.0
     */
    public void add_post_content (PostContent post_content) {
        assert (!readonly);
        assert (method == HttpMethod.POST);

        this.post_content = post_content;
    }

    /**
     * Get status code from internal {@link Soup.Message}.
     * Must be run after {@link form_message} or
     * {@link Session.exec}/{@link Session.exec_async}
     *
     * @return  Status
     *
     * @since 3.0
     */
    public Soup.Status get_status_code () {
        assert (message != null);

        return message.get_status ();
    }

    /**
     * Form message with all data (headers, params, etc).
     * Request become readonly.
     *
     * If run second time, returns formed message.
     *
     * @return  Message object
     *
     * @since 3.0
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

        if (post_content != null) {
            message.set_request_body_from_bytes (
                post_content.content_type.to_string (),
                post_content.get_bytes ()
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

    /**
     * Simple request execution.
     *
     * @since 3.0
     */
    public GLib.Bytes simple_exec (
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return soup_wrapper.exec (this, cancellable);
    }

    /**
     * Asynchronious version of {@link simple_exec}
     *
     * @since 3.0
     */
    public async GLib.Bytes simple_exec_async (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return yield soup_wrapper.exec_async (this, priority, cancellable);
    }
}
