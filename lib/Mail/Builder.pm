# ============================================================================
package Mail::Builder;
# ============================================================================

use version;
our $AUTHORITY = 'cpan:MAROS';
our $VERSION = version->new("2.00");

use Moose;
with qw(Mail::Builder::Role::TypeConstraints);

use Carp;

use Encode qw(encode decode); 
use MIME::Entity;

use Email::MessageID;
use Email::Address;

use Mail::Builder::Address;
use Mail::Builder::Attachment;
use Mail::Builder::Image;
use Mail::Builder::List;

has 'plaintext' => (
    is              => 'rw',
    isa             => 'Str',
    predicate       => 'has_plaintext',
    clearer         => 'clear_plaintext',
);

has 'htmltext' => (
    is              => 'rw',
    isa             => 'Str',
    predicate       => 'has_htmltext',
    clearer         => 'clear_htmltext',
    trigger         => \&_generate_plaintext,
);

has 'subject' => (
    is              => 'rw',
    isa             => 'Str',
    #required        => 1,
    predicate       => 'has_subject',
);

has 'organization' => (
    is              => 'rw',
    isa             => 'Str',
    predicate       => 'has_organization',
    clearer         => 'clear_organization',
);

has 'priority' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::Priority',
    default         => 3,
);

has 'language' => (
    is              => 'rw',
    isa             => 'Str',
    clearer         => 'clear_language',
    predicate       => 'has_language',
);

has 'mailer' => (
    is              => 'rw',
    isa             => 'Str',
    default         => "Mail::Builder v$VERSION",
);

has 'autotext' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => 1,
);

has 'messageid' => (
    is              => 'rw',
    isa             => 'Email::MessageID',
    default         => sub { Email::MessageID->new },
);

has '_boundary' => (
    is              => 'rw',
    isa             => 'Int',
    default         => 1,
);

has 'from' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::Address',
    predicate       => 'has_from',
    clearer         => 'clear_from',
);

has 'reply' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::Address',
    predicate       => 'has_reply',
    clearer         => 'clear_reply',
);

has 'returnpath' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::Address',
    predicate       => 'has_returnpath',
    clearer         => 'clear_returnpath',
);

has 'sender' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::Address',
    predicate       => 'has_sender',
    clearer         => 'clear_sender',
);

has [qw(to cc bcc)] => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::AddressList',
    required        => 1,
    coerce          => 1,
    default         => \&_default_addresslist,
);

has 'attachment' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::AttachmentList',
    coerce          => 1,
    required        => 1,
    default         => sub { Mail::Builder::List->new( type => 'Mail::Builder::Attachment' ) }
);

has 'image' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::ImageList',
    coerce          => 1,
    required        => 1,
    default         => sub { Mail::Builder::List->new( type => 'Mail::Builder::Image' ) }
);

around 'from' => \&_address_accessor;
around 'returnpath' => \&_address_accessor;
around 'sender' => \&_address_accessor;
around 'reply' => \&_address_accessor;

sub _default_addresslist {
    return Mail::Builder::List->new( type => 'Mail::Builder::Address' )
}

sub _address_accessor {
    my ($method,$self,@params) = @_;
    
    if (scalar @params) {
        return $method->($self,Mail::Builder::Address->new(@params));
    } else {
        return $method->($self);
    }
}

sub _generate_plaintext {
    my ($self,$htmltext) = @_;
    $htmltext ||= $self->htmltext;
    
    if ($self->autotext) {
        Class::MOP::load_class('HTML::TreeBuilder');
        
        my $html_tree = HTML::TreeBuilder->new_from_content($self->htmltext);
        # Only use the body
        my $html_body = $html_tree->find('body');
        # And now convert all elements
        $self->plaintext($self->_convert_text($html_body));
    }
}

