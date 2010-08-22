package App::Po::Web::View;
use warnings;
use strict;
use base qw(Template::Declare);
use Template::Declare::Tags;

sub page (&) {
    my ($ref) = shift;
    return sub {
        my ($class,$handler) = @_;
        html {
            head {


            }

            body {

                $ref->( $class, $handler );

            }

        };
    }
}

template '/' => page {
    my ($class,$handler) = @_;

    h1 { "App::Po Web Server is running!" };





};


1;
