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


=cut

sub options { (
    'q|quiet'  => 'quiet',
    'locale'   => 'locale',
    'podir=s'  => 'podir',
    ) }

sub run {
    my ( $self, $lang ) = @_;

    my $logger = App::Po->logger();

	# create language file
    my $podir = $self->{podir} || 'po';
    my $pot_name = App::Po->pot_name;

    my $potfile = File::Spec->catfile( $podir, $pot_name . ".pot") ;
    if( -e $potfile ) {
        $logger->info( "$potfile found." );
        my $langfile;
        if( $self->{locale} ) {
            $langfile = File::Spec->join( $podir , $lang , 'LC_MESSAGES' , $pot_name . ".po" );
        }
        else {
            $langfile = File::Spec->join( $podir , $lang . ".po" );
        }

        use File::Copy;
        $logger->info(  "$langfile created.");
        copy( $potfile , $langfile );

        $logger->info( "Done" );
    }


}

1;
