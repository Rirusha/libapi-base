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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Soup;

/**
 * A wrapper class for {@link Soup.Session}
 */
public sealed class ApiBase.Session : Soup.Session {

    /**
     * Cookies storage type
     */
    public CookieJarType cookie_jar_type { get; private set; default = NONE; }

    /**
     * Path to cookies
     */
    public string? cookies_file_path { get; private set; }

    Urls base_urls = new Urls ();

    internal HashTable<string, Array<Header>> presets_table = new HashTable<string, Array<Header>> (str_hash, str_equal);

    FileIOStream trace_file_stream;

    construct {
        var trace_filename = Environment.get_variable ("API_BASE_SOUP_TRACE_FILENAME");
        if (trace_filename != null) {
            if (trace_filename != "stdout") {
                try {
                    var f = File.new_for_path (trace_filename);
                    if (!f.query_exists ()) {
                        trace_file_stream = f.create_readwrite (GLib.FileCreateFlags.REPLACE_DESTINATION);
                    }
                } catch (Error e) {
                    error ("Can't create %s: %s", trace_filename, e.message);
                }
            }

            var logger = new Soup.Logger (BODY);
            logger.set_printer (log_printer);
            add_feature (logger);
        }
    }

    void log_printer (Soup.Logger logger, Soup.LoggerLogLevel level, char direction, string data) {
        string d;

        switch (direction) {
            case '<':
            case '>':
                d = "%c: %s".printf (direction, data);
                break;

            default:
                d = "";
                break;
        }

        if (trace_file_stream != null) {
            try {
                trace_file_stream.output_stream.write (d.data);
            } catch (Error e) {
                warning ("Can't write to trace file: %s", e.message);
            }
        } else {
            stdout.printf ("%s\n", d);
        }
    }

    /**
     * Init cookiew with type and path
     *
     * @param cookie_jar_type   Cookies storage type
     * @param cookies_file_path Path to cookies
     */
    [Version (since = "3.0")]
    public void init_cookies (
        CookieJarType cookie_jar_type,
        string cookies_file_path
    ) {
        this.cookie_jar_type = cookie_jar_type;
        this.cookies_file_path = cookies_file_path;

        reload_cookies ();
    }

