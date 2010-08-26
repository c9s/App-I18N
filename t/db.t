#!/usr/bin/env perl
use Test::More tests => 8;
use utf8;
use lib 'lib';
use App::Po::DB;

use_ok('App::Po::DB');

my $db = App::Po::DB->new( lang => 'zh-tw' );
ok( $db );

$db->insert( 'test' , '測試' );

$entry = $db->find( 'test' );


ok( $entry );
ok( $entry->id );
ok( $entry->msgid );
ok( $entry->lang );
ok( $entry->msgstr );

is( $entry->msgstr , '測試' );
