




package App::I18N::Web::Handler;
use warnings;
use strict;
use base qw(Tatsumaki::Handler);
use Tatsumaki;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Template::Declare;

sub update_po {
    my ( $self, $pofile, $lexicon ) = @_;

    my $lme = App::I18N->lm_extract();
    $lme->read_po($pofile) if -f $pofile && $pofile !~ m/pot$/;

    # Reset previously compiled entries before a new compilation
    $lme->set_compiled_entries;
    $lme->compile(1);  # use gettext style

    my $o_lexicon = $lme->lexicon;
    for ( keys %$lexicon ) {
        print STDERR "Setup Entry: $_ : @{[  $lexicon->{ $_ } ]} \n";
        $o_lexicon->{ $_ } = $lexicon->{ $_ };
    }
    $lme->set_lexicon($o_lexicon);
    $lme->write_po($pofile);
}

sub post {
    my ($self,$path) = @_;
    my $params = $self->request->parameters->mixed;
    use List::MoreUtils qw(zip);

    my $pofile = $params->{pofile};
    my %lexicon = zip @{ $params->{'msgid[]'} } 
        ,@{ $params->{'msgstr[]'} };

    $self->update_po( $pofile , \%lexicon );
    $self->finish({ success => 1 });
}

sub get {
    my ( $self, $path ) = @_;
    $path ||= "/";
    $self->write( Template::Declare->show( $path, $self ) );
    $self->finish;
}



package App::I18N::Web::Handler::API;
use base qw(Tatsumaki::Handler);

sub post {

}

sub get {
    my ( $self, $path ) = @_;
    my ( $p1, $p2, @parts ) = split /\//, $path;
    my $params = $self->request->parameters->mixed;

    if( $p1 eq 'lang' && $p2 eq 'list' ) {
        my $langdata = $self->application->podata;
        $self->write( $langdata );
    }
    elsif( $p1 eq 'entry' && $p2 eq 'list' ) {
        my $lang = shift @parts;
        my $entrylist = $self->application->db->get_entry_list( $lang );
        $self->write( { 
            entrylist => $entrylist } );
    }
    elsif( $p1 eq 'entry' && $p2 eq 'get' ) {
        my $id = shift @parts;
        my $entry = $self->application->db->get_entry( $id );
        $self->write( $entry );
    } 
    elsif( $p1 eq 'entry' && $p2 eq 'set' ) {
        my $id = shift @parts;
        my $msgstr = shift @parts;
        $self->application->db->set_entry(  $id , $msgstr );
        $self->write({ success => 1 });
    }

    # warn "!!!!!!!!!!!!!!!!!!!!!!";
}

1;
