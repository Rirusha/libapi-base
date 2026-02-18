valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : serialize_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

valadoc_vala_dir = serialize_versioned_lib_name + '-vala'
custom_target(
  'valadoc',
  command: [ valadoc ] + pkgs +
  [
    serialize_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + serialize_versioned_lib_name,
    '--package-version=' + libversion,
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],
  build_by_default: true,
  input : serialize_sources,
  output: valadoc_vala_dir,
  depends: serialize_lib,
)