sub _convert_text {
    my ($self,$html_element,$params) = @_;

    my $plain_text = q[];
    $params ||= {};
    
    # Loop all children of the HTML element  
    foreach my $html_content ($html_element->content_list) {
        # HTML element
        if (ref($html_content) 
            && $html_content->isa('HTML::Element')) {
            my $html_tagname = $html_content->tag;
            if ($html_tagname eq 'i' || $html_tagname eq 'em') {
                $plain_text .= '_'.$self->_convert_text($html_content,$params).'_';
            } elsif ($html_tagname =~ m/^h\d$/) {
                $plain_text .= '=='.$self->_convert_text($html_content,$params).qq[\n];
            } elsif ($html_tagname eq 'strong' || $html_tagname eq 'b') {
                $plain_text .= '*'.$self->_convert_text($html_content,$params).'*';
            } elsif ($html_tagname eq 'hr') {
                $plain_text .= qq[\n---------------------------------------------------------\n];
            } elsif ($html_tagname eq 'br') {
                $plain_text .= qq[\n];
            } elsif ($html_tagname eq 'ul' || $html_tagname eq 'ol') {
                my $count_old = $params->{count};    
                $params->{count} = ($html_tagname eq 'ol') ? 1:'*';
                $plain_text .= qq[\n].$self->_convert_text($html_content,$params).qq[\n\n];
                if (defined $count_old) {
                    $params->{count} = $count_old;
                } else {
                    delete $params->{count};
                }
            } elsif ($html_tagname eq 'div' || $html_tagname eq 'p') {
                $plain_text .= $self->_convert_text($html_content,$params).qq[\n\n];
            } elsif ($html_tagname eq 'table') {
                require Text::Table; # Load Text::Table lazily
                    
                my $table_old = $params->{table}; 
                $params->{table} = Text::Table->new();
                $self->_convert_text($html_content,$params);
                $params->{table}->body_rule('-','+');
                $params->{table}->rule('-','+');
                $plain_text .= qq[\n].$params->{table}->rule('-').$params->{table}.$params->{table}->rule('-').qq[\n];
                if (defined $table_old) {
                    $params->{table} = $table_old;
                } else {
                    delete $params->{table};
                }
            } elsif ($html_tagname eq 'tr' 
                && defined $params->{table}) { 
                my $tablerow_old = $params->{tablerow}; 
                $params->{tablerow} = [];
                $self->_convert_text($html_content,$params);
                $params->{table}->add(@{$params->{tablerow}});
                if (defined $tablerow_old) {
                    $params->{tablerow} = $tablerow_old;
                } else {
                    delete $params->{tablerow};
                }
            } elsif (($html_tagname eq 'td' || $html_tagname eq 'th') && $params->{tablerow}) {
                push @{$params->{tablerow}},$self->_convert_text($html_content,$params);     
                if ($html_content->attr('colspan')) {
                    my $colspan = $html_content->attr('colspan') || 1;
                    $colspan --;
                    push @{$params->{tablerow}},''
                        for (1..$colspan);
                }
            } elsif ($html_tagname eq 'img' && $html_content->attr('alt')) {
                $plain_text .= '['.$html_content->attr('alt').']';  
            } elsif ($html_tagname eq 'a' && $html_content->attr('href')) {
                $plain_text .= '['.$html_content->attr('href').' '.$self->_convert_text($html_content,$params).']';    
            } elsif ($html_tagname eq 'li') {
                $plain_text .= qq[\n\t];
                $params->{count} ||= '*';
                if ($params->{count} eq '*') {
                    $plain_text .= '*';
                } elsif ($params->{count} =~ /^\d+$/) {
                    $plain_text .= $params->{count}.'.';
                    $params->{count} ++;
                }
                $plain_text .= q[ ].$self->_convert_text($html_content);
            } elsif ($html_tagname eq 'pre') {
                $params->{pre} = 1;
                $plain_text .= qq[\n].$self->_convert_text($html_content,$params).qq[\n\n];
                delete $params->{pre};
            } elsif ($html_tagname eq 'head'
                || $html_tagname eq 'script'
                || $html_tagname eq 'frameset'
                || $html_tagname eq 'style') {
                next;
            } else {
                $plain_text .= $self->_convert_text($html_content,$params);
            }
        # CDATA
        } else {
            unless ($params->{pre}) {
                $html_element =~ s/(\n|\n)//g;
                $html_element =~ s/(\t|\n)/ /g;
            }
            $plain_text .= $html_content;
        }
    }
    
    return $plain_text;
}

