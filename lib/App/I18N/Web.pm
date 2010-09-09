package App::I18N::Web;
use warnings;
use strict;
use base qw(Tatsumaki::Application);
use Any::Moose;

has webpo =>
    ( is => 'rw', isa => 'HashRef', default => sub { 
        +{
        
        }
    } );

1;
