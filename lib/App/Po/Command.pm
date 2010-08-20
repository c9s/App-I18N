package App::Po::Command;
use warnings;
use strict;
use base qw(App::CLI App::CLI::Command);

sub invoke {
    my ($pkg, $cmd, @args) = @_;
    local *ARGV = [$cmd, @args];
    my $ret = eval {
        $pkg->dispatch();
    };
    if( $@ ) {
        warn $@;
    }
}


1;
