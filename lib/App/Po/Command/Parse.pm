package App::Po::Command::Parse;
use warnings;
use strict;
use Cwd;
use App::Po::Config;
use App::Po::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use base qw(App::Po::Command);

use constant USE_GETTEXT_STYLE => 1;

sub options {
    (
        'q|quiet' => 'quiet',
        'podir=s' => 'podir',
        'js'      => 'js',
    );
}

our $LMExtract = Locale::Maketext::Extract->new(
        # Specify which parser plugins to use
        plugins => {
            # Use Perl parser, process files with extension .pl .pm .cgi
            'Locale::Maketext::Extract::Plugin::PPI' => ['pm','pl'],
            'tt2' => [ ],
            'perl' => ['pl','pm','js','json'],
            'mason' => [ ] ,
        },
        verbose => 1,
);


sub update_catalog {
    my ( $self, $translation ) = @_;

    my $logger = App::Po->logger;
    $logger->info( "Updating message catalog '$translation'");

    $LMExtract->read_po($translation) if ( -f $translation && $translation !~ m/pot$/ );

    my $orig_lexicon;

    # Reset previously compiled entries before a new compilation
    $LMExtract->set_compiled_entries;
    $LMExtract->compile(USE_GETTEXT_STYLE);
    $LMExtract->write_po($translation);

#     $orig_lexicon = $LMExtract->lexicon;
#     my $lexicon = { %$orig_lexicon };
# 
#     # XXX: cache core_lm
#     my $core_lm = Locale::Maketext::Extract->new();
#     Locale::Maketext::Lexicon::set_option('allow_empty' => 1);
#     # $core_lm->read_po( File::Spec->catfile(  ));
#     # Locale::Maketext::Lexicon::set_option('allow_empty' => 0);
#     # for (keys %{ $core_lm->lexicon }) {
#     #     next unless exists $lexicon->{$_};
#     #     # keep the local entry overriding core if it exists
#     #     delete $lexicon->{$_} unless length $lexicon->{$_};
#     # }
#     $LMExtract->set_lexicon($lexicon);
#     $LMExtract->write_po($translation);
#     $LMExtract->set_lexicon($orig_lexicon);

}

sub guess_appname {
    return lc(basename(getcwd()));
}

sub run {
    my ($self,@args) = @_;
    my $podir = $self->{podir} || 'po';
    my @dirs = @args;

    # try to load application config file
    my $config = App::Po::Config->read;
    if( $config ) {
        my @langs = @{ $config->{I18N}->{langs} };


    }

    # check existing po files


    my @files = File::Find::Rule->file->in( @dirs || ( 'lib', 'bin' ) );
    my $logger = App::Po->logger;
    foreach my $file (@files) {
        next if $file =~ m{(^|/)[\._]svn/};
        next if $file =~ m{\~$};
        next if $file =~ m{\.pod$};
        next unless $self->_check_mime_type($file);

        $logger->info("Extracting messages from '$file'");
        $LMExtract->extract_file($file);
    }

    mkpath [ $podir ];
    $self->update_catalog( File::Spec->catfile( $podir , "app.pot" ) );
}


1;
