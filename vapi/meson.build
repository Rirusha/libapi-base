local_vapi_dir = meson.current_source_dir()

local_vapi_sources = files(
  'yaml-0.1.vapi',
)

install_data(
  local_vapi_sources,
  install_dir: get_option('prefix') / get_option('datadir') / 'vala' / 'vapi',
)

install_data(
  'yaml-0.1.deps',
  install_dir: get_option('prefix') / get_option('datadir') / 'vala' / 'vapi',
)


install_data(
  'Yaml-0.1.gir',
  install_dir: get_option('prefix') / get_option('datadir') / 'gir-1.0',
)

if get_option('introspection')
  g_ir_compiler = find_program('g-ir-compiler')
  custom_target(
    'yaml-typelib',
    command: [
      g_ir_compiler,
      '--output', '@OUTPUT@',
      '@INPUT@',
    ],
    input: 'Yaml-0.1.gir',
    output: 'Yaml-0.1.typelib',
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif
