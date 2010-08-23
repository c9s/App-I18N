package App::Po::Web::Handler;
use warnings;
use strict;
use base qw(Tatsumaki::Handler);
use Tatsumaki;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Template::Declare;

# sub post {
#     my ($self,$path) = @_;
# #     if( $path eq '/save_item' ) {
# # 
# #     }
#     $self->finish({ success => 1 });
# }

sub get {
    my ( $self, $path ) = @_;
    $path ||= "/";
    $self->write( Template::Declare->show( $path, $self ) );
    $self->finish;
}

1;
