# -*- perl -*-

# t/004_address.t - check module for address handling

use Test::More tests => 10;

use Mail::Builder;

my $address;

ok($address = Mail::Builder::Address->new('test@test.com'),'Create simple object');
isa_ok ($address, 'Mail::Builder::Address');
is ($address->email, 'test@test.com');
is ($address->name, undef);
is ($address->serialize, '<test@test.com>');
ok ($address->name('"This is a Test"'), 'Set new name');
is ($address->serialize, '"\"This is a Test\"" <test@test.com>');
ok ($address->email('othertest@test2.com'), 'Set new email');
is ($address->email, 'othertest@test2.com');
eval {
	$address->email('messed.up.@-address.comx');
};
like($@,qr/e\-mail address is not valid at/);