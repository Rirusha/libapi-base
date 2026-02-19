test('Test Jsoner',
  executable('jsoner-test',
    sources: ['jsoner-test.vala'],
    dependencies: [serialize_dependencies, serialize_lib_dep],
  )
)

if get_option('run_net_tests')
  test('Test SoupWrapper',
    executable('session-test',
      sources: ['session-test.vala'],
      dependencies: [api_base_dependencies, api_base_lib_dep],
    ),
    is_parallel: true,
    timeout: 9000
  )
endif