sub _get_boundary {
    my ($self) = @_;
    my $boundary = $self->_boundary( $self->_boundary + 1 );
    return sprintf('----_=_NextPart_%04i_%lx',$boundary,time);
}

sub charset {
    warn('DEPRECATED: The charset accessor has been removed.')
}

sub purge_cache {
    my ($self) = @_;
    
    foreach my $list (qw(attachment image)) {
        foreach my $element ($self->$list->list) {
            $element->clear_cache;
        }
    }
    return 1;
}

sub _build_text {
    my ($self,%mime_params) = @_;
    
    # Build plaintext message from HTML
    if ($self->has_htmltext
        && ! $self->has_plaintext
        && $self->autotext) {
        # Parse HTML tree. Load HTML::TreeBuilder lazily
        require HTML::TreeBuilder;
        
        my $html_tree = HTML::TreeBuilder->new_from_content($self->html_text);
        # Only use the body
        my $html_body = $html_tree->find('body');
        # And now convert all elements
        $self->plaintext(_convert_text($html_body));
    }
    
    my $mime_part;
    
    # We have HTML and plaintext
    if ($self->has_htmltext
        && $self->has_plaintext) {
        
        # Build multipart/alternative envelope for HTML and plaintext
        $mime_part = build MIME::Entity(
            %mime_params,
            Type        => q[multipart/alternative],
            Boundary    => $self->_get_boundary(),
            Encoding    => 'binary',
        );
        
        # Add the plaintext entity first
        $mime_part->add_part(build MIME::Entity (
            Top         => 0,
            Type        => qq[text/plain; charset="utf-8"],
            Data        => $self->plaintext,
            Encoding    => 'quoted-printable',
        ));
        
        # Add the html entity (the last entity is prefered in multipart/alternative context)
        $mime_part->add_part($self->_build_html(Top => 0));
    # We only have plaintext
    } else {
        $mime_part = build MIME::Entity (
            %mime_params,
            Type        => qq[text/plain; charset="utf-8"],
            Data        => $self->plaintext,
            Encoding    => 'quoted-printable',
        );
    }
    
    return $mime_part;
}

sub _build_html {
    my ($self,%mime_params) = @_;
    
    my $mime_part;
    
    # We have inline images
    if ($self->image->length) {
        # So we need a multipart/related envelope first
        $mime_part = build MIME::Entity(
            %mime_params,
            Type        => q[multipart/related],
            Boundary    => $self->_get_boundary(),
            Encoding    => 'binary',
        );
        # Add the html body
        $mime_part->add_part(build MIME::Entity (
            Top         => 0,
            Type        => qq[text/html; charset="utf-8"],
            Data        => $self->htmltext,
            Encoding    => 'quoted-printable',
        ));
        # And now all the inline images
        foreach ($self->image->list) {
            $mime_part->add_part($_->serialize);
        }
    # We don't have any inline images
    } else {
        $mime_part = build MIME::Entity (
            %mime_params,
            Type        => qq[text/html; charset="utf-8"],
            Data        => $self->htmltext,
            Encoding    => 'quoted-printable',
        );
    }   
    return $mime_part;
}


sub build_message {
    my ($self) = @_;
    
    croak(q[Recipient address missing]) 
        unless ($self->to->length());
    croak(q[From address missing]) 
        unless ($self->has_from);
    croak(q[e-mail subject missing]) 
        unless ($self->has_subject);
    croak(q[e-mail content missing]) 
        unless ($self->has_plaintext || $self->has_htmltext);
    
    # Set header fields
    my %email_header = (
        'Top'           => 1,
        'From'          => $self->from->serialize,
        'To'            => $self->to->join(','),
        'Cc'            => $self->to->join(','),
        'Bcc'           => $self->bcc->join(','),
        'Subject'       => encode('MIME-Header',$self->subject),
        'Message-ID'    => $self->messageid->in_brackets(),
        'X-Priority'    => $self->priority,
        'X-Mailer'      => encode('MIME-Header', $self->mailer),
    );
    
    # Set reply address
    if ($self->has_reply) {
        $email_header{'Reply-To'} = $self->reply->serialize;
    }
    
    # Set sender address
    if ($self->has_sender) {
        $email_header{'Sender'} = $self->has_sender->serialize;
    }
    
    # Set language
    if ($self->has_language) {
        $email_header{'Content-language'} = $self->language;
    }
    
    # Set return path
    if ($self->has_returnpath) {
        $email_header{'Return-Path'} = $self->has_returnpath->address();
    } elsif ($self->has_reply) {
        $email_header{'Return-Path'} = $self->reply->address();
    } else {
        $email_header{'Return-Path'} = $self->from->address();
    } 
    
    # Set organizsation
    if ($self->has_organization) {
        $email_header{'Organization'} = encode('MIME-Header', $self->organization);
    }
    
    # Build e-mail entity ...
    my $mime_entity;
    
    # ... with attachments
    if ($self->attachment->length()) {
        $mime_entity = build MIME::Entity(
            %email_header,
            Type        => 'multipart/mixed',
            Boundary    => $self->_get_boundary(),
            Encoding    => 'binary',
        );
        foreach my $attachment ($self->attachment->list()) {
            $mime_entity->add_part($attachment->serialize());
        }
        $mime_entity->add_part($self->_build_text(Top => 0));
    # ... without attachments
    } else {
        $mime_entity = $self->_build_text(%email_header);
    }
    
    return $mime_entity;
}

sub stringify {
    my $obj = shift;
    return $obj->build_message->stringify;
}

__PACKAGE__->meta->make_immutable;










=encoding utf8

=head1 NAME

Mail::Builder - Easily create plaintext/html e-mail messages with attachments
and inline images

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $mail = Mail::Builder->new();
  
  $mail->from('mightypirate@meele-island.mq','Guybrush Threepwood');
  $mail->to->add('manuel.calavera@dod.mx','Manuel Calavera');
  $mail->cc->add('glotis@dod.mx');
  $mail->subject('Party at Sam\'s place');
  $mail->htmltext('<h1>Party invitation</h1> ... ');
  $mail->attachment->add('direction_samandmax.pdf');

  # Send it with your favourite module (e.g. Email::Send)
  my $mailer = Email::Send->new({mailer => 'Sendmail'})->send($mail->stringify);
  
  # Or mess with MIME::Entity objects
  my $mime = $mail->build_message;
  $mime-> ....

=head1 DESCRIPTION

This module helps you to build correct e-mails with attachments, inline 
images, multiple recipients, ... without having to worry about the underlying
MIME stuff and encoding issues. Mail::Builder relies heavily on the 
L<MIME::Entity> module from the L<MIME::Tools> distribution. 

The module will create the correct MIME bodies, headers and containers 
(multipart/mixed, multipart/related, multipart/alternative) depending on if
you use attachments, HTML text and inline images.

Furthermore it will encode non-ascii header data and autogenerate plaintext
messages (if you don't provide it yourself or disable the
L<autotext> option) from html content.

Addresses, attachments and inline images are handled as objects by helper
classes:

=over

=item * L<Mail::Builder::Address>

Stores an e-mail address and a display name.

=item * Attachments: L<Mail::Builder::Attachment::File> and L<Mail::Builder::Attachment::Data>

This classes manage attachments which can be created either from files in the
filesystem or from data in memory.

=item * Inline images:L<Mail::Builder::Image>

The Mail::Builder::Image class manages images that should be displayed in the 
html e-mail body. (E<lt>img src="cid:imageid" /E<gt>)

=item * L<Mail::Builder::List>

Helper class for handling list of varoius items (recipient lists, attachment
lists, image lists)

=back

=head1 METHODS

=head2 Constructors

=head3 new

This is a simple constructor. It does not expect any parameters.

=cut


=head2 Public methods 

=head3 stringify

Returns the e-mail message as a string. This string can be passed to modules
like L<Email::Send>.

This method is just a shortcut to C<$mb-E<gt>build_message-E<gt>stringify>

=cut



=head3 build_message

 my $entity = $mb->build_message();
 
 # Print the entire message:
 $entity->print(\*STDOUT);
 
 # Stringify the entire message:
 print $entity->stringify; 

Returns the e-mail message as a L<MIME::Entity> object. You can mess around 
with the object, change parts, ... as you wish. 

Every time you call build_message the MIME::Entity object will be created, 
which can take some time if you are sending bulk e-mails. In 
order to increase the processing speed Mail::Builder::Attachment and
Mail::Builder::Image entities will be cached and only rebuilt if something 
has changed.

=cut



=head2 Accessors 

=head3 from, returnpath, reply, sender

These accessors set/return the from, sender and reply address as well as the
returnpath for bounced messages.

 $obj->from(EMAIL[,NAME])
 OR
 $obj->from(Mail::Builder::Address)

This accessor always returns a Mail::Builder::Address object. 

To change the attribute value you can either supply a L<Mail::Builder::Address> 
object or scalar parameters which will be passed to 
C<Mail::Builder::Address-E<gt>new>. (email address, and an optional display
name)

=cut


=head3 charset (DEPRECATED)

=cut



=head3 to, cc, bcc

 $obj->to(Mail::Builder::List)
 OR
 $obj->to(Mail::Builder::Address)
 OR
 $obj->to(EMAIL[,NAME])

This accessor always returns a L<Mail::Builder::List> object containing
L<Mail::Builder::Address> objects. 

To alter the values you can either

=over

=item * Manipulate the L<Mail::Builder::List> object (add, remove, ...)

=item * Supply a L<Mail::Builder::Address> object. This will reset the current
list and add the object to the list.

=item * Supply a L<Mail::Builder::List> object. The list object replaces the 
old one if the list types match

=item * Scalar values will be passed to C<Mail::Builder::Address-E<gt>new>. 
The returned object will be added to the object list.

=back

The L<Mail::Builder::List> package provides some basic methods for 
manipulating the list of recipients. e.g.

 $obj->to->add(EMAIL[,NAME])
 OR
 $obj->to->add(Mail::Builder::Address)

=cut


=head3 language

e-mail text language

=head3 messageid

Message ID of the e-mail. Read only and available only after the 
C<build_message> or C<stingify> methods have been called.

=head3 organization
 
Accessor for the name of the sender's organisation. This header field is not
part of the RFC 4021, however supported by many mailer applications.

=head3 priority

Priority accessor. Accepts values from 1 to 5. The default priority is 3.

=head3 subject

e-mail subject accessor. Must be specified.

=head3 htmltext

HTML mail body accessor.

=head3 mailer

Mailer name.

=head3 plaintext

Plaintext mail body accessor. This text will be autogenerated from htmltext
if not provided by the user and the C<autotext> option is not turned off. 
Simple formating (e.g. <strong>, <em>) will be converted to pseudo formating.

If you want to disable the autogeneration of plaintext parts set the 
L<autotext> accessor to a false value. However be aware that most spam 
enginges rate e-mail messages without a plaintext part as spam.

The following html tags will be transformed to simple markup:

=over

=item * I, EM

Italic text will be surrounded by underscores. (_italic text_)

=item * H1, H2, H3, ...

Two equal signs are prepended to headlines (== Headline)

=item * STRONG, B

Bold text will be marked by stars (*bold text*)

=item * HR

A horizontal rule is replaced with 60 dashes.

=item * BR

Single linebreak

=item * P, DIV

Two linebreaks

=item * IMG

Prints the alt text of the image (if any).

=item * A

