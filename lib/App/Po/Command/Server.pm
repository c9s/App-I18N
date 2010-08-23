package App::Po::Command::Server;
use warnings;
use strict;
use base qw(App::Po::Command);
use App::Po::Web::View;
use App::Po::Web::Handler;
use Tatsumaki::Application;
use Plack::Runner;
use File::Basename;
use File::ShareDir qw();
use File::Path qw(mkpath);

sub options { (
    'l|lang=s' => 'language',
    'f|file=s' => 'pofile',
    'dir=s@'   => 'directories',
    'podir=s'  => 'podir',
    ) }



sub run {
    my ($self) = @_;
    my $podir = $self->{podir} || 'po';
    my @dirs = @{ $self->{directories} || []  };

    Template::Declare->init( dispatch_to => ['App::Po::Web::View'] );

    my $lme = App::Po->lm_extract;

    if( @dirs ) {
        App::Po->extract_messages( @dirs );
        mkpath [ $podir ];
        App::Po->update_catalog( 
                File::Spec->catfile( $podir, 
                    App::Po->pot_name . ".pot") );

        if ( $self->{language} ) {
            App::Po->update_catalog( 
                    File::Spec->catfile( $podir, $self->{'language'} . ".po") );
        }
        else {
            App::Po->update_catalogs( $podir );
        }
    }

    my $translation;
    if( $self->{pofile} ) {
        $translation = $self->{pofile};
    }
    elsif ($self->{language} ) {
        $translation = File::Spec->catfile( $podir, $self->{language} . ".po");
    }
    else {
        die;
    }

#     $lme->read_po( $translation ) if -f $translation && $translation !~ m/pot$/;
#     $lme->set_compiled_entries;
#     $lme->compile(USE_GETTEXT_STYLE);
#     $lme->write_po($translation);

    use App::Po::Web;
    my $app = App::Po::Web->new([
        "(/.*)" => "App::Po::Web::Handler"
    ]);

    my $shareroot = 
        ( -e "./share" ) 
            ? 'share' 
            : File::ShareDir::dist_dir( "App-Po" );

    print "Share root: $shareroot\n";

    $app->webpo({
        language  => $self->{language},
        pofile    => $self->{pofile},
        shareroot => $shareroot,
    });

    $app->template_path( $shareroot . "/templates" );
    $app->static_path( $shareroot . "/static" );

    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run($app->psgi_app);
}

1;
