use inc::Module::Install;

name      'Combust';
license   'apache';
all_from  'lib/Combust.pm';
resources  repository  => 'http://github.com/abh/combust';

requires  'Config::Simple';
requires  'DBI';
requires  'Cache::Memcached' => '1.27';
requires  'JSON::XS' => '2.29';
requires  'Template';
requires  'Pod::Simple';
requires  'Class::Accessor::Class';
requires  'Digest::SHA1';
requires  'URI::Escape';
requires  'HTML::Entities';
requires  'Sub::Install';
requires  'namespace::clean';

requires  'Authen::Bitcard';

# for mod_perl only ...
requires   'Apache::DBI';
requires   'Apache::Reload';

test_requires 'Data::Dumper';
test_requires 'Test::More' => '0.88';
test_requires 'HTML::TagCloud';
test_requires 'Template::Plugin::Number::Format';

tests_recursive;

#recommends     'Text::CSV_XS'=> '0.50';
#no_index       'directory'   => 'demos';

#install_script 'myscript';

  
postamble("

.PHONY: testcover

cover:
\tcover -delete
\tHARNESS_PERL_SWITCHES=-MDevel::Cover make test
\tcover

");

WriteAll;

