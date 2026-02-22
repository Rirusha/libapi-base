api_base_name = 'api-base'

api_base_versioned_name = api_base_name + '-' + api_version
api_base_versioned_lib_name = 'lib' + api_base_name + '-' + api_version

api_base_deps_name = api_base_versioned_lib_name + '.deps'
api_base_header_name = api_base_versioned_lib_name + '.h'
api_base_vapi_name = api_base_versioned_lib_name + '.vapi'

api_base_deps_pkgs = [
  'gio-2.0',
  'libsoup-3.0',
  serialize_versioned_lib_name,
]

api_base_dependencies = [
  serialize_lib_dep,
  gio_dep,
  libsoup_dep,
]

api_base_vapi_sources = files(
  
)

api_base_vala_sources = files(
  'content.vala',
  'enums.vala',
  'errors.vala',
  'header.vala',
  'parameter.vala',
  'request.vala',
  'session.vala',
  'utils.vala',
)

api_base_sources = [
  api_base_vapi_sources,
  api_base_vala_sources,
]

api_base_lib = library(
  api_base_versioned_name,
  api_base_sources,
  dependencies: api_base_dependencies,
  vala_header: api_base_header_name,
  vala_vapi: api_base_vapi_name,
  version: libversion,
  install: true,
  install_dir: [ true, true, true],
)

api_base_lib_dep = declare_dependency(
  link_with: api_base_lib,
  include_directories: include_directories('.'),
  dependencies: api_base_dependencies
)

api_base_deps_conf = configuration_data()
api_base_deps_conf.set ('DEPS',  '\n'.join (api_base_deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: api_base_deps_name,
  configuration: api_base_deps_conf,
  install: true,
  install_dir: get_option('datadir') / 'vala' / 'vapi',
)

pkgconfig.generate(
  api_base_lib,
  name: api_base_versioned_lib_name,
  requires: api_base_dependencies,
  subdirs: [ api_base_versioned_lib_name ],
  description: 'Base objects for API libraries',
  version: libversion,
  url: 'https://gitlab.gnome.org/Rirusha/libapi-base',
)
