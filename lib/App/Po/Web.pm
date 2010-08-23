package App::Po::Web;
use warnings;
use strict;
use base qw(Tatsumaki::Application);
use Any::Moose;


has po_options => 
    ( is => 'rw' , isa => 'HashRef' , default => sub {  +{  } }  );





1;
