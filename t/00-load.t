#!perl

use Test::More tests => 2;

BEGIN {
	use_ok('API::McBain') || print "Bail out!\n";
	use_ok('API::McBain::Topic') || print "Bail out!\n";
}

diag( "Testing API::McBain $API::McBain::VERSION, Perl $], $^X" );
