package App::Po::Command::Server;
use warnings;
use strict;
use base qw(App::Po::Command);
use App::Po::Web;
use App::Po::Web::View;
use App::Po::Web::Handler;
use Tatsumaki::Application;
use Plack::Runner;
use File::Basename;
use File::ShareDir qw();
use File::Path qw(mkpath);


use constant debug => 1;

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


    # pre-process messages
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


    # init po database in memory
    my $db;
    eval {
        require App::Po::DB;
    };
    if( $@ ) {

    }
    $db = App::Po::DB->new( lang => 'zh-tw' );
    # $db->insert( 'test' , '測試' );




    $SIG{INT} = sub {
        # XXX: write sqlite data to po file here.
        $db->write_to_pofile(  );
        exit;
    };



#     $lme->read_po( $translation ) if -f $translation && $translation !~ m/pot$/;
#     $lme->set_compiled_entries;
#     $lme->compile(USE_GETTEXT_STYLE);
#     $lme->write_po($translation);

    Template::Declare->init( dispatch_to => ['App::Po::Web::View'] );

    my $app = App::Po::Web->new([
        "(/.*)" => "App::Po::Web::Handler"
    ]);

    my $shareroot = 
        ( -e "./share" ) 
            ? 'share' 
            : File::ShareDir::dist_dir( "App-Po" );

    print "Share root: $shareroot\n" if debug;

    $app->webpo({
        podir     => $podir,
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
