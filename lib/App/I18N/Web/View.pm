package App::I18N::Web::View;
use warnings;
use strict;
use base qw(Template::Declare);
use Template::Declare::Tags;
use utf8;
use Encode;

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
    outs_raw qq|<script type="text/javascript" src="$_"></script>\n| for @_;
}

sub css {
    outs_raw qq|<link href="$_" media="screen" rel="stylesheet" type="text/css" />| for @_;
} 

template 'head' => sub {
    my ( $class, $handler ) = @_;

    outs_raw qq|<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">\n|;


    js qw(
        /static/jquery-1.4.2.js
        /static/jquery.jgrowl.js
        /static/app.js
    );
    css qw(
        /static/app.css
        /static/jquery.jgrowl.css
    );
};


template 'edit_po' => sub {
    my ( $self, $handler, $translation ) = @_;
    my $po_opts = $handler->application->options;
    my $podir   = $po_opts->{podir};
    unless( $translation ) {
        $translation = File::Spec->catfile( $podir , $handler->request->param( 'lang' ) . ".po" );
    }

    my $logger = App::I18N->logger();

    unless( -f $translation ) {
        $logger->info( "$translation doesnt exist." );
    }


    my $LME = App::I18N->lm_extract();
    $LME->read_po( $translation ) if -f $translation;

    my $lex = $LME->lexicon;

    h3 { "Po Web Server: " . $translation };


    # load all po msgid and msgstr
    form { { method is 'post' }

        div {
            outs "Editing po file: " . $translation;
        }

        input { { type is 'hidden',  name is 'pofile' , value is $translation } };

        div { { class is 'msgitem' }
            div { { class is 'msgid column-header' } _("MsgID") }
            div { { class is 'msgstr column-header' } _("MsgStr") }
        };


        # XXX: a better way to read po file ? not to parse every time.
        while( my ($msgid,$msgstr) = each %$lex ) {

            div { { class is 'msgitem' }
                div { { class is 'msgid' }
                    textarea {  { name is 'msgid[]' };
                        outs decode_utf8 $msgid;
                    };
                }

                div { { class is 'msgstr' }
                    textarea {  { name is 'msgstr[]' };
                        outs decode_utf8 $msgstr;
                    };
                }

#                 div { { class is 'savethis' }
#                     input { { type is 'button' , value is _("Save This") } };
#                 };
            }


        }


        div { { class is 'clear' } };
        div { { style is 'width: 80%; text-align:right;' };
            input { { 
                type is 'submit' , 
                value is _("Write All") ,
                onclick is qq|return writeAll(this);|
                } };
        }
    };



};

template '/' => page {
    my ( $class, $handler ) = @_;

    my $po_opts = $handler->application->webpo;
    my $podir   = $po_opts->{podir};


    h1 {  "App::I18N Server" }

    my $translation = 
        ( $po_opts->{pofile} )
            ? $po_opts->{pofile}
            : $po_opts->{language}
                ? File::Spec->catfile( $podir, $po_opts->{language} . ".po")
                : undef;

    if( $translation ) {
        show 'edit_po', $handler, $translation;
    }
    else {
        # list language
        use File::Find::Rule;
        my @files  = File::Find::Rule->file()->name( "*.po" )->in( $podir );
        foreach my $file (@files) {
            my ($langname) = ( $file =~ m{([a-zA-Z-_]+)\.po$}i );
            input { attr { type is 'button', value is $file , onclick is qq|
                    return (function(e){  
                        jQuery.ajax({
                            url: '/edit_po',
                            data: { lang: "$langname" },
                            dataType: 'html',
                            type: 'get',
                            success: function(html) {
                                jQuery('#panel').html( html );
                            }
                        });
            })(this);| } };
        }

        div { { id is 'panel' };




        };
    }


};

1;
