project(
  'libapi-base',
  ['c', 'vala'],
  version: '1.7',
  meson_version: '>= 1.0.0',
  license: 'GPL-3.0-or-later',
)

api_version = '1'
glib_min_version = '2.76'

name = 'api-base'
gir_name = 'ApiBase'

versioned_name = name + '-' + api_version
versioned_lib_name = meson.project_name() + '-' + api_version
versioned_gir_name = gir_name + '-' + api_version

deps_name = versioned_lib_name + '.deps'
header_name = versioned_lib_name + '.h'
vapi_name = versioned_lib_name + '.vapi'
gir_name = versioned_gir_name + '.gir'
typelib_name = versioned_gir_name + '.typelib'

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

dependencies = [
  gee_dep,
  gio_dep,
  json_glib_dep,
  libsoup_dep,
]

pkgconfig_requires = dependencies

gee_girdir = gee_dep.get_variable('datadir') / 'gir-1.0'

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
