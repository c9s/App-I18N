package App::I18N::DB;
use warnings;
use strict;
use DBI;
use Any::Moose;
use Encode;

has dbh => 
    ( is => 'rw' );

sub BUILD {
    my ($self,$args) = @_;
    # my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","",
            { RaiseError     => 1, sqlite_unicode => 1, });
    my $rv = $dbh->do( qq|create table po_string (  
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lang TEXT,
            msgid TEXT,
            msgstr TEXT
        );|);
    $self->dbh( $dbh );
}

# by {id}
sub get_entry {
    my ( $self, $id ) = @_;
    my $sth = $self->dbh->prepare(qq{ select * from po_string where id = ? });
    $sth->execute($id);
    my $data = $sth->fetchrow_hashref();
    $sth->finish;
    return $data;
}

sub set_entry {
    my ($self,$id,$msgstr) = @_;
    die unless $id && $msgstr;
    my $sth = $self->dbh->prepare(qq{ update po_string set msgstr = ? where id = ? });
    my $ret = $sth->execute( $msgstr, $id );
    $sth->finish;
    return $ret;
}

sub last_id {
    my $self = shift;


}

sub insert {
    my ( $self , $lang , $msgid, $msgstr ) = @_;
    $msgstr = decode_utf8( $msgstr );
    my $sth = $self->dbh->prepare(
        qq| INSERT INTO po_string (  lang , msgid , msgstr ) VALUES ( ? , ? , ? ); |);
    $sth->execute( $lang, $msgid, $msgstr );
}

sub find {
    my ( $self, $lang , $msgid ) = @_;
    my $sth = $self->dbh->prepare(qq| SELECT * FROM po_string WHERE lang = ? AND msgid = ? LIMIT 1;|);
    $sth->execute( $lang, $msgid );
    my $data = $sth->fetchrow_hashref();
    $sth->finish;


    return $data;
}

sub get_unset_entry_list {
    my ($self, $lang ) = @_;
    my $sth;
    if( $lang ) {
        $sth = $self->dbh->prepare(qq| SELECT * FROM po_string where lang = ? and msgstr = '' or msgstr is null; |);
        $sth->execute( $lang );
    }
    else {
        $sth = $self->dbh->prepare(qq| SELECT * FROM po_string where msgstr = '' or msgstr is null; | );
        $sth->execute();
    }
    return $self->_entry_sth_to_list( $sth );
}

sub get_entry_list {
    my ( $self, $lang ) = @_;
    my $sth;
    if( $lang ) {
        $sth = $self->dbh->prepare(qq| select * from po_string where lang = ? |);
        $sth->execute( $lang );
    }
    else {
        $sth = $self->dbh->prepare(qq| select * from po_string | );
        $sth->execute();
    }
    return $self->_entry_sth_to_list( $sth );
}


sub _entry_sth_to_list {
    my ($self , $sth) = @_;
    my @result;
    while( my $row = $sth->fetchrow_hashref ) {
        push @result, {
            id     => $row->{id},
            lang   => $row->{lang},
            msgid  => $row->{msgid},
            msgstr => $row->{msgstr},
        };
    }
    return \@result;
}




sub get_langlist {
    my $self = shift;
    my $sth = $self->dbh->prepare("select distinct lang from po_string;");
    $sth->execute();
    my $hashref = $sth->fetchall_hashref('lang');
    $sth->finish;
    return keys %$hashref;
}

sub write_to_pofile {
    # XXX:

}

sub import_lexicon {
    my ( $self , $lang , $lex ) = @_;
    while ( my ( $msgid, $msgstr ) = each %$lex ) {
        $self->insert( $lang , $msgid , $msgstr );
    }
}


sub import_po {
    my ( $self, $lang, $pofile ) = @_;
    my $lme = App::I18N->lm_extract;
    $lme->read_po($pofile) if -f $pofile && $pofile !~ m/pot$/;
    $self->import_lexicon( $lang , $lme->lexicon );
}

# sub get_entrylist {
#     my ( $self, $lang ) = @_;
# 
# 
# }


sub export_lexicon {
    my ($self) = @_;
    my $lexicon;


    return $lexicon;
}

sub export_po {
    my ( $self, $podir ) = @_;

    # $lme->write_po($pofile);
}

=pod
package MsgEntry;
use Any::Moose;
use JSON::XS;
use overload 
    '""' => \&to_string,
    '%{}' => \&to_hash;


has id => ( is => 'rw', isa => 'Int' );
has lang  => ( is => 'rw' , isa => 'Str' );
has msgid => ( is => 'rw' , isa => 'Str' );
has msgstr => ( is => 'rw' , isa => 'Str' );

sub to_hash {
    my $self = shift;
    return (
        id       => $self->id,
        lang     => $self->lang,
        msgid    => $self->msgid,
        msgstr   => $self->msgstr,
    );
}

sub to_string {
    my $self = shift;
    return encode_json( { $self->to_hash } );
}
=cut


1;
