# libapi-base

Base objects for API libraries written in Vala.

## Description

libapi-base provides a set of base classes and utilities for building API libraries in Vala. It includes:

- **DataObject**: Base class for JSON serialization/deserialization
- **Jsoner**: Advanced JSON handling with case conversion support
- **SoupWrapper**: HTTP client wrapper for libsoup-3.0
- **Utils**: Utility functions for string manipulation and data conversion

## Requirements

- Vala compiler (>= 0.56)
- GLib (>= 2.76)
- libsoup-3.0
- json-glib-1.0
- gee-0.8

## Building

```bash
meson setup _build
ninja -C _build
```

## Testing

```bash
ninja -C _build test
```

## Debug

There is env vars that can be useed:

- `API_BASE_SOUP_TRACE_FILENAME`: Filename in which will be printed soupe trace. Can be used with `stdout` to print in stdout
- `SERIALIZE_UNKNOWN_PROPS`: Print warnings if json object has field but lang object doesn't
- `SERIALIZE_UNKNOWN_FIELDS`: Print warnings if lang object has field but json object doesn't

## Documentation

[Documentation here](https://rirusha.altlinux.team/libapi-base/)

## License

GPL-3.0-or-later
