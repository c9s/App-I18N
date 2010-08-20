package App::Po;
use File::Copy;
use File::Find::Rule;
use File::Path qw/make_path/;
use Locale::Maketext::Extract;
use Getopt::Long;
use Exporter 'import';
use JSON::XS;
use YAML::XS;

my @EXPORT = qw(_);

use Carp;
use strict;
use warnings;

our $Ext;

sub init {
	my $self = shift;
	my $conf = shift;


	my $config = do {
		open F, $conf;
		local $/;
		my $ret = <F>;
		close F;
		$ret;
	};

	$conf = Load $config;
	$Ext = Locale::Maketext::Extract->new;
	$self->_load_po($conf->{lang}) if $conf->{lang};
}

sub _load_po {
	my $self = shift;
	my $lg = shift;
	$lg =~ s/\s+/_/g;
	$lg =~ s/-/_/g;
	my $path = "po/$lg.po";
	if(-e $path) {
		$Ext->read_po($path);
	} else {
		croak "cannot read $path: file does not exist\n";
	}
}

sub change_lang ($$) {
	my $self = shift;
	my $lg = shift;
	$Ext->clear;
	$self->_load_po($lg);
}

sub _($@) {
	my $str = shift;
	my @args = @_;
	$str = $Ext->has_msgid($str)?$Ext->msgstr($str):$str;
	my @tokens = split /(%\d+)/, $str;
	map {
		if($_ =~ /^%(\d+)$/) {
			$_ = $args[$1 - 1];
		}
	} @tokens;
	return join('', @tokens);
}

sub lang {
	my $lg = shift;
	unless(-d 'po') {
		make_path('po');
	}
    $lg =~ s/\s+/_/g;
    $lg =~ s/-/_/g;
    if ( -e "po/$lg.po" ) {
        die "po/$lg.po already exists\n";
    } elsif ( -e 'po/app.po' ) {
        copy( 'po/app.po', "po/$lg.po" )
            or die "failed to copy po/app.po to po/$lg.po";
    } else {

        #gives a empty po
        $Ext = Locale::Maketext::Extract->new;
        $Ext->write_po("po/$lg.po");
        undef $Ext;
    }
	return 1;
}

sub parse {
	@ARGV = @_;
	my $js;
	GetOptions('js' => \$js);
	my @paths = @ARGV;
	my $Ext = Locale::Maketext::Extract->new(
		plugins => {
			perl => ['*'],
		},
		#verbose => 1,
		warnings => 1,
	);

	my $rule = File::Find::Rule->file->name("*.pm", "*.pl", "*.js")->start(@paths);
	make_path('po');
	while(defined (my $path = $rule->match)) {
		$Ext->extract_file($path);
		print "Parsing $path\n";
	}
	$Ext->compile(1);
	print "Update po/app.po\n";
	$Ext->write_po('po/app.po');

	#update the .pos
	my @pofiles = File::Find::Rule->file->name("*.po")->not_name("app.po")->in('po');
	my $ents = $Ext->compiled_entries;
	foreach my $po (@pofiles) {
		print "Update $po\n";
		$Ext->read_po($po);
		$Ext->set_compiled_entries($ents);
		$Ext->compile(1);
		$Ext->write_po($po);
		if($js) {
			my $lg = $po;
			$lg =~ s#po/(\S+)\.po#$1#;
			dump_js($lg, $Ext);
		}
	}
}

=head1 dump_js

	generate a js dict containing all entries

=cut

sub dump_js {
	my $lg = shift;
	my $Ext = shift;
	my $ents = $Ext->entries;
	my %entries = ();
	foreach my $ent (keys %$ents) {
		$entries{$ent} = $Ext->msgstr($ent);
	}
	open F, ">po/$lg.js" or die "failed to open po/$lg.js";
	print F "var dict = ". encode_json(\%entries);
	close F;
}

1;
