vapi_sources = files(
  
)

vala_sources = files(
  'soup-wrapper/header.vala',
  'soup-wrapper/headers.vala',
  'soup-wrapper/parameter.vala',
  'soup-wrapper/post-content.vala',
  'soup-wrapper/soup-wrapper.vala',

  'data-object.vala',
  'jsoner.vala',
  'utils.vala',
)

sources = [
  vapi_sources,
  vala_sources,
]

lib = shared_library(
  versioned_name,
  sources,
  dependencies: dependencies,
  vala_header: header_name,
  vala_vapi: vapi_name,
  vala_gir: gir_name,
  version: meson.project_version(),
  install: true,
  install_dir: [ true, true, true, true ],
)

lib_dep = declare_dependency(
  link_with: lib,
  include_directories: include_directories('.'),
  dependencies: dependencies
)

deps_conf = configuration_data()
deps_conf.set ('DEPS',  '\n'.join (deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: deps_name,
  configuration: deps_conf,
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
      meson.current_build_dir() / gir_name,
    ],
    input: lib,
    output: typelib_name,
    depends: lib,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  lib,
  name: versioned_lib_name,
  requires: pkgconfig_requires,
  subdirs: [ versioned_lib_name ],
  description: 'Base objects for API libraries',
  version: meson.project_version(),
  url: 'https://gitlab.gnome.org/Rirusha/libapi-base',
)
