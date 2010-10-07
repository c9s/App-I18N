package App::I18N;
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
use Locale::Maketext::Extract;
use App::I18N::Logger;
use Cwd;
use Encode;
use MIME::Types ();
use constant USE_GETTEXT_STYLE => 1;

# our @EXPORT = qw(_);

our $VERSION = 0.011;
our $LOGGER;
our $LMExtract;
our $MIME = MIME::Types->new();

sub logger {
    $LOGGER ||= App::I18N::Logger->new;
    return $LOGGER;
}

Locale::Maketext::Lexicon::set_option( 'allow_empty' => 1 );
Locale::Maketext::Lexicon::set_option( 'use_fuzzy'   => 1 );
Locale::Maketext::Lexicon::set_option( 'encoding'    => "UTF-8" );
Locale::Maketext::Lexicon::set_option( 'style'       => 'gettext' );

sub lm_extract {
    return $LMExtract ||= Locale::Maketext::Extract->new(
        plugins => {
            'Locale::Maketext::Extract::Plugin::PPI' => [ 'pm','pl' ],
            'tt2' => [ ],
            # 'perl' => ['pl','pm','js','json'],
            'perl' => [ '*' ],   # _( ) , gettext( ) , loc( ) ...
            'mason' => [ ] ,
            'generic' => [ '*' ],
        },
        verbose => 1, warnings => 1 );
}

sub guess_appname {
    return lc(basename(getcwd()));
}

sub pot_name {
    my $self = shift;
    return guess_appname();
}


sub _check_mime_type {
    my $self       = shift;
    my $local_path = shift;
    my $mimeobj = $MIME->mimeTypeOf($local_path);
    my $mime_type = ($mimeobj ? $mimeobj->type : "unknown");
    return if ( $mime_type =~ /^image/ );
    return if ( $mime_type =~ /compressed/ );  # ignore compressed archive files
    # return if ( $mime_type =~ /^application/ );
    return 1;
}

sub extract_messages {
    my ( $self, @dirs ) = @_;
    my @files  = File::Find::Rule->file->in(@dirs);
    my $logger = $self->logger;
    my $lme = $self->lm_extract;
    foreach my $file (@files) {
        next if $file =~ m{(^|/)[\._]svn/};
        next if $file =~ m{\~$};
        next if $file =~ m{\.pod$};
        next if $file =~ m{^\.git};

        next unless $self->_check_mime_type($file);

        $logger->info("Extracting messages from '$file'");
        $lme->extract_file($file);
    }
}

sub update_catalog {
    my ( $self, $translation , $cmd ) = @_;

    $cmd ||= {};

    my $logger = $self->logger;
    $logger->info( "Updating message catalog '$translation'");

    my $lme = $self->lm_extract;
    $lme->read_po( $translation ) if -f $translation && $translation !~ m/pot$/;

    # Reset previously compiled entries before a new compilation
    $lme->set_compiled_entries;
    $lme->compile(USE_GETTEXT_STYLE);
    $lme->write_po($translation);

    # patch CHARSET
    $logger->info( "Set CHARSET to UTF-8" );
    open my $fh , "<" , $translation;
    my @lines = <$fh>;
    close $fh;

    open my $out_fh , ">" , $translation;
    for my $line ( @lines ) {
        $line =~ s{charset=CHARSET}{charset=UTF-8};
        print $out_fh $line;
    }
    close $out_fh;


    if( $cmd->{mo} ) {
        my $mofile = $translation;
        $mofile =~ s{\.po$}{.mo};
        $logger->info( "Generating MO file: $mofile" );
        system(qq{msgfmt -v $translation -o $mofile});
    }
}

sub guess_podir {
    my ($class,$cmd) = @_;
    my $podir;
    $podir = 'po' if -e 'po';
    $podir = 'locale' , $cmd->{locale} = 1 if -e 'locale';
    $podir ||= 'locale' if $cmd->{locale};
    $podir ||= 'po';
    return $podir;
}


sub update_catalogs {
    my ($self,$podir , $cmd ) = @_;
    my @catalogs = grep !m{(^|/)(?:\.svn|\.git)/}, 
                File::Find::Rule->file
                        ->name('*.po')->in( $podir);

    my $logger = App::I18N->logger;
    unless ( @catalogs ) {
        $logger->error("You have no existing message catalogs.");
        $logger->error("Run `po lang <lang>` to create a new one.");
        $logger->error("Read `po help` to get more info.");
        return 
    }

    foreach my $catalog (@catalogs) {
        $self->update_catalog( $catalog , $cmd );
    }
}


1;
