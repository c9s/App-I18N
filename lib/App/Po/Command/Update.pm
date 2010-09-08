package App::Po::Command::Update;
use warnings;
use strict;
use Cwd;
use App::Po::Config;
use App::Po::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use base qw(App::Po::Command);

sub options { (
    'mo'       => 'mo',   # generate mo file
    'podir=s'  => 'podir',
    ) }

sub run {
    my ( $self, $lang ) = @_;
    my $logger = App::Po->logger();
    my $podir = $self->{podir} || 'po';


    my @pofiles = File::Find::Rule->file->name( "*.po" )->in( $podir );
    for my $pofile ( @pofiles ) {
        if( $self->{mo} ) {
            $logger->info( "Updating $pofile" );
            qx{msgfmt -v $pofile};
        }
    }
}



1;
