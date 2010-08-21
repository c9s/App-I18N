package App::Po::Command::Parse;
use warnings;
use strict;
use Cwd;
use App::Po::Config;
use App::Po::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use Locale::Maketext::Extract;
use base qw(App::Po::Command);

use constant USE_GETTEXT_STYLE => 1;

sub options {
    (
    'q|quiet'  => 'quiet',
    'l|lang=s' => 'language',
    'podir=s'  => 'podir',
    'js'       => 'js',
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
        warnings => 1,
);

use MIME::Types ();
our $MIME = MIME::Types->new();

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
    my ($self,@dirs) = @_;
    my @files = File::Find::Rule->file->in( @dirs );
    my $logger = App::Po->logger;
    foreach my $file (@files) {
        next if $file =~ m{(^|/)[\._]svn/};
        next if $file =~ m{\~$};
        next if $file =~ m{\.pod$};
        next unless $self->_check_mime_type($file);

        $logger->info("Extracting messages from '$file'");
        $LMExtract->extract_file($file);
    }
}

sub print_help_message {
    print <<END

In your application include the code below:

    use App::Po::I18N;

    sub hello {
        print _( "Hello %1" , \$world );
    }

END
}

sub run {
    my ($self,@args) = @_;
    my $podir = $self->{podir} || 'po';
    my @dirs = @args;

    my $logger = App::Po->logger;
    $self->extract_messages( @dirs );

    # update app.pot catalog
    mkpath [ $podir ];


    $self->update_catalog( File::Spec->catfile( $podir, $self->pot_name . ".pot") );
    if ( $self->{'language'} ) {
        $self->update_catalog( File::Spec->catfile(
            $podir, $self->{'language'} . ".po"
        ) );
        return;
    }
    $self->update_catalogs( $podir );

    print_help_message();
}

1;
__END__

_("Check existing po files")
_("Test %1", 1234 )