    /**
     * Reload cookies, fully resetting it.
     */
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
            if (has_feature (feature_type)) {
                remove_feature_by_type (feature_type);
            }
        }

        if (cookies_file_path != null) {
            Soup.CookieJar cookie_jar;

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

            add_feature (cookie_jar);
            debug ("Cookies updated. New cookies file: \"%s\"", cookies_file_path);
        }
    }

    /**
     * Add preset to session. Headers presets can be used with {@link Request.add_preset_name}
     */
    public void add_headers_preset (string preset_name, Header[] headers) {
        if (!presets_table.contains (preset_name)) {
            presets_table[preset_name] = new Array<Header> ();
        }
        foreach (var header in headers) {
            presets_table[preset_name].append_val (header);
        }
    }

    public void add_base_url (string base_url) {
        base_urls.add (base_url);
    }

    public void remove_base_url (string base_url) {
        base_urls.remove (base_url);
    }

    /**
     * Synchronously execute the {@link Request}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    [Version (since = "3.0", deprecated = true, deprecated_since = "7.4", replacement = "send_and_read")]
    public GLib.Bytes? exec (
        Request request,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        try {
            return send_and_read (request, cancellable);
        } catch (Soup.SessionError e) {
            throw new SoupError.INTERNAL (e.message);
        } catch (IOError e) {
            throw new SoupError.INTERNAL (e.message);
        } catch (TlsError e) {
            throw new SoupError.INTERNAL (e.message);
        } catch (ResolverError e) {
            throw new SoupError.INTERNAL (e.message);
        }
    }

    /**
     * Asynchronously execute the {@link Request}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    [Version (since = "3.0", deprecated = true, deprecated_since = "7.4", replacement = "send_and_read_async")]
    public async GLib.Bytes? exec_async (
        Request request,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        try {
            return yield send_and_read_async (request, priority, cancellable);
        } catch (Soup.SessionError e) {
            throw new SoupError.INTERNAL (e.message);
        } catch (IOError e) {
            throw new SoupError.INTERNAL (e.message);
        } catch (TlsError e) {
            throw new SoupError.INTERNAL (e.message);
        } catch (ResolverError e) {
            throw new SoupError.INTERNAL (e.message);
        }
    }

    /**
     * Send {@link Request}.
     *
     * @throws Soup.SessionError    Session error from libsoup
     * @throws IOError              Error from reading stream or reqeust cancellation
     * @throws ResolverError         An error code from a Resolver routine
     * @throws TlsError             An error code from a TLS-related routine
     * @throws BadStatusCodeError   Bad status code
     */
    [Version (since = "7.4")]
    public new InputStream? send (
        Request request,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        Error? err = null;

        foreach (var base_url in base_urls.copy ()) {
            InputStream? input_stream = null;

            var message = get_message (request, base_url);

            if (message == null) {
                return null;
            }

            var send_uri = message.uri.to_string ();
            debug_pre (send_uri);

            try {
                input_stream = base.send (message, cancellable);

                request.check_status_code (input_stream, cancellable);
                debug_success (send_uri, base_url);

                return input_stream;
            } catch (Error e) {
                if (e is IOError) {
                    throw (IOError) e;
                }
                err = e;
                debug_failed (send_uri, base_url);
            }
        }

        detect_error (err);
        debug_post ();
        return null;
    }

    /**
     * Send and read to bytes {@link Request}.
     *
     * @throws Soup.SessionError    Session error from libsoup
     * @throws IOError              Error from reading stream or reqeust cancellation
     * @throws ResolverError         An error code from a Resolver routine
     * @throws TlsError             An error code from a TLS-related routine
     * @throws BadStatusCodeError   Bad status code
     */
    [Version (since = "7.4")]
    public new Bytes? send_and_read (
        Request request,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        Bytes? bytes = null;
        var out_stream = new MemoryOutputStream.resizable ();

        try {
            if (send_and_splice (request, out_stream, CLOSE_TARGET | CLOSE_SOURCE, cancellable) != -1) {
                bytes = out_stream.steal_as_bytes ();
            }
        } catch (IOError e) {}

        return bytes;
    }

    /**
     * Send and splice to stream {@link Request}.
     *
     * @throws Soup.SessionError    Session error from libsoup
     * @throws IOError              Error from reading stream or reqeust cancellation
     * @throws ResolverError         An error code from a Resolver routine
     * @throws TlsError             An error code from a TLS-related routine
     * @throws BadStatusCodeError   Bad status code
     */
    [Version (since = "7.4")]
    public new ssize_t send_and_splice (
        Request request,
        OutputStream out_stream,
        OutputStreamSpliceFlags flags,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        var stream = send (request, cancellable);
        if (stream == null) {
            return -1;
        }
        return out_stream.splice (stream, flags, cancellable);
    }

    /**
     * Asynchronious version of {@link send}.
     *
     * @throws Soup.SessionError    Session error from libsoup
     * @throws IOError              Error from reading stream or reqeust cancellation
     * @throws ResolverError         An error code from a Resolver routine
     * @throws TlsError             An error code from a TLS-related routine
     * @throws BadStatusCodeError   Bad status code
     */
    [Version (since = "7.4")]
    public async new InputStream? send_async (
        Request request,
        int io_priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        Error? err = null;

        foreach (var base_url in base_urls.copy ()) {
            InputStream? input_stream = null;

            var message = get_message (request, base_url);

            if (message == null) {
                return null;
            }

            var send_uri = message.uri.to_string ();
            debug_pre (send_uri);

            try {
                input_stream = yield base.send_async (message, io_priority, cancellable);

                request.check_status_code (input_stream, cancellable);
                debug_success (send_uri, base_url);

                return input_stream;
            } catch (Error e) {
                if (e is IOError) {
                    throw (IOError) e;
                }
                err = e;
                debug_failed (send_uri, base_url);
            }
        }

        detect_error (err);
        debug_post ();
        return null;
    }

    /**
     * Asynchronious version of {@link send_and_read}.
     *
     * @throws Soup.SessionError    Session error from libsoup
     * @throws IOError              Error from reading stream or reqeust cancellation
     * @throws ResolverError         An error code from a Resolver routine
     * @throws TlsError             An error code from a TLS-related routine
     * @throws BadStatusCodeError   Bad status code
     */
    [Version (since = "7.4")]
    public async new Bytes? send_and_read_async (
        Request request,
        int io_priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        Bytes? bytes = null;
        var out_stream = new MemoryOutputStream.resizable ();

        try {
            if ((yield send_and_splice_async (request, out_stream, CLOSE_TARGET | CLOSE_SOURCE, io_priority, cancellable)) != -1) {
                bytes = out_stream.steal_as_bytes ();
            }
        } catch (IOError e) {}

        return bytes;
    }

    /**
     * Asynchronious version of {@link send_and_splice}.
     *
     * @throws Soup.SessionError    Session error from libsoup
     * @throws IOError              Error from reading stream or reqeust cancellation
     * @throws ResolverError         An error code from a Resolver routine
     * @throws TlsError             An error code from a TLS-related routine
     * @throws BadStatusCodeError   Bad status code
     */
    [Version (since = "7.4")]
    public async new ssize_t send_and_splice_async (
        Request request,
        OutputStream out_stream,
        OutputStreamSpliceFlags flags,
        int io_priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        var stream = yield send_async (request, io_priority, cancellable);
        if (stream == null) {
            return -1;
        }
        return yield out_stream.splice_async (stream, flags, io_priority, cancellable);
    }

    Soup.Message? get_message (Request request, string? base_url = null) {
        request.peak_presets_from (this);
        request.init_message (base_url);

        return request.message;
    }

    [Diagnostics]
    inline void debug_pre (string uri) {
        debug ("Send %s", uri);
    }

    [Diagnostics]
    inline void debug_post () {
        debug ("No next");
    }

    [Diagnostics]
    inline void debug_success (string uri, string? base_url = null) {
        debug ("Exec %s success", uri);
        if (base_url != null) {
            if (base_urls.raise (base_url)) {
                debug ("%s good, raise it", base_url);
            }
        }
    }

    [Diagnostics]
    inline void debug_failed (string uri, string? base_url = null) {
        if (base_url != null) {
            debug ("Exec %s failed, %s bad, try next", uri, base_url);
        } else {
            debug ("Exec %s failed", uri);
        }
    }

    void detect_error (Error e) throws Soup.SessionError, IOError, TlsError, ResolverError, BadStatusCodeError {
        if (e is Soup.SessionError) {
            throw (Soup.SessionError) e;
        } else if (e is IOError) {
            throw (IOError) e;
        } else if (e is BadStatusCodeError) {
            throw (BadStatusCodeError) e;
        } else if (e is IOError) {
            throw (IOError) e;
        } else if (e is ResolverError) {
            throw (ResolverError) e;
        } else {
            message (e.domain.to_string ());
            assert_not_reached ();
        }
    }

    public new async Soup.WebsocketConnection websocket_connect_async (
        Request request,
        string? origin,
        string[]? protocols,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError {
        string? base_url = base_urls.first ();
        if (base_urls.size > 1) {
            warning ("Websockets don't support base urls iteration");
        }

        request.init_message (base_url);
        var message = request.message;
        if (message == null) {
            throw new SoupError.INTERNAL ("Bad message");
        }

        try {
            return yield base.websocket_connect_async (message, origin, protocols, priority, cancellable);
        } catch (Error e) {
            throw new SoupError.INTERNAL (e.message);
        }
    }
}
