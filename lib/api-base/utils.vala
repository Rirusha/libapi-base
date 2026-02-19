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

namespace ApiBase {

    internal BadStatusCodeError get_error (Soup.Status status_code, string error_response) {
        switch (status_code) {
            case Soup.Status.BAD_REQUEST:
                return new BadStatusCodeError.BAD_REQUEST (error_response);
            case Soup.Status.UNAUTHORIZED:
                return new BadStatusCodeError.UNAUTHORIZED (error_response);
            case Soup.Status.FORBIDDEN:
                return new BadStatusCodeError.FORBIDDEN (error_response);
            case Soup.Status.NOT_FOUND:
                return new BadStatusCodeError.NOT_FOUND (error_response);
            case Soup.Status.METHOD_NOT_ALLOWED:
                return new BadStatusCodeError.METHOD_NOT_ALLOWED (error_response);
            case Soup.Status.REQUEST_TIMEOUT:
                return new BadStatusCodeError.REQUEST_TIMEOUT (error_response);
            case Soup.Status.CONFLICT:
                return new BadStatusCodeError.CONFLICT (error_response);
            case Soup.Status.GONE:
                return new BadStatusCodeError.GONE (error_response);
            case Soup.Status.REQUEST_ENTITY_TOO_LARGE:
                return new BadStatusCodeError.PAYLOAD_TOO_LARGE (error_response);
            case Soup.Status.UNSUPPORTED_MEDIA_TYPE:
                return new BadStatusCodeError.UNSUPPORTED_MEDIA_TYPE (error_response);
            case 429:
                return new BadStatusCodeError.TOO_MANY_REQUESTS (error_response);
            case Soup.Status.INTERNAL_SERVER_ERROR:
                return new BadStatusCodeError.INTERNAL_SERVER_ERROR (error_response);
            case Soup.Status.NOT_IMPLEMENTED:
                return new BadStatusCodeError.NOT_IMPLEMENTED (error_response);
            case Soup.Status.BAD_GATEWAY:
                return new BadStatusCodeError.BAD_GATEWAY (error_response);
            case Soup.Status.SERVICE_UNAVAILABLE:
                return new BadStatusCodeError.SERVICE_UNAVAILABLE (error_response);
            case Soup.Status.GATEWAY_TIMEOUT:
                return new BadStatusCodeError.GATEWAY_TIMEOUT (error_response);
            default:
                return new BadStatusCodeError.UNKNOWN (status_code.to_string () + ": " + error_response);
        }
    }
}
