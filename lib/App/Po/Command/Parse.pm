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

sub options {
    (
    'q|quiet'  => 'quiet',
    'l|lang=s' => 'language',
    'locale'   => 'locale',   # XXX: use locale directory structure
    'podir=s'  => 'podir',
    'mo'       => 'mo',
    'js'       => 'js',
    );
}

our $LMExtract = App::Po->lm_extract();


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

    App::Po->extract_messages( @dirs );

    # update app.pot catalog
    mkpath [ $podir ];

    my $pot_name = App::Po->pot_name;
    App::Po->update_catalog( File::Spec->catfile( $podir, $pot_name . ".pot") );

    if ( $self->{'language'} ) {
        # locale structure
        #    locale/{lang}/LC_MESSAGES/{domain}.po
        #    {podir}/{lang}/LC_MESSAGES/{pot_name}.po
        if( $self->{locale} ) {
            mkpath [ File::Spec->join(  $podir , $self->{language}  , "LC_MESSAGES" )  ];

            my $pofile =  File::Spec->catfile( $podir, $self->{'language'} , "LC_MESSAGES" , $pot_name . ".po");
            App::Po->update_catalog( $pofile , $self );
        }
        else {
            App::Po->update_catalog( File::Spec->catfile( $podir, $self->{'language'} . ".po") , $self );
        }
        return;
    }
    App::Po->update_catalogs( $podir , $self );

    print_help_message();
}

1;
__END__

_("Check existing po files")
_("Test %1", 1234 )
