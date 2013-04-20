#!perl

use lib 't/lib';
use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use McBainTestAPI;

my $api = McBainTestAPI->new;

ok($api, 'object successfully created');

is(ref $api, 'McBainTestAPI', '...and it is the right class');

throws_ok(sub { $api->call('does_not_exist', one => 1, two => 2) }, 'API::McBain::Exception::NotFound', "non-existant topic");

throws_ok(sub { $api->call('math_bad', one => 1, two => 2) }, 'API::McBain::Exception::NotFound', "non-existant method");

is($api->call('math_add', one => 1, two => 2), 3, "simple add method works");

throws_ok(sub { $api->call('math_add', one => 1) }, 'API::McBain::Exception::BadRequest', "bad request exception thrown");

is($api->call('math_subtract', one => 4, two => 2), 2, "simple subtract method works");

is($api->call('math_add-then-subtract', one => 4, two => 2, three => 3), 3, "forwarding works");

done_testing();