Prints the link url surrounded by brackets ([http://myurl.com text])

=item * UL, OL

All list items will be indented with a tab and prefixed with a start 
(*) or an index number.

=item * TABLE, TR, TD, TH

Tables are converted into text using L<Text::Table>.

=back

=head3 attachment

 $obj->attachment(Mail::Builder::List)
 OR
 $obj->attachment(Mail::Builder::Attachment)
 OR
 $obj->attachment(PATH[,NAME,MIME])
 
This accessor always returns a Mail::Builder::List object. If you supply
a L<Mail::Builder::List> the list will be replaced.

If you pass a Mail::Builder::Attachment object or a scalar path (with an
optional name an mime type) the current list will be reset and the new 
attachment will be added.

The L<Mail::Builder::List> package provides some basic methods for 
manipulating the list of attachments.

If you want to append an additional attachment to the list use

 $obj->attachment->add(PATH[,NAME,MIME])
 OR
 $obj->attachment->add(Mail::Builder::Attachment)

=cut


=head3 image

 $obj->image(Mail::Builder::List)
 OR
 $obj->image(Mail::Builder::Image)
 OR
 $obj->image(PATH[,ID])
 
This accessor always returns a Mail::Builder::List object. If you supply
a L<Mail::Builder::List> the list will be replaced.

If you pass a Mail::Builder::Image object or a scalar path (with an
optional id) the current list will be reset and the new image will be added. 

The L<Mail::Builder::List> package provides some basic methods for 
manipulating the list of inline images.

If you want to append an additional attachment to the list use

 $obj->image->add(PATH[,ID])
 OR
 $obj->image->add(Mail::Builder::Image)

You can embed the image into the html mail body code by referencing the ID. If 
you don't provide an ID the lowercase filename without the file extension will
be used as the ID.

 <img src="cid:logo"/>

Only jpg, gif and png images may be added as inline images.

=cut









=head1 EXAMPLE

If you want to send multiple e-mail messages from one Mail::Builder object
(e.g. a solicited mailing to multiple recipients) you have to pay special
attention, or else you might end up with mixed contents and growing 
recipients lists.

 # Example for a mass mailing
 foreach my $recipient (@recipients) {
     $mb->to->reset; # Remove all recipients
     $mb->to->add($recipient); # Add current recipient
     
     # Alternatively you could use $mb->to($recipient); which has the
     # same effect as the two previous commands. Same applies to 'cc' and 'bcc'
     
     $mb->plaintext(undef);
     # Reset plaintext, otherwise it will not be autogenerated from htmltext
     # after the first run
     
     $mb->htmltext(qq[<h1>Hello $recipient!</h1> Text, yadda yadda! ]);
     
     my $mail = $mb->stringify();
     
     # Send $mail ... 
 }
 
=head1 IMPORTANT CHANGES 
 
From 1.10 on Mail::Builder only supports utf-8 charsets for mails. Supporting
multiple encodings turned out to be error prone and not necessary since all
modern mail clients support utf-8.

=head1 CAVEATS 

Watch out when sending Mail::Builder generated mails with 
L<Email::Send::SMTP>: The 'Return-Path' headers are ignored by the MTA 
since L<Email::Send::SMTP> uses the 'From' header for SMTP handshake. Postfix
(any maybe some other MTAs) overwrites the 'Return-Path' field in the data
with the e-mail used in the handshake ('From'). The behaviour of 
L<Email::Send::SMTP> may however be modified by replacing the 
C<get_env_sender> and C<get_env_recipients> methods. See L<Email::Send::SMTP>
for more details.

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-mail-builder@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Mail::Builder>.  
I will be notified, and then you'll automatically be notified of progress on 
your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 ACKNOWLEDGEMENTS 

This module was written for my old employer the Centre for Social Innovation
L<http://www.zsi.at> and is currently advanced by Revdev 
L<http://www.revdev.at>, a nice litte software company I run with Koki and 
Domm (L<http://search.cpan.org/~domm/>).

=head1 COPYRIGHT

Mail::Builder is Copyright (c) 2007,2008 Maroš Kollár.

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself as long it is not used for sending 
unsolicited mail (SPAM): 

 "Thou shalt not send SPAM with this module."

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

The L<Mime::Entity> module in the L<Mime::Tools> distribution.

Furthermore these modules are bing used for various tasks:

=over 

=item * L<Email::Valid> for validating e-mail addresses
=item * L<HTML::TreeBuilder> for parsing html and generating plaintext
=item * L<MIME::Types> for guessing attachment mime types
=item * L<Email::MessageID> for generating unique message IDs
=item * L<Encode> for encoding issues

=back

=cut

"Thou shalt not send SPAM with this module";