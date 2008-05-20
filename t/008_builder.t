# -*- perl -*-

# t/008_builder.t - check if everything works well toghether

use Test::More tests => 63;

use Mail::Builder;

my $mime;
my $object = Mail::Builder->new();
isa_ok ($object, 'Mail::Builder');
ok($object->returnpath('return@test.com'),'Set returnpath');
isa_ok($object->returnpath,'Mail::Builder::Address');
ok($object->organization('organization'),'Set organization');
is($object->organization,'organization');
my $replyaddress = Mail::Builder::Address->new('reply@test.com','Reply name');
ok($object->reply($replyaddress),'Set reply address');
isa_ok($object->reply(),'Mail::Builder::Address');
ok($object->priority('9'),'Set priority');
eval {
	$object->build_message();
};
like($@,qr/Recipient address/);
ok($object->to('recipient1@test.com'));
isa_ok($object->to(),'Mail::Builder::List');
is($object->to->length,1);
isa_ok($object->to->item(0),'Mail::Builder::Address');
is($object->to->item(0)->email,'recipient1@test.com');
isa_ok($object->cc(),'Mail::Builder::List');
is($object->cc->length,0);
my $list = Mail::Builder::List->new('Mail::Builder::Address');
$list->add('cc1@test.com');
$list->add('cc2@test.com');
ok($object->cc($list),'Set new list');
is($object->cc->length,2);
eval {
	$object->build_message();
};
like($@,qr/Sender address missing/);
ok($object->from('from@test.com'),'Set sender');
isa_ok($object->from,'Mail::Builder::Address');
is($object->from->email,'from@test.com');
eval {
	$object->build_message();
};
like($@,qr/e-mail subject missing/);
ok($object->subject('subject'),'Set subject');
is($object->subject,'subject');
eval {
	$mime = $object->build_message();
};
like($@,qr/e-mail content/);
ok($object->htmltext(qq[<html><head></head><body><h1>Headline</h1>

<p>
<ul>
	<li>Bullet</li>
	<li>Bullet</li>
</ul>
<strong>This is a bold text</strong>
<ol>
	<li>Item</li>
	<li>Item</li>
</ol>
<em>This is an <span>italic</span> text</em>

<p><a href="http://revdev.at">Visit us</a></p>

<img src="cid:revdev" alt="revdev logo"/>

<table>
  <tr>
    <td>Test1</td>
    <td>Test2</td>
    <td>Test3</td>
  </tr>
  <tr>
    <td colspan="2">Test21</td>
    <td>Test23</td>
  </tr>
  <tr>
    <td>Test31</td>
    <td>Test32</td>
    <td>Test33</td>
  </tr>
</table>

</p>
</body>
</html>
]),'Set HTML Text');
eval {
	$object->build_message();
};
like($@,qr/Invalid priority/);
ok($object->priority('4'),'Set priority');
ok($mime = $object->build_message(),'Build Message');
isa_ok($mime,'MIME::Entity');
like($object->{'plaintext'},qr/\t* Bullet/);
like($object->{'plaintext'},qr/\t1\. Item/);
like($object->{'plaintext'},qr/_This is an italic text_/);
like($object->{'plaintext'},qr/\*This is a bold text\*/);
like($object->{'plaintext'},qr/\[http:\/\/revdev\.at Visit us\]/);
like($object->{'plaintext'},qr/\[revdev logo\]/);

like($object->{'plaintext'},qr/Test1\s\sTest2\s\sTest3/);
like($object->{'plaintext'},qr/Test21\s{8}Test23/);

isa_ok($mime->head,'MIME::Head');
is($mime->head->get('To'),'<recipient1@test.com>'."\n");
is($mime->head->get('Cc'),'<cc1@test.com>,<cc2@test.com>'."\n");
is($mime->head->get('X-Priority'),'4'."\n");
is($mime->head->get('Subject'),'subject'."\n");
is($mime->parts,2);
ok($mime = $object->stringify(),'Stringify Message');
like($mime,qr/Content-Type: text\/html; charset="utf-8"/);
like($mime,qr/------_=_NextPart_002_/);

my $object2 = Mail::Builder->new();
ok($object2->to->add('recipient2@test.com','nice üft-8 nämé'));
ok($object2->from('from2@test.com','me'));
ok($object2->subject('Testmail'));
ok($object2->plaintext(qq[Text]));
ok($object2->attachment->add(qq[t/testfile.pdf],q[test.pdf]));
is($object2->attachment->length,1);
ok($mime = $object2->build_message(),'Build Message');
isa_ok($mime,'MIME::Entity');
isa_ok($mime->head,'MIME::Head');
is($mime->head->get('To'),'"=?UTF-8?B?bmljZSDDg8K8ZnQtOCBuw4PCpG3Dg8Kp?=" <recipient2@test.com>'."\n");
is($mime->head->get('Subject'),'Testmail'."\n");
is($mime->head->get('From'),'"me" <from2@test.com>'."\n");
is($mime->parts,2);
is($mime->parts(0)->mime_type,'application/pdf');
is($mime->parts(1)->mime_type,'text/plain');