# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 9 + 1;
use Test::NoWarnings;
use Test::Exception;

use Mail::Builder;

my $mailbuilder = Mail::Builder->new();

isa_ok($mailbuilder,'Mail::Builder');

# Test address accessors
ok($mailbuilder->from('from@test.com'),'Set from');
isa_ok($mailbuilder->from,'Mail::Builder::Address');
is($mailbuilder->from->email,'from@test.com','Has correct email address');

# Test basic accessor
is($mailbuilder->has_organization,'','Has no organization');
ok($mailbuilder->organization('organization'),'Set organization');
is($mailbuilder->has_organization,1,'Has organization');
is($mailbuilder->organization,'organization','Has correct organization');

throws_ok {
    $mailbuilder->build_message();
} qr/Recipient address missing/,'Required values missing';

$mailbuilder->to(Mail::Builder::Address->new(email => 'to@test.com'));