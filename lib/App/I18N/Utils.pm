package App::I18N::Utils;
use warnings;
use strict;
use Locale::Language;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(langinfo);

sub langinfo {
    my $file = shift;
    my $lc;
    my $lc_full;
    if ( $file =~ m{/(\w+)/LC_MESSAGES/}i ) {
        $lc = $1;
    }
    elsif ( $file =~ m{([a-z]{2})(_[A-Z][A-Z])?.po$}i ) {
        $lc = $1;
        $lc_full = $1 . $2 if $2;
    }
    return {
        lc_name     => $lc,
        lc_fullname => $lc_full,
        name        => code2language($lc),
        path        => $file,
        encoding    => undef, # XXX
    };
}




1;
