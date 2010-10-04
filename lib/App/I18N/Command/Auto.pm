package App::I18N::Command::Auto;
use warnings;
use strict;
use Encode;
use Cwd;
use App::I18N::Config;
use App::I18N::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use REST::Google::Translate;
use base qw(App::I18N::Command);


=head1 DESCRIPTION


--from 

--to

--backend

--locale

-s

--overwrite

--msgstr

--verbose

=cut


sub options {
    ( 
        'f|from=s' => 'from',
        't|to=s'   => 'to',
        'backend=s' => 'backend',
        'locale'  => 'locale',
        'verbose' => 'verbose',
        'msgstr' => 'from_msgstr',   # translate from existing msgstr instead of translating from msgid.
        'overwrite' => 'overwrite',  # overwrite existing msgstr
        's'         => 'skip_existing'
    )
}

sub run {
    my ( $self ) = shift;
    my $logger = $self->logger();


    # XXX: check this option
    $self->{backend} ||= 'rest-google';


    $self->{mo} = 1 if $self->{locale};
    my $podir = $self->{podir};
    $podir = App::I18N->guess_podir( $self ) unless $podir;

    mkpath [ $podir ];

    my $pot_name = App::I18N->pot_name;
    my $potfile = File::Spec->catfile( $podir, $pot_name . ".pot") ;
    if( ! -e $potfile ) {
        $logger->info( "$potfile not found." );
        return;
    }

    my $from_lang = $self->{from};
    my $to_lang   = $self->{to};
    my $from_pofile;
    my $to_pofile;

    if( $self->{locale} ) {
        mkpath [ File::Spec->join( $podir , $from_lang , 'LC_MESSAGES' )  ];
        $from_pofile = File::Spec->join( $podir , $from_lang , 'LC_MESSAGES' , $pot_name . ".po" );

        mkpath [ File::Spec->join( $podir , $to_lang , 'LC_MESSAGES' )  ];
        $to_pofile = File::Spec->join( $podir , $to_lang , 'LC_MESSAGES' , $pot_name . ".po" );
    }
    else {
        $from_pofile = File::Spec->join( $podir , $from_lang . ".po" );

        $to_pofile = File::Spec->join( $podir , $to_lang . ".po" );
    }

    my $ext = Locale::Maketext::Extract->new;

    $logger->info( "Reading po file: $from_pofile" ) if $self->{verbose};
    $ext->read_po($from_pofile);


    my $from_lang_s = $from_lang;
    my $to_lang_s = $to_lang;

    ($from_lang_s) = ( $from_lang  =~ m{^([a-z]+)(_\w+)} );
    ($to_lang_s)   = ( $to_lang    =~ m{^([a-z]+)(_\w+)} );

    REST::Google::Translate->http_referer('http://google.com');

    for my $i ($ext->msgids()) {
        my $msgstr = $ext->msgstr( $i );

        next if $msgstr && $self->{skip_existing};

        $i = $msgstr if $msgstr && $self->{msgstr};

        $logger->info( "Translating: [ $i ]" ) if $self->{verbose};
        $logger->info( encode_utf8("  Original translation: [ $msgstr ]") ) if $msgstr;

        my $retry = 1;
        while($retry--) {
            eval {
                my $res = REST::Google::Translate->new(
                            q => $i,
                            langpair => $from_lang_s . '|' . $to_lang_s );

                if ($res->responseStatus == 200) {
                    my $translated = $res->responseData->translatedText;
                    if( ($msgstr && $self->{overwrite}) 
                            || ! $msgstr ) {
                        if( $msgstr ) {
                            $logger->info( encode_utf8("  Translation overwrited: [$i] => [$translated]") );
                        } else {
                            $logger->info( encode_utf8("  Translation: [$i] => [$translated]" ) );
                        }
                        $ext->set_msgstr($i, encode_utf8( $translated ) );
                    }
                }
                else {
                    $ext->set_msgstr($i, undef) if $self->{overwrite};
                }

            };
            if( $@ ) {
                # XXX: let it retry for 3 times
                $retry = 2;
                $logger->error( "REST API ERROR: $@ , $!" );
                $logger->info( "Retrying ..." );
            }
        }
    }

    $logger->info( "Writing po file to $to_pofile" );
    $ext->write_po($to_pofile);

    if( $self->{mo} ) {
        my $mofile = $to_pofile;
        $mofile =~ s{\.po$}{.mo};
        $logger->info( "Updating MO file: $mofile" );
        system(qq{msgfmt -v $to_pofile -o $mofile});
    }

    $logger->info( "Done" );
}




1;
