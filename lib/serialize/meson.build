serialize_name = 'serialize'
serialize_gir_name = 'Serialize'

serialize_versioned_name = serialize_name + '-' + api_version
serialize_versioned_lib_name = serialize_name + '-' + api_version
serialize_versioned_gir_name = serialize_gir_name + '-' + api_version

serialize_deps_name = serialize_versioned_lib_name + '.deps'
serialize_header_name = serialize_versioned_lib_name + '.h'
serialize_vapi_name = serialize_versioned_lib_name + '.vapi'
serialize_gir_name = serialize_versioned_gir_name + '.gir'
serialize_typelib_name = serialize_versioned_gir_name + '.typelib'

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
  'collection-factory.vala',
  'convert.vala',
  'data-object.vala',
  'enums.vala',
  'errors.vala',
  'jsoner.vala',
  'utils.vala',
)

serialize_sources = [
  serialize_vapi_sources,
  serialize_vala_sources,
]

serialize_lib = shared_library(
  serialize_versioned_name,
  serialize_sources,
  dependencies: serialize_dependencies,
  vala_header: serialize_header_name,
  vala_vapi: serialize_vapi_name,
  vala_gir: serialize_gir_name,
  version: libversion,
  install: true,
  install_dir: [ true, true, true, true ],
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

if get_option('introspection')
  g_ir_compiler = find_program('g-ir-compiler')
  custom_target(
    'typelib',
    command: [
      g_ir_compiler,
      '--shared-library', '@PLAINNAME@',
      '--output', '@OUTPUT@',
      '--includedir', gee_girdir,
      meson.current_build_dir() / serialize_gir_name,
    ],
    input: serialize_lib,
    output: serialize_typelib_name,
    depends: serialize_lib,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  serialize_lib,
  name: serialize_versioned_lib_name,
  requires: serialize_dependencies,
  subdirs: [ serialize_versioned_lib_name ],
  description: 'Base objects for API libraries',
  version: libversion,
  url: 'https://gitlab.gnome.org/Rirusha/libapi-base',
)
