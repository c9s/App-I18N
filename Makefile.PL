use inc::Module::Install;

name     'App-Po';
all_from 'lib/App/Po.pm';
author   q{Cornelius <cornelius.howl@gmail.com> freehaha};
license  'perl';

build_requires 'Test::More';

# requires 'JSON';
# requires 'JSON::XS';
# requires 'File::Temp';
requires 'LWP::Simple';
requires 'Exporter::Lite';

install_script 'bin/po';

# author_tests('xt');

auto_install;

WriteAll;
