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

    HashTable<string, Array<Header>> presets_table = new HashTable<string, Array<Header>> (str_hash, str_equal);

    construct {
        if (Environment.get_variable ("API_BASE_SOUP_TRACE") != null) {
            var logger = new Soup.Logger (BODY);

            logger.set_printer ((logger, level, direction, data) => {
                switch (direction) {
                    case '<':
                    case '>':
                        debug ("%c: %s", direction, data);
                        break;

                    default:
                        debug ("");
                        break;
                }
            });

            add_feature (logger);
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

    void fill_request_presets (Request request) {
        foreach (var preset_name in request.presets) {
            Array<Header> headers = presets_table.get (preset_name);
            if (headers != null) {
                request.add_headers ((Header[]) headers.data, false);
            }
        }
    }

    void check_status_code (Soup.Status status_code, Bytes? bytes) throws SoupError, BadStatusCodeError {
        if (status_code == Soup.Status.OK) {
            return;
        }

        string error_message = (string) (bytes.get_data ()) ?? "";

        throw get_error (status_code, error_message);
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
    [Version (since = "3.0")]
    public GLib.Bytes? exec (
        Request request,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        GLib.Bytes? bytes = null;

        fill_request_presets (request);

        string?[] trys = { null };
        if (base_urls.size > 0) {
            trys = base_urls.to_array ();
        }

        foreach (var base_url in trys) {
            request.init_message (base_url);
            var message = request.message;

            debug ("Exec %s", message.uri.to_string ());

            if (message == null) {
                throw new SoupError.INTERNAL ("Bad message");
            }

            try {
                try {
                    bytes = send_and_read (message, cancellable);

                } catch (Error e) {
                    if (e is IOError.CANCELLED) {
                        throw new SoupError.CANCELLED (e.message);
                    } else {
                        throw new SoupError.INTERNAL ("%s %s (%s): %s".printf (
                            message.method,
                            message.uri.to_string (),
                            message.status_code.to_string (),
                            e.message
                        ));
                    }
                }

                check_status_code (request.get_status_code (), bytes);

                if (base_url != null) {
                    base_urls.raise (base_url);
                    debug ("Exec with %s success, raise it", base_url);
                }
                return bytes;
            } catch (BadStatusCodeError e) {
                if (base_url == trys[trys.length - 1]) {
                    throw e;
                } else {
                    debug ("Exec with %s failed, try next", base_url);
                }
            }
        }

        return null;
    }

    /**
     * Asynchronously execute the {@link Request}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     */
    [Version (since = "3.0")]
    public async GLib.Bytes? exec_async (
        Request request,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        GLib.Bytes? bytes = null;

        fill_request_presets (request);

        string?[] trys = { null };
        if (base_urls.size > 0) {
            trys = base_urls.to_array ();
        }

        foreach (var base_url in trys) {
            request.init_message (base_url);
            var message = request.message;

            var exec_uri = message.uri.to_string ();
            debug ("Exec %s", exec_uri);

            if (message == null) {
                throw new SoupError.INTERNAL ("Bad message");
            }

            try {
                try {
                    bytes = yield send_and_read_async (message, priority, cancellable);

                } catch (Error e) {
                    if (e is IOError.CANCELLED) {
                        throw new SoupError.CANCELLED (e.message);
                    } else {
                        throw new SoupError.INTERNAL ("%s %s: %s".printf (message.method, message.uri.to_string (), e.message));
                    }
                }

                check_status_code (request.get_status_code (), bytes);

                debug ("Exec %s success", exec_uri);
                if (base_url != null) {
                    if (base_urls.raise (base_url)) {
                        debug ("%s good, raise it", base_url);
                    }
                }
                return bytes;
            } catch (BadStatusCodeError e) {
                debug ("Exec %s failed", exec_uri);
                if (base_url == trys[trys.length - 1]) {
                    throw e;
                } else {
                    debug ("%s bad, try next", base_url);
                }
            }
        }

        return null;
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
