package App::Po::Web::View;
use warnings;
use strict;
use base qw(Template::Declare);
use Template::Declare::Tags;


# XXX: take this out.
*_ = sub { return @_; };

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


    style { attr { type is 'text/css' }

        outs_raw <<'END';

input { 
    font-size: 22px;
    padding: 3px;
}

input:focus {  background: #ddd; }

END

    };

};

template '/' => page {
    my ($class,$handler) = @_;

    h1 { "App::Po Web Server is running!" };

    # load all po msgid and msgstr
    form { { method is 'post' }

        div { { class is 'msg-item' }

            div { { class is 'msgid' }

                input { { type is 'text' } }; 

            }

            div { { class is 'msgstr' }

                input { { type is 'text' } }; 

            }
        }

        input { { type is 'submit' , value is _("Write All") } };
    };

};

1;
