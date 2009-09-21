use inc::Module::Install;

name      'Combust';
license   'apache';
all_from  'lib/Combust.pm';
resources  repository  => 'http://github.com/abh/combust';

requires  'Config::Simple';
requires  'DBI';
requires  'Cache::Memcached';
requires  'JSON::XS';
requires  'Template';
requires  'Pod::Simple';
requires  'Class::Accessor::Class';
requires  'Digest::SHA1';
requires  'URI::Escape';
requires  'HTML::Entities';
requires  'Sub::Install';


test_requires 'Data::Dumper';
test_requires 'Test::More' => '0.88';
test_requires 'HTML::TagCloud';

#requires       'File::Spec'  => '0.80';
#test_requires  'Test::More'  => '0.42';
#recommends     'Text::CSV_XS'=> '0.50';
#no_index       'directory'   => 'demos';

#install_script 'myscript';
  
WriteAll;

