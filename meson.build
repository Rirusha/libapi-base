project(
  'libapi-base',
  ['c', 'vala'],
  version: '7.8',
  meson_version: '>= 1.9.0',
  license: 'GPL-3.0-or-later',
)

libversion = meson.project_version().replace('.rc', '')
soversion = meson.project_version().split('.')[0]
glib_min_version = '2.76'

pkgconfig = import('pkgconfig')
gnome = import('gnome')

gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
json_glib_dep = dependency('json-glib-1.0')
libsoup_dep = dependency('libsoup-3.0')
libyaml_dep = dependency('yaml-0.1')

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
  '--vapi-comments',
  language: ['vala'],
)

subdir('vapi')
subdir('lib')
subdir('tests')

if get_option('documentation')
  subdir('doc')
endif

gnome.post_install()
