test('Test Jsoner',
  executable('jsoner-test',
    sources: ['jsoner-test.vala'] + sources,
    dependencies: dependencies,
  )
)

if get_option('run_net_tests')
  test('Test SoupWrapper',
    executable('soup-wrapper-test',
      sources: ['soup-wrapper-test.vala'] + sources,
      dependencies: dependencies,
    )
  )
endif
