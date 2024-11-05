test('Test Jsoner',
  executable('jsoner-test',
    sources: ['jsoner-test.vala'] + libapi_base_sources,
    dependencies: libapi_base_dependencies,
  )
)

if get_option('run_net_tests')
  test('Test SoupWrapper',
    executable('soup-wrapper-test',
      sources: ['soup-wrapper-test.vala'] + libapi_base_sources,
      dependencies: libapi_base_dependencies,
    )
  )
endif
