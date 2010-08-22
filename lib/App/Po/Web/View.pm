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

                show 'head', $class, $handler;

            }

            body {

                $ref->( $class, $handler );

            }

        };
    }
}

# move to template helpers
sub js { 
    my $file = shift;
    outs_raw qq|<script type="text/javascript" src="$file"></script>\n|;
}

sub css {
    my $file = shift;
    outs_raw qq|<style type="text/css" src="$file"></style>\n|;
} 

template 'head' => sub {
    my ( $class, $handler ) = @_;

    # js "blah.js";
    # css "blah.js";

};

template '/' => page {
    my ($class,$handler) = @_;

    h1 { "App::Po Web Server is running!" };

    # load all po msgid and msgstr

};

1;
