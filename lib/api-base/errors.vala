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
 * Error from libsoup
 */
[Version (since = "3.0", deprecated = true, deprecated_since = "7.4")]
public errordomain ApiBase.SoupError {
    INTERNAL,
    CANCELLED;
}

/**
 * Bad status codes error.
 * Real code store in `code` field.
 */
public errordomain ApiBase.BadStatusCodeError {

    [Version (deprecated = true, deprecated_since = "7.4")]
    BAD_REQUEST = 400,
    [Version (deprecated = true, deprecated_since = "7.4")]
    UNAUTHORIZED = 401,
    [Version (deprecated = true, deprecated_since = "7.4")]
    FORBIDDEN = 403,
    [Version (deprecated = true, deprecated_since = "7.4")]
    NOT_FOUND = 404,
    [Version (deprecated = true, deprecated_since = "7.4")]
    METHOD_NOT_ALLOWED = 405,
    [Version (deprecated = true, deprecated_since = "7.4")]
    REQUEST_TIMEOUT = 408,
    [Version (deprecated = true, deprecated_since = "7.4")]
    CONFLICT = 409,
    [Version (deprecated = true, deprecated_since = "7.4")]
    GONE = 410,
    [Version (deprecated = true, deprecated_since = "7.4")]
    PAYLOAD_TOO_LARGE = 413,
    [Version (deprecated = true, deprecated_since = "7.4")]
    UNSUPPORTED_MEDIA_TYPE = 415,
    [Version (deprecated = true, deprecated_since = "7.4")]
    TOO_MANY_REQUESTS = 429,
    [Version (deprecated = true, deprecated_since = "7.4")]
    INTERNAL_SERVER_ERROR = 500,
    [Version (deprecated = true, deprecated_since = "7.4")]
    NOT_IMPLEMENTED = 501,
    [Version (deprecated = true, deprecated_since = "7.4")]
    BAD_GATEWAY = 502,
    [Version (deprecated = true, deprecated_since = "7.4")]
    SERVICE_UNAVAILABLE = 503,
    [Version (deprecated = true, deprecated_since = "7.4")]
    GATEWAY_TIMEOUT = 504,
    [Version (deprecated = true, deprecated_since = "7.4")]
    CONNECTION_TIMED_OUT = 522,

    UNKNOWN = 0
}
