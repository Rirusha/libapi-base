project(
  'libapi-base',
  ['c', 'vala'],
  version: '6.1',
  meson_version: '>= 1.9.0',
  license: 'GPL-3.0-or-later',
)

libversion = meson.project_version().replace('.rc', '')

api_version = libversion.split('.')[0]
glib_min_version = '2.76'

pkgconfig = import('pkgconfig')
gnome = import('gnome')

gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
json_glib_dep = dependency('json-glib-1.0')
libsoup_dep = dependency('libsoup-3.0')

gee_girdir = gee_dep.get_variable('datadir') / 'gir-1.0'

add_project_arguments(
  '-w',
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
