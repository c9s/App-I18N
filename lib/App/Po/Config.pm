package App::Po::Config;
use warnings;
use strict;
use File::Spec;
use YAML::XS;

our $CONFIG;

sub configfile {
    return File::Spec->catefile( 'etc', 'config.yml' ) );
}

sub exists {
	return -e File::Spec->catefile( 'etc' , 'config.yml' );
}

sub read {
	my $class = shift;
	my $configfile = shift;
	return $CONFIG ||= LoadFile( $configfile || $class->configfile );
}

1;
