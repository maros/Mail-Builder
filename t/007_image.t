# -*- perl -*-

# t/007_image.t - check module handling the images

use Test::More tests => 15;

use Mail::Builder;

ok($image = Mail::Builder::Image->new('t/testfile.gif'),'Create simple object');
isa_ok ($image, 'Mail::Builder::Image');
is ($image->path, 't/testfile.gif');
ok ($image->id('testid'), 'Set id');
is ($image->id, 'testid');
is ($image->{'type'}, 'gif');
is ($image->{'cache'}, undef);
ok ($mime = $image->serialize,'Get MIME::Entity');
isa_ok ($mime, 'MIME::Entity');
is ($mime->mime_type,'image/gif');
is ($mime->head->get('Content-Transfer-Encoding'),qq[base64\n]);
eval {
	$image = Mail::Builder::Image->new('t/missingfile.gif');
};
like($@,qr/Could not find\/open file/);
eval {
	$image = Mail::Builder::Image->new('t/testfile.txt');
};
like($@,qr/Invalid file type/);
$image = Mail::Builder::Image->new('t/testfile.gif');
ok ($mime = $image->serialize,'Get MIME::Entity');
is ($image->id, 'testfile');