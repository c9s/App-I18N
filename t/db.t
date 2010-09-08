#!/usr/bin/env perl
use Test::More tests => 10;
use utf8;
use lib 'lib';
use App::Po::DB;

use_ok('App::Po::DB');

my $db = App::Po::DB->new();
ok( $db );

$db->insert( 'zh-tw',  'test' , '測試' );

$entry = $db->find( 'zh-tw', 'test' );


ok( $entry );
ok( $entry->id );
ok( $entry->msgid );
ok( $entry->lang );
ok( $entry->msgstr );

is( $entry->msgstr , '測試' );

my $entries = $db->fetch_lang_table( 'zh-tw' );
ok( @$entries );
is( scalar(@$entries) , 1 );
