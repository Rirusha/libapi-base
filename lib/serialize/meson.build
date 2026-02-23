serialize_name = 'serialize'

serialize_versioned_name = serialize_name + '-' + api_version
serialize_versioned_lib_name = 'lib' + serialize_name + '-' + api_version

serialize_deps_name = serialize_versioned_lib_name + '.deps'
serialize_header_name = serialize_versioned_lib_name + '.h'
serialize_vapi_name = serialize_versioned_lib_name + '.vapi'

serialize_deps_pkgs = [
  'json-glib-1.0',
  'gee-0.8',
  'gio-2.0',
]

serialize_dependencies = [
  gee_dep,
  gio_dep,
  json_glib_dep,
]

serialize_vapi_sources = files(
  
)

serialize_vala_sources = files(
  'collections/array.vala',
  'collections/dict.vala',

  'jsoner/deserialize-async.vala',
  'jsoner/deserialize-sync.vala',
  'jsoner/serialize-async.vala',
  'jsoner/serialize-sync.vala',

  'object-helpers/data-object.vala',
  'object-helpers/has-complex-collections.vala',
  'object-helpers/has-fallback.vala',
  'object-helpers/type-famaly.vala',

  'collection-factory.vala',
  'convert.vala',
  'enums.vala',
  'errors.vala',
  'jsoner.vala',
  'settings.vala',
  'utils.vala',
)

serialize_sources = [
  serialize_vapi_sources,
  serialize_vala_sources,
]

serialize_lib = library(
  serialize_versioned_name,
  serialize_sources,
  dependencies: serialize_dependencies,
  vala_header: serialize_header_name,
  vala_vapi: serialize_vapi_name,
  version: libversion,
  install: true,
  install_dir: [ true, true, true ],
)

serialize_lib_dep = declare_dependency(
  link_with: serialize_lib,
  include_directories: include_directories('.'),
  dependencies: serialize_dependencies
)

serialize_deps_conf = configuration_data()
serialize_deps_conf.set ('DEPS',  '\n'.join (serialize_deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: serialize_deps_name,
  configuration: serialize_deps_conf,
  install: true,
  install_dir: get_option('datadir') / 'vala' / 'vapi',
)

pkgconfig.generate(
  serialize_lib,
  name: serialize_versioned_lib_name,
  requires: serialize_dependencies,
  subdirs: [ serialize_versioned_lib_name ],
  description: 'Base objects for API libraries',
  version: libversion,
  url: 'https://gitlab.gnome.org/Rirusha/libapi-base',
)
