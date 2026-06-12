resource_files = files('test-data.gresource.xml')
resources = gnome.compile_resources(
  'test-data-resources',
  resource_files,
  c_name: 'test_data'
)

test_vala_args = [
  '--vapidir', local_vapi_dir,
]

test('json',
  executable('jsoner-test',
    sources: ['jsoner-test.vala', resources],
    dependencies: [serialize_dependencies, serialize_lib_dep],
    vala_args: test_vala_args,
  ),
)

test('ini',
  executable('ini-test',
    sources: ['ini-test.vala', resources],
    dependencies: [serialize_dependencies, serialize_lib_dep],
    vala_args: test_vala_args,
  ),
  env: [
    'SERIALIZE_UNKNOWN_PROPS=1',
    'SERIALIZE_UNKNOWN_FIELDS=1',
  ],
)

test('yaml',
  executable('yaml-test',
    sources: ['yaml-test.vala', resources],
    dependencies: [serialize_dependencies, serialize_lib_dep],
    vala_args: test_vala_args,
  ),
)

test('session',
  executable('session-test',
    sources: ['session-test.vala'],
    dependencies: [api_base_dependencies, api_base_lib_dep],
    vala_args: test_vala_args,
  ),
  is_parallel: true,
  timeout: 9000
)
