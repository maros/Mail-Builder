# -*- perl -*-

# t/005_list.t - check module for list handling

use Test::More tests => 28;

use Mail::Builder;

my ($list,$list2); 

ok($list = Mail::Builder::List->new('Mail::Builder::Address'),'Create list');
isa_ok ($list, 'Mail::Builder::List');
is($list->type, 'Mail::Builder::Address');
is($list->length, 0);
ok($list->add('test@test.com'), 'Add new item');
is($list->length, 1);
ok($list->add('test2@test2.com','test'), 'Add new item');
is($list->length, 2);
isa_ok(scalar($list->list),'ARRAY');
isa_ok($list->item(0),'Mail::Builder::Address');
isa_ok($list->item(1),'Mail::Builder::Address');
is($list->item(2),undef);
is($list->join(', '),'test@test.com, "test" <test2@test2.com>');
my $address1 = new Mail::Builder::Address('test2@test2.com');
ok($list->has($address1),'Has item');
ok($list->reset,'Reset list');
is($list->length, 0);
my $address2 = Mail::Builder::Address->new('test3@test3.com','test3');
ok($list->add($address2));
is($list->length, 1);
my $fake_object = bless {},'Fake';
eval {
	$list->add($fake_object);
};
like($@,qr/Invalid item added to list/);

ok($list2 = Mail::Builder::List->convert([$address1,$address2]),'Convert item');
is($list2->item(0)->email, 'test2@test2.com');
is($list2->length, 2);
ok($list2->remove($address1));
is($list2->length, 1);
ok($list2->remove($address1));
is($list2->length, 1);
ok($list2->remove($address2->email));
is($list2->length, 0);