package App::I18N::Command;
use warnings;
use strict;
use base qw(App::CLI App::CLI::Command);

sub options {
    return (
        'h|help|?' => 'help',
        'man' => 'man',
    );
}

sub alias {
    (
        "s" => "server",
        "p" => "parse",
        "l" => "lang",
    );
}

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


sub logger {
    return App::I18N->logger();
}

1;
