valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : serialize_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

serialize_trg = custom_target(
  'serialize_valadoc',
  command: [ valadoc ] + pkgs +
  [
    serialize_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + serialize_versioned_lib_name,
    '--package-version=' + libversion,
    '--verbose',
    '--force',
    '-o', '@OUTPUT@',
  ],
  build_by_default: true,
  input : serialize_sources,
  output: 'serialize',
  depends: serialize_lib,
)

valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : api_base_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

api_base_trg = custom_target(
  'api_base_valadoc',
  command: [ valadoc ] + pkgs +
  [
    api_base_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + api_base_versioned_lib_name,
    '--package-version=' + libversion,
    '--importdir=lib/serialize',
    '--import=' + 'Serialize-6',
    '--verbose',
    '--force',
    '-o', '@OUTPUT@',
  ],
  build_by_default: true,
  input : api_base_sources,
  output: 'api-base',
  depends: [api_base_lib, serialize_lib]
)

valadoc = find_program('./fix-doc')
custom_target(
  'fix_doc',
  command: [ valadoc, api_version ],
  build_by_default: true,
  input : api_base_sources,
  output: 'fix',
  depends: [serialize_trg, api_base_trg]
)
