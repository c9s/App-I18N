package App::Po;
use strict;
use warnings;
use Carp;
use File::Copy;
use File::Find::Rule;
use File::Path qw/mkpath/;
use Locale::Maketext::Extract;
use Getopt::Long;
use Exporter 'import';
use JSON::XS;
use YAML::XS;
use File::Basename;
use App::Po::Logger;
use Cwd;

# our @EXPORT = qw(_);

our $VERSION = 0.001;
our $LOGGER;
our $LMExtract;

sub logger {
    $LOGGER ||= App::Po::Logger->new;
    return $LOGGER;
}

sub lm_extract {
    return $LMExtract ||= Locale::Maketext::Extract->new(
        # Specify which parser plugins to use
        plugins => {
            # Use Perl parser, process files with extension .pl .pm .cgi
            'Locale::Maketext::Extract::Plugin::PPI' => ['pm','pl'],
            'tt2' => [ ],
            'perl' => ['pl','pm','js','json'],
            'mason' => [ ] ,
        },
        verbose => 1,
        warnings => 1,
    );
}








1;
