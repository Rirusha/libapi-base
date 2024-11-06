valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : deps_pkgs 
  pkgs += '--pkg=' + deps_pkg
endforeach

valadoc_vala_dir = versioned_name + '-vala'
custom_target(
  'valadoc',
  command: [ valadoc ] + pkgs +
  [
    libapi_base_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + versioned_name,
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],
  build_by_default: true,
  input : libapi_base_sources,
  output: valadoc_vala_dir,
  depends: libapi_base,
)

custom_target(
  'cdocs',
  command: [ valadoc ] + pkgs +
  [
    libapi_base_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + versioned_name,
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / versioned_name,
    '--doclet-arg=lib/' + libapi_base_header,
    '--doclet=gtkdoc',
  ],
  build_by_default: true,
  output: versioned_name,
  depends: libapi_base,
)
