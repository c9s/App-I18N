package App::Po::Command::Lang;
use warnings;
use strict;
use Cwd;
use App::Po::Config;
use App::Po::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use base qw(App::Po::Command);

=head1 Lang Command


    --mo        
                generate mo file

    --locale    
                create new po file from pot file in locale directory structure:
                    {podir}/{lang}/LC_MESSAGES/{potname}.po

    -q
    --quiet         
                just be quiet

    --podir={path}  
                po directory. potfile will be generated in {podir}/{appname}.pot

=cut

sub options { (
    'q|quiet'  => 'quiet',
    'locale'   => 'locale',
    'mo'       => 'mo',   # generate mo file
    'podir=s'  => 'podir',
    ) }

sub run {
    my ( $self, $lang ) = @_;

    my $logger = App::Po->logger();
    my $podir = $self->{podir} || 'po';

    mkpath [ $podir ];

    my $pot_name = App::Po->pot_name;

    my $potfile = File::Spec->catfile( $podir, $pot_name . ".pot") ;
    if( ! -e $potfile ) {
        $logger->info( "$potfile not found." );
        return;
    }

    $logger->info( "$potfile found." );
    my $pofile;
    if( $self->{locale} ) {

        mkpath [ File::Spec->join( $podir , $lang , 'LC_MESSAGES' )  ];
        $pofile = File::Spec->join( $podir , $lang , 'LC_MESSAGES' , $pot_name . ".po" );

    }
    else {
        $pofile = File::Spec->join( $podir , $lang . ".po" );
    }

    use File::Copy;
    $logger->info(  "$pofile created.");
    copy( $potfile , $pofile );

    if( $self->{mo} ) {
        $logger->info( "Generating MO file for $pofile" );
        system(qq{msgfmt -v $pofile});
    }

    $logger->info( "Done" );
}

1;
