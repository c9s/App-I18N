package App::I18N::Web;
use warnings;
use strict;
use base qw(Tatsumaki::Application);
use Any::Moose;

# web po options

has webpo =>
    ( is => 'rw', isa => 'HashRef', default => sub { 
        +{
        
        }
    } );

has db =>
    ( is => 'rw' );






1;
