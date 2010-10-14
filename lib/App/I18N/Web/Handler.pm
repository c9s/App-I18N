




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

package App::I18N::Web::Handler::GetPo;
use warnings;
use strict;
use base qw(Tatsumaki::Handler);
use Tatsumaki;
sub get {
    my ( $self, $lang, $locale ) = @_;

}






1;
