package App::I18N::Command::Import;
use warnings;
use strict;
use base qw(App::I18N::Command);
use App::I18N::DB;
use DBI;
use DBD::SQLite;
use File::Find::Rule;


use App::I18N::Utils qw(langinfo);

sub run {
    my ($self, @args) = @_;
    my @files = map { -d $_ ? File::Find::Rule->file->name( "*.po" )->in( $_ ) : $_ } @args;
    my @podata = map { langinfo($_) } @files;


    my $db = App::I18N::DB->new( memory => 1);
    $db->init_schema;
    for my $po ( @podata ) {
        $db->import_po( $po->{lc_fullname} , $po->{path} );
    }


    $db->close();
}

1;
