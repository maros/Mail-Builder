# -*- perl -*-

# t/004_address.t - check module for address handling

use Test::More tests => 15 + 1;
use Test::NoWarnings;

use Mail::Builder;

ok($address1 = Mail::Builder::Address->new('test@test.com'),'Create simple object');
isa_ok ($address1, 'Mail::Builder::Address');
is ($address1->email, 'test@test.com','Check email address');
is ($address1->name, undef,'Name not set');
is ($address1->comment, undef,'Comment not set');
is ($address1->serialize, 'test@test.com','Serialize email');
ok ($address1->name('This is a Test'),'Set new name');
is ($address1->serialize, '"This is a Test" <test@test.com>','Serialize email with name');

ok($address2 = Mail::Builder::Address->new('test@test.com','testname'),'Create simple object');
isa_ok ($address2, 'Mail::Builder::Address');
is ($address2->email, 'test@test.com','Check email address');
is ($address2->name, 'testname','Check name');

ok($address3 = Mail::Builder::Address->new('test@test.com','testname','comment'),'Create simple object');
isa_ok ($address3, 'Mail::Builder::Address');
is ($address3->email, 'test@test.com','Check email address');
is ($address3->name, 'testname','Check name');
is ($address3->comment, 'comment','Check name');
is ($address3->serialize, '"testname" <test@test.com> comment','Serialize email with name');
#
#
#ok ($address->email('othertest@test2.com'), 'Set new email');
#is ($address->email, 'othertest@test2.com');
#
#eval {
#    $address->email('messed.up.@-address.comx');
#};
#like($@,qr/e\-mail address is not valid at/);

