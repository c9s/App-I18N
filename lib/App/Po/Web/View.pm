package App::Po::Web::View;
use warnings;
use strict;
use base qw(Template::Declare);
use Template::Declare::Tags;

our $CURRENT_LANG;

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

template '/' => page {

    my ($class,$handler) = @_;

    h1 { "Po Web Server: " . $CURRENT_LANG };

    my $lang = $CURRENT_LANG;
    my $LME = App::Po->lm_extract();

    $LME->read_po( "po/$lang.po" );

    $LME->set_compiled_entries;
    $LME->compile(1);

    # $LME->write_po($translation);

    my $orig_lexicon = $LME->lexicon;
    use Data::Dumper; warn Dumper( $orig_lexicon );


#     my @files = File::Find::Rule->file->in( qw(lib) );
#     foreach my $file (@files) {
#         next if $file =~ m{(^|/)[\._]svn/};
#         next if $file =~ m{\~$};
#         next if $file =~ m{\.pod$};
#         $LMExtract->extract_file($file);
#     }

    my $pofile = "po/en.po";
    my $lex = App::Po->read_po_file( $pofile );


    # load all po msgid and msgstr
    form { { method is 'post' }

        div {
            outs "Editing po file: " . $pofile;
        }

        input { { type is 'hidden',  name is 'pofile' , value is $pofile } };

        div { { class is 'msgitem' }
            div { { class is 'msgid column-header' } _("MsgID") }
            div { { class is 'msgstr column-header' } _("MsgStr") }
        };


        # XXX: a better way to read po file ? not to parse every time.
        while( my ($msgid,$msgstr) = each %$lex ) {

            div { { class is 'msgitem' }
                div { { class is 'msgid' }
                    textarea {  { name is 'msgid[]' };
                        outs $msgid;
                    };
                }

                div { { class is 'msgstr' }
                    textarea {  { name is 'msgstr[]' };
                        outs $msgstr;
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

1;
