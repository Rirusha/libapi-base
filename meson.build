project(
  'libapi-base',
  ['c', 'vala'],
  version: '1.3',
  meson_version: '>= 1.0.0',
  license: 'GPL-3.0-or-later',
)

api_version = '1'
glib_min_version = '2.76'

project_name = meson.project_name()
gir_name = 'ApiBase'

versioned_name = meson.project_name() + '-' + api_version
versioned_gir_name = gir_name + '-' + api_version

libapi_base_deps = versioned_name + '.deps'
libapi_base_header = project_name + '.h'
libapi_base_vapi = versioned_name + '.vapi'
libapi_base_gir = versioned_gir_name + '.gir'
libapi_base_typelib = versioned_gir_name + '.typelib'

pkgconfig = import('pkgconfig')
gnome = import('gnome')

deps_pkgs = [
  'libsoup-3.0',
  'json-glib-1.0',
  'gee-0.8',
  'gio-2.0',
]

gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
json_glib_dep = dependency('libsoup-3.0')
libsoup_dep = dependency('json-glib-1.0')

libapi_base_dependencies = [
  gee_dep,
  gio_dep,
  json_glib_dep,
  libsoup_dep,
]

gee_girdir = gee_dep.get_variable('datadir') / 'gir-1.0'
gee_vapidir = gee_dep.get_variable('datadir') / 'vala' / 'vapi'

add_project_arguments(
  # GCC14 COMPILE ERROR
  '-Wno-int-conversion',
  language: ['c'],
)

add_project_arguments(
  '--abi-stability',
  '--hide-internal',
  '--target-glib', glib_min_version,
  '--vapidir', meson.current_source_dir(),
  language: ['vala'],
)

subdir('lib')
subdir('tests')

if get_option('documentation')
  subdir('doc')
endif

gnome.post_install()
