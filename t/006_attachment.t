# -*- perl -*-

# t/006_attachment.t - check module handling the attachments

use Test::More tests => 23;

use Mail::Builder;

ok($attachment = Mail::Builder::Attachment::File->new('t/testfile.txt'),'Create simple object');
isa_ok ($attachment, 'Mail::Builder::Attachment');
isa_ok ($attachment, 'Mail::Builder::Attachment::File');
is ($attachment->path, 't/testfile.txt');
ok ($attachment->mime('text/plain'), 'Set mime type');
is ($attachment->mime, 'text/plain');
ok ($attachment->name('changes.txt'), 'Set name');
is ($attachment->name, 'changes.txt');
is ($attachment->{'cache'}, undef);
ok ($mime = $attachment->serialize,'Get MIME::Entity');
isa_ok ($mime, 'MIME::Entity');
is ($mime->mime_type,'text/plain');
is ($mime->head->get('Content-Disposition'),qq[attachment; filename="changes.txt"\n]);
is ($mime->head->get('Content-Transfer-Encoding'),qq[base64\n]);
eval {
	$attachment = Mail::Builder::Attachment->new('t/missingfile.txt');
};
like($@,qr/Could not find\/open file/);
ok($attachment = Mail::Builder::Attachment->new('t/testfile.pdf'));
ok ($mime = $attachment->serialize,'Get MIME::Entity');
is ($attachment->mime,'application/pdf');
is ($attachment->name,'testfile.pdf');
$attachment = Mail::Builder::Attachment::Data->new('FILECONTENT','testfile.exe','application/octet-stream');
isa_ok ($attachment, 'Mail::Builder::Attachment::Data');
is ($attachment->data, 'FILECONTENT');
ok ($attachment->data('FILECONTENT_NEU'), 'Set data');
is ($attachment->data, 'FILECONTENT_NEU');