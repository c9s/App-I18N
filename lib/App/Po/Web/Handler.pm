package App::Po::Web::Handler;
use warnings;
use strict;
use base qw(Tatsumaki::Handler);
use Tatsumaki;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Template::Declare;

sub post {
    my ($self,$path) = @_;
    my $params = $self->request->parameters->mixed;
    use List::MoreUtils qw(zip);


    my $pofile = $params->{pofile};
    my %lexicon = zip @{ $params->{'msgid[]'} } 
        ,@{ $params->{'msgstr[]'} };

    # use Data::Dumper; warn Dumper( \%lexicon );
    # zip arrayref

    Locale::Maketext::Lexicon::set_option('allow_empty' => 1);
    my $lme = App::Po->lm_extract();
    $lme->read_po($pofile) if -f $pofile && $pofile !~ m/pot$/;


    # Reset previously compiled entries before a new compilation
    $lme->set_compiled_entries;
    $lme->compile(1);  # use gettext style


    use Data::Dumper; warn Dumper( \%lexicon );
    
    

    $lme->set_lexicon( \%lexicon );
    $lme->write_po($pofile);

#     $orig_lexicon = $lme->lexicon;
#     my $lexicon = { %$orig_lexicon };
# 
#     # XXX: cache core_lm
#     my $core_lm = Locale::Maketext::Extract->new();
#     Locale::Maketext::Lexicon::set_option('allow_empty' => 1);
#     # $core_lm->read_po( File::Spec->catfile(  ));
#     # Locale::Maketext::Lexicon::set_option('allow_empty' => 0);
#     # for (keys %{ $core_lm->lexicon }) {
#     #     next unless exists $lexicon->{$_};
#     #     # keep the local entry overriding core if it exists
#     #     delete $lexicon->{$_} unless length $lexicon->{$_};
#     # }
#     $lme->set_lexicon($lexicon);
#     $lme->write_po($translation);
#     $lme->set_lexicon($orig_lexicon);




    $self->finish({ success => 1 });
}

sub get {
    my ( $self, $path ) = @_;
    $path ||= "/";
    $self->write( Template::Declare->show( $path, $self ) );
    $self->finish;
}

1;
