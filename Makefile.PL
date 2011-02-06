use inc::Module::Install;
all_from 'lib/App/commandlinefu.pm';
readme_markdown_from('lib/App/commandlinefu.pm');
build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;
