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

## Documentation

[Documentation here](https://rirusha.altlinux.team/libapi-base/)

## License

GPL-3.0-or-later
