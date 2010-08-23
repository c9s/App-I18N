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
use Locale::Maketext::Extract;
use App::Po::Logger;
use Cwd;
use Encode;
use MIME::Types ();

use constant USE_GETTEXT_STYLE => 1;

# our @EXPORT = qw(_);

our $VERSION = 0.001;
our $LOGGER;
our $LMExtract;
our $MIME = MIME::Types->new();

sub logger {
    $LOGGER ||= App::Po::Logger->new;
    return $LOGGER;
}

Locale::Maketext::Lexicon::set_option( 'allow_empty' => 1 );
Locale::Maketext::Lexicon::set_option( 'use_fuzzy'   => 1 );
Locale::Maketext::Lexicon::set_option( 'encoding'    => "UTF-8" );
Locale::Maketext::Lexicon::set_option( 'style'       => 'gettext' );

sub lm_extract {
    return $LMExtract ||= Locale::Maketext::Extract->new(
        plugins => {
            'Locale::Maketext::Extract::Plugin::PPI' => ['pm','pl'],
            'tt2' => [ ],
            'perl' => ['pl','pm','js','json'],
            'mason' => [ ] ,
        },
        verbose => 1,
        warnings => 1,
    );
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
        next unless $self->_check_mime_type($file);

        $logger->info("Extracting messages from '$file'");
        $lme->extract_file($file);
    }
}

sub update_catalog {
    my ( $self, $translation ) = @_;

    my $logger = $self->logger;
    $logger->info( "Updating message catalog '$translation'");


    my $lme = $self->lm_extract;
    $lme->read_po( $translation ) if -f $translation && $translation !~ m/pot$/;

    my $orig_lexicon;

    # Reset previously compiled entries before a new compilation
    $lme->set_compiled_entries;
    $lme->compile(USE_GETTEXT_STYLE);
    $lme->write_po($translation);
}

sub update_catalogs {
    my ($self,$podir) = @_;
    my @catalogs = grep !m{(^|/)(?:\.svn|\.git)/}, 
                File::Find::Rule->file
                        ->name('*.po')->in( $podir);

    my $logger = App::Po->logger;
    unless ( @catalogs ) {
        $logger->error("You have no existing message catalogs.");
        $logger->error("Run `po lang <lang>` to create a new one.");
        $logger->error("Read `po help` to get more info.");
        return 
    }

    foreach my $catalog (@catalogs) {
        $self->update_catalog( $catalog );
    }
}


sub read_po_file {
    my ($self,$path) = @_;
    open my $fh , "<" , $path or die( "can not open po file: $path\n" );
    my $lexs = $self->read_po( $fh);
    close $fh;
    return $lexs;
}


# XXX: remove this
# should pass a handle to this.
sub read_po {
    my ( $self, $fh ) = @_;
    use Locale::Maketext::Lexicon::Gettext;

    my %Lexicon;

    %Lexicon = %{ Locale::Maketext::Lexicon::Gettext->parse(<$fh>) };
    map { delete $Lexicon{$_} if /^__/ }   keys %Lexicon;
    map { Encode::_utf8_on($Lexicon{$_}) } keys %Lexicon;
    return \%Lexicon;
}


1;
