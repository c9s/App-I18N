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
    'g|gettext'  => 'gettext',
    ) }

sub run {
    my ( $self, $lang ) = @_;
    my $logger = App::Po->logger();
    my $podir = $self->{podir} || 'po';

    $self->{mo} = $self->{locale} = 1 if $self->{gettext};

    my @pofiles = File::Find::Rule->file->name( "*.po" )->in( $podir );
    for my $pofile ( @pofiles ) {
        $logger->info( "Updating $pofile" );
        if( $self->{mo} ) {
            my $mofile = $pofile;
            $mofile =~ s{\.po$}{.mo};
            $logger->info( "Updating $mofile" );
            qx{msgfmt -v $pofile -o $mofile};
        }
    }
}



1;
