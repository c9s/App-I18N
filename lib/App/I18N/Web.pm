package App::I18N::Web;
use warnings;
use strict;
use base qw(Tatsumaki::Application);
use Any::Moose;

# XXX: web po => options 
has options =>
    ( is => 'rw', isa => 'HashRef', default => sub { 
        +{
        
        }
    } );

has podata =>
    ( is => 'rw' , isa => 'HashRef' , default => sub { +{  } } );


has db =>
    ( is => 'rw' );


1;
