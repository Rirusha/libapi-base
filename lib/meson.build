vapi_sources = files(
  
)

vala_sources = files(
  'soup-wrapper/header.vala',
  'soup-wrapper/headers.vala',
  'soup-wrapper/parameter.vala',
  'soup-wrapper/post-content.vala',
  'soup-wrapper/soup-wrapper.vala',

  'api-error.vala',
  'jsoner.vala',
  'utils.vala',
)

libapi_base_sources = [
  vapi_sources,
  vala_sources,
]

libapi_base = shared_library(
  project_name,
  libapi_base_sources,
  dependencies: libapi_base_dependencies,
  vala_header: libapi_base_header,
  vala_vapi: libapi_base_vapi,
  vala_gir: libapi_base_gir,
  version: meson.project_version(),
  install: true,
  install_dir: [ true, true, true, true ],
)

libapi_base_dep = declare_dependency(
  link_with: libapi_base,
  include_directories: include_directories('.'),
  dependencies: libapi_base_dependencies
)

deps_conf = configuration_data()
deps_conf.set ('DEPS',  '\n'.join (deps_pkgs))

configure_file(
  input: libapi_base_deps + '.in',
  output: libapi_base_deps,
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
      meson.current_build_dir() / libapi_base_gir,
    ],
    input: libapi_base,
    output: libapi_base_typelib,
    depends: libapi_base,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  libapi_base,
  name: versioned_name,
  requires: libapi_base_dependencies,
  subdirs: [ versioned_name ],
  description: 'Base objects for API libraries',
  version: meson.project_version(),
  url: 'https://github.com/Rirusha/libapi-base',
)
