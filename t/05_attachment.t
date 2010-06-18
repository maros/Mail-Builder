# -*- perl -*-

# t/04_attachment.t - check module for attachment handling

use Test::Most tests => 37 + 1;
use Test::NoWarnings;

use Mail::Builder;
use Path::Class::File;

my $pc_file = Path::Class::File->new('t/testfile.txt');

my $attachment1 = Mail::Builder::Attachment->new('t/testfile.txt');
my $attachment2 = Mail::Builder::Attachment->new({ file => $pc_file });
my $attachment3 = Mail::Builder::Attachment->new({ file => $pc_file->openr });
my $attachment4 = Mail::Builder::Attachment->new(\'File content');

isa_ok ($attachment1, 'Mail::Builder::Attachment');
isa_ok ($attachment2, 'Mail::Builder::Attachment');
isa_ok ($attachment3, 'Mail::Builder::Attachment');
isa_ok ($attachment4, 'Mail::Builder::Attachment');

is($attachment1->filecontent,'This is a test file for the attachment test!','Content ok');
is($attachment2->filecontent,'This is a test file for the attachment test!','Content ok');
is($attachment3->filecontent,'This is a test file for the attachment test!','Content ok');
is($attachment4->filecontent,'File content','Content ok');

is($attachment1->filename,'t/testfile.txt','Filename ok');
is($attachment2->filename,'t/testfile.txt','Filename ok');
is($attachment3->filename,undef,'Filename missing ok');
is($attachment4->filename,undef,'Filename missing ok');

isa_ok($attachment1->filename,'Path::Class::File');
isa_ok($attachment2->filename,'Path::Class::File');

is($attachment1->mimetype,'text/plain','MIME type ok');
is($attachment2->mimetype,'text/plain','MIME type ok');
is($attachment3->mimetype,'application/octet-stream','Fallback MIME type ok');
is($attachment4->mimetype,'application/octet-stream','Fallback MIME type ok');

$attachment3->mimetype('text/plain');
is($attachment3->mimetype,'text/plain','MIME type ok');
throws_ok { $attachment4->mimetype('brokenmime') } qr/pass the type constraint because: 'brokenmime' is not a valid MIME-type/, 'Broken mimetype not accepted';

throws_ok { $attachment3->serialize } qr/Could not determine the attachment name automatically/,'Name check works';
$attachment3->name('testattachment.txt');
my $serialized_attachment3 = $attachment3->serialize;
isa_ok($serialized_attachment3,'MIME::Entity');

#is ($attachment->path, 't/testfile.txt');
#ok ($attachment->mime('text/plain'), 'Set mime type');
#is ($attachment->mime, 'text/plain');
#ok ($attachment->name('changes.txt'), 'Set name');
#is ($attachment->name, 'changes.txt');
#is ($attachment->{'cache'}, undef);
#ok ($mime = $attachment->serialize,'Get MIME::Entity');
#isa_ok ($mime, 'MIME::Entity');
#is ($mime->mime_type,'text/plain');
#is ($mime->head->get('Content-Disposition'),qq[attachment; filename="changes.txt"\n]);
#is ($mime->head->get('Content-Transfer-Encoding'),qq[base64\n]);
#eval {
#    $attachment = Mail::Builder::Attachment->new('t/missingfile.txt');
#};