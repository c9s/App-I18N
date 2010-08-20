use inc::Module::Install;

name     'App-Po';
all_from 'lib/App/Po.pm';
author   q{Cornelius <cornelius.howl@gmail.com> freehaha};
license  'perl';

build_requires 'Test::More';

requires 'LWP::Simple';
requires 'Exporter::Lite';
requires 'File::Copy';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'Locale::Maketext::Extract';
requires 'Getopt::Long';
requires 'Exporter';
requires 'JSON::XS';

install_script 'bin/po';

# author_tests('xt');

auto_install;

WriteAll;
