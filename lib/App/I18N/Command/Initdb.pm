package App::I18N::Command::Initdb;
use warnings;
use strict;
use Cwd;
use App::I18N::Config;
use App::I18N::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use Locale::Maketext::Extract;
use base qw(App::I18N::Command);
use App::I18N::DB;
use DBI;
use DBD::SQLite;


sub options { (

    ) }

sub run {
    my ($self,$dbname) = @_;
    $dbname ||= 'i18n.sqlite';
    my $dbpath = File::Spec->join(  $ENV{HOME} ,  $dbname );

    if ( -e $dbpath ) {
        my $ans = $self->prompt( "Database $dbname exists, replace it ? (N/y)", 'n');
        return if( $ans =~ /n/i );
    }

    unlink( $dbpath );

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","");

    my $db = App::I18N::DB->new( dbh => $dbh  );
    $db->init_schema();

    $dbh->disconnect();

    print "Database $dbname ($dbpath) created.\n";
}


1;
