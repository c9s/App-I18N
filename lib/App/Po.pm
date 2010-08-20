package App::Po;
use File::Copy;
use File::Find::Rule;
use File::Path qw/make_path/;
use Locale::Maketext::Extract;
use Getopt::Long;
use Exporter 'import';
use JSON;
my @EXPORT = qw(_);
use Carp;
use strict;
use warnings;

our $ext;

sub init {
	my $self = shift;
	my $conf = shift;

	use YAML::XS;

	my $config = do {
		open F, $conf;
		local $/;
		my $ret = <F>;
		close F;
		$ret;
	};

	$conf = Load $config;
	$ext = Locale::Maketext::Extract->new;
	$self->_load_po($conf->{lang}) if $conf->{lang};
}

sub _load_po {
	my $self = shift;
	my $lg = shift;
	$lg =~ s/\s+/_/g;
	$lg =~ s/-/_/g;
	my $path = "po/$lg.po";
	if(-e $path) {
		$ext->read_po($path);
	} else {
		croak "cannot read $path: file does not exist\n";
	}
}

sub change_lang ($$) {
	my $self = shift;
	my $lg = shift;
	$ext->clear;
	$self->_load_po($lg);
}

sub _($@) {
	my $str = shift;
	my @args = @_;
	$str = $ext->has_msgid($str)?$ext->msgstr($str):$str;
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
	if(-e "po/$lg.po") {
		die "po/$lg.po already exists\n";
	} elsif(-e 'po/app.po') {
		copy('po/app.po', "po/$lg.po")
			or die "failed to copy po/app.po to po/$lg.po";
	} else {
		#gives a empty po
		$ext = Locale::Maketext::Extract->new;
		$ext->write_po("po/$lg.po");
		undef $ext;
	}
	return 1;
}

sub parse {
	@ARGV = @_;
	my $js;
	GetOptions('js' => \$js);
	my @paths = @ARGV;
	my $ext = Locale::Maketext::Extract->new(
		plugins => {
			perl => ['*'],
		},
		#verbose => 1,
		warnings => 1,
	);

	my $rule = File::Find::Rule->file->name("*.pm", "*.pl", "*.js")->start(@paths);
	make_path('po');
	while(defined (my $path = $rule->match)) {
		$ext->extract_file($path);
		print "Parsing $path\n";
	}
	$ext->compile(1);
	print "Update po/app.po\n";
	$ext->write_po('po/app.po');

	#update the .pos
	my @pofiles = File::Find::Rule->file->name("*.po")->not_name("app.po")->in('po');
	my $ents = $ext->compiled_entries;
	foreach my $po (@pofiles) {
		print "Update $po\n";
		$ext->read_po($po);
		$ext->set_compiled_entries($ents);
		$ext->compile(1);
		$ext->write_po($po);
		if($js) {
			my $lg = $po;
			$lg =~ s#po/(\S+)\.po#$1#;
			dump_js($lg, $ext);
		}
	}
}

=dump_js
	generate a js dict containing all entries
=cut
sub dump_js {
	my $lg = shift;
	my $ext = shift;
	my $ents = $ext->entries;
	my %entries = ();
	foreach my $ent (keys %$ents) {
		$entries{$ent} = $ext->msgstr($ent);
	}
	open F, ">po/$lg.js" or die "failed to open po/$lg.js";
	print F "var dict = ". JSON->new->utf8(0)->encode(\%entries);
	close F;
}

1;
