use inc::Module::Install;

all_from 'lib/App/commandlinefu.pm';
readme_markdown_from('lib/App/commandlinefu.pm');

requires 'Furl' => 0.21;
requires 'Mouse';
requires 'MouseX::Getopt';
requires 'JSON::XS';
requires 'MIME::Base64';
requires 'URI::Escape';
requires 'Term::ANSIColor';

test_requires 'Test::More', 0.88;
test_requires 'Test::Requires';

auto_set_repository();
WriteAll;
