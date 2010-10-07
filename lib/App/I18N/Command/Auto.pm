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

auto - auto translate po files.

=head1 OPTIONS

    --from [lang]
    --to [lang]
    --backend [backend]
    --locale
    --prompt 
    --overwrite
    --msgstr
    --verbose

Translate zh_CN.po from en_US to zh_TW

    po auto zh_CN --from en_US --to zh_TW

    po auto zh_CN --from en_US --overwrite --prompt

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
        'p|prompt'    => 'prompt',
    )
}



sub prompt {
    print STDERR "Apply This ? (Y/n)";
    my $ans = <STDIN>;
    chomp($ans);
    $ans ||= "Y";
    return $ans;
}


sub run {
    my ( $self , $lang ) = @_;
    my $logger = $self->logger();

    # XXX: check this option
    $self->{backend} ||= 'rest-google';

    my $podir = $self->{podir};
    $podir = App::I18N->guess_podir( $self ) unless $podir;
    $self->{mo} = 1 if $self->{locale};

    mkpath [ $podir ];

    my $pot_name = App::I18N->pot_name;
    my $potfile = File::Spec->catfile( $podir, $pot_name . ".pot") ;
    if( ! -e $potfile ) {
        $logger->info( "$potfile not found." );
        return;
    }

    my $from_lang = $self->{from};
    my $to_lang = $self->{to} || $lang;

    my $pofile;
    if( $self->{locale} ) {
        $pofile = File::Spec->join( $podir , $lang , 'LC_MESSAGES' , $pot_name . ".po" );
    }
    else {
        $pofile = File::Spec->join( $podir , $lang . ".po" );
    }

    my $ext = Locale::Maketext::Extract->new;

    $logger->info( "Reading po file: $pofile" );
    $ext->read_po($pofile);

    my $from_lang_s = $from_lang;
    my $to_lang_s = $to_lang;
    ($from_lang_s) = ( $from_lang  =~ m{^([a-z]+)(_\w+)} );
    ($to_lang_s)   = ( $to_lang    =~ m{^([a-z]+)(_\w+)} );

    REST::Google::Translate->http_referer('http://google.com');

NEXT_MSGID:
    for my $i ($ext->msgids()) {
        my $msgstr = $ext->msgstr( $i );

        next if $msgstr && ! $self->{overwrite};

        $i = $msgstr if $msgstr && $self->{msgstr};

        $logger->info( "Translating: [ $i ]" );
        $logger->info( "  Original translation: [ $msgstr ]" ) if $msgstr;

        my $retry = 1;
        while($retry--) {
            my $res;
            eval {
                $res = REST::Google::Translate->new(
                            q => $i,
                            langpair => $from_lang_s . '|' . $to_lang_s );


            };
            if( $@ ) {
                # XXX: let it retry for 3 times
                $retry = 2;
                $logger->error( "REST API ERROR: $@ , $!" );
                $logger->info( "Retrying ..." );
            }

            if ($res->responseStatus == 200) {
                my $translated = $res->responseData->translatedText;
                if( ($msgstr && $self->{overwrite}) 
                        || ! $msgstr ) {
                    if( $msgstr ) {
                        $logger->info( encode_utf8("  Translation overwrited: [$i] => [$translated]") );
                    } else {
                        $logger->info( encode_utf8("  Translation: [$i] => [$translated]" ) );
                    }

                    if( $self->{prompt} ) {
                        my $ans = $self->prompt();
                        next NEXT_MSGID if $ans =~ /n/i;
                    }
                    $ext->set_msgstr($i, encode_utf8( $translated ) );
                }
            }
            else {
                $ext->set_msgstr($i, undef) if $self->{overwrite};
            }

        }
    }

    $logger->info( "Writing po file to $pofile" );
    $ext->write_po($pofile);

    if( $self->{mo} ) {
        my $mofile = $pofile;
        $mofile =~ s{\.po$}{.mo};
        $logger->info( "Updating MO file: $mofile" );
        system(qq{msgfmt -v $pofile -o $mofile});
    }

    $logger->info( "Done" );
}




1;
