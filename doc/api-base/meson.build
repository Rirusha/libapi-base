valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : api_base_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

valadoc_vala_dir = api_base_versioned_lib_name + '-vala'
custom_target(
  'valadoc',
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
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],
  build_by_default: true,
  input : api_base_sources,
  output: valadoc_vala_dir,
  depends: [api_base_lib, serialize_lib]
)
