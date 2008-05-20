# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Mail::Builder' ); }

my $object = Mail::Builder->new();
isa_ok ($object, 'Mail::Builder');
