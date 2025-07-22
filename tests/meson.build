test('Test Jsoner',
  executable('jsoner-test',
    sources: ['jsoner-test.vala'] + sources,
    dependencies: dependencies,
  )
)

if get_option('run_net_tests')
  test('Test SoupWrapper',
    executable('session-test',
      sources: ['session-test.vala'] + sources,
      dependencies: dependencies,
    ),
    is_parallel: true,
    timeout: 9000
  )
endif
