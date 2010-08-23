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
        'dir=s@'   => 'directories',
        'podir=s'  => 'podir',
        ) }

sub run {
    my ($self) = @_;
    my $podir = $self->{podir} || 'po';
    my @dirs = @{ $self->{directories} || "lib" };

    Template::Declare->init( dispatch_to => ['App::Po::Web::View'] );

#     App::Po->extract_messages( @dirs );
# 
#     # update app.pot catalog
#     mkpath [ $podir ];
# 
#     App::Po->update_catalog( 
#             File::Spec->catfile( $podir, 
#                 App::Po->pot_name . ".pot") );

    my $translation = File::Spec->catfile( $podir, $self->{language} . ".po");
    my $lme = App::Po->lm_extract;
    $lme->read_po( $translation ) if -f $translation && $translation !~ m/pot$/;
    my $orig_lexicon;
    $lme->set_compiled_entries;
    $lme->compile(USE_GETTEXT_STYLE);
    $orig_lexicon = $lme->lexicon;


    # $lme->write_po($translation);
#     if ( $self->{'language'} ) {
#         App::Po->update_catalog( File::Spec->catfile(
#             $podir, 
#             $self->{language} . ".po"
#         ) );
#         return;
#     }
#     App::Po->update_catalogs( $podir );

    $App::Po::Web::View::CURRENT_LANG = $self->{language} || "en";

    my $app = Tatsumaki::Application->new([
        "(/.*)" => "App::Po::Web::Handler"
    ]);

    my $shareroot;
    if( -e "./share" ) {
        $shareroot = 'share' ;
    }
    else {
        $shareroot = File::ShareDir::dist_dir( "App-Po" );
    }

    print "using share root: $shareroot\n";

    $app->template_path( $shareroot . "/templates" );
    $app->static_path( $shareroot . "/static" );

    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run($app->psgi_app);
}

1;
