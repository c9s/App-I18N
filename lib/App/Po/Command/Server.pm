package App::Po::Command::Server;
use warnings;
use strict;
use base qw(App::Po::Command);
use App::Po::Web::View;
use Tatsumaki::Application;
use Plack::Runner;
use File::Basename;

sub options {
    (

    )
}

sub run {
    my ($self) = @_;

    print "Init Template Declare View: App::Po::Web::View ...\n";
    Template::Declare->init( dispatch_to => ['App::Po::Web::View'] );

    print "Init Tatsumaki::Application ...\n";
    my $app = Tatsumaki::Application->new([
        "(.*)" => "RootHandler"
    ]);
    $app->template_path(dirname(__FILE__) . "/templates");
    $app->static_path(dirname(__FILE__) . "/static");

    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run($app->psgi_app);
}

package RootHandler;
use base qw(Tatsumaki::Handler);
use Tatsumaki;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Template::Declare;

sub post {
    my ($self,$path) = @_;


    $self->finish({ success => 1 });
}

sub get {
    my ( $self, $path ) = @_;
    $path ||= "/";
    $self->write( Template::Declare->show( $path, $self ) );
    $self->finish;
}

1;
