valadoc_prog = find_program('valadoc')
fix_doc_prog = find_program('./fix-doc')

serialize_pkgs = []
foreach pkg : serialize_deps_pkgs
  serialize_pkgs += '--pkg=' + pkg
endforeach

api_base_pkgs = []
foreach pkg : api_base_deps_pkgs
  api_base_pkgs += '--pkg=' + pkg
endforeach

serialize_valadoc = custom_target(
  'serialize_valadoc',
  command: [valadoc_prog] + serialize_pkgs + [
    serialize_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + serialize_versioned_lib_name,
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', '@OUTPUT@',
  ],
  build_by_default: true,
  input: serialize_sources,
  output: 'serialize',
  depends: serialize_lib,
)

api_base_valadoc = custom_target(
  'api_base_valadoc',
  command: [valadoc_prog] + api_base_pkgs + [
    api_base_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + api_base_versioned_lib_name,
    '--package-version=' + meson.project_version(),
    '--vapidir=lib/serialize',
    '--verbose',
    '--force',
    '-o', '@OUTPUT@',
  ],
  build_by_default: true,
  input: api_base_sources,
  output: 'api-base',
  depends: [api_base_lib, serialize_lib],
)

custom_target(
  'fix_doc',
  command: [fix_doc_prog, soversion],
  build_by_default: true,
  input: api_base_sources,
  output: 'nothing',
  depends: [serialize_valadoc, api_base_valadoc],
)

serialize_devhelp = custom_target(
  'serialize_devhelp',
  command: [valadoc_prog] + serialize_pkgs + [
    serialize_sources,
    '--doclet=devhelp',
    '--target-glib=' + glib_min_version,
    '--package-name=' + serialize_versioned_lib_name,
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', '@OUTPUT@',
  ],
  build_by_default: true,
  input: serialize_sources,
  output: 'serialize-devhelp',
  depends: serialize_lib,
)

api_base_devhelp = custom_target(
  'api_base_devhelp',
  command: [valadoc_prog] + api_base_pkgs + [
    api_base_sources,
    '--doclet=devhelp',
    '--target-glib=' + glib_min_version,
    '--package-name=' + api_base_versioned_lib_name,
    '--package-version=' + meson.project_version(),
    '--vapidir=lib/serialize',
    '--verbose',
    '--force',
    '-o', '@OUTPUT@',
  ],
  build_by_default: true,
  input: api_base_sources,
  output: 'api-base-devhelp',
  depends: [api_base_lib, serialize_lib],
)

doc_dir = get_option('prefix') / get_option('datadir') / 'doc'
foreach book : [
  ['serialize-devhelp', serialize_versioned_lib_name],
  ['api-base-devhelp', api_base_versioned_lib_name],
]
  meson.add_install_script(
    'sh', '-c',
    'mkdir -p "${DESTDIR}@0@" && cp -r "@1@/." "${DESTDIR}@0@/" && sed -i "s/version=\"\"/version=\"2\"/" "${DESTDIR}@0@/@2@.devhelp2"'.format(
      doc_dir / book[1],
      meson.current_build_dir() / book[0] / book[1],
      book[1],
    ),
  )
endforeach
