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
requires 'Locale::Maketext::Lexicon';
requires 'Getopt::Long';
requires 'Exporter';
requires 'JSON::XS';
requires 'Tatsumaki';
requires 'Plack';
requires 'File::ShareDir';

install_script 'bin/po';

# author_tests('xt');


no_index( directory => qw< share > );
install_share;

auto_install;

WriteAll;
