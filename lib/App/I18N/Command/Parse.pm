package App::I18N::Command::Parse;
use warnings;
use strict;
use Cwd;
use App::I18N::Config;
use App::I18N::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use Locale::Maketext::Extract;
use base qw(App::I18N::Command);

sub options {
    (
    'q|quiet'  => 'quiet',
    'l|lang=s' => 'language',
    'locale'   => 'locale',   # XXX: use locale directory structure
    'podir=s'  => 'podir',
    'g|gettext' => 'gettext',  # XXX: should just be locale option and merge the 'mo' option
    'mo'       => 'mo',
    'js'       => 'js',
    );
}

our $LMExtract = App::I18N->lm_extract();


sub print_help_message {
    print <<END

In your application include the code below:

    use App::I18N::I18N;

    sub hello {
        print _( "Hello %1" , \$world );
    }

END
}

sub run {
    my ($self,@args) = @_;
    my $podir = $self->{podir};

    $self->{mo} = $self->{locale} = 1 if $self->{gettext};
    unless( $podir ) {
        $podir = 'po' if -e 'po';
        $podir = 'locale' if -e 'locale' && $self->{locale};
        $podir ||= 'po';
    }

    my @dirs = @args;
    App::I18N->extract_messages( @dirs );

    # update app.pot catalog
    mkpath [ $podir ];

    my $pot_name = App::I18N->pot_name;
    App::I18N->update_catalog( File::Spec->catfile( $podir, $pot_name . ".pot") );

    if ( $self->{'language'} ) {
        # locale structure
        #    locale/{lang}/LC_MESSAGES/{domain}.po
        #    {podir}/{lang}/LC_MESSAGES/{pot_name}.po
        if( $self->{locale} ) {
            mkpath [ File::Spec->join(  $podir , $self->{language}  , "LC_MESSAGES" )  ];

            my $pofile =  File::Spec->catfile( $podir, $self->{'language'} , "LC_MESSAGES" , $pot_name . ".po");
            App::I18N->update_catalog( $pofile , $self );
        }
        else {
            App::I18N->update_catalog( File::Spec->catfile( $podir, $self->{'language'} . ".po") , $self );
        }
        return;
    }
    App::I18N->update_catalogs( $podir , $self );

    print_help_message();
}

1;
__END__

_("Check existing po files")
_("Test %1", 1234 )
