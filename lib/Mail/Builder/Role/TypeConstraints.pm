# ============================================================================
package Mail::Builder::Role::TypeConstraints;
# ============================================================================

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use Path::Class::File;

our $VERSION = $Mail::Builder::VERSION;

eval {
    Class::MOP::load_class('Net::Domain::TLD');
};
our $TLDCHECK = ($@) ? 0:1;

# Simple types

subtype 'Mail::Builder::Type::Content'
    => as 'ScalarRef';

subtype 'Mail::Builder::Type::File'
    => as class_type('Path::Class::File')
    => where { -f $_ && -r _ }
    => message { "Could not open file '$_'" };

subtype 'Mail::Builder::Type::Fh'
    => as class_type('IO::File');
    
coerce 'Mail::Builder::Type::Fh'
    => from 'GlobRef'
    => via { 
        return bless($_,'IO::File'); 
    };

coerce 'Mail::Builder::Type::File'
    => from 'Str'
    => via { 
        return Path::Class::File->new($_)
    };

subtype 'Mail::Builder::Type::EmailAddress'
    => as 'Str'
    => where {
        Email::Valid->address( 
            -address => $_,
            -tldcheck => $TLDCHECK 
        );
    }
    => message { "'$_' is not a valid e-mail address" };

subtype 'Mail::Builder::Type::Class'
    => as 'Str'
    => where { m/^Mail::Builder::(.+)$/ && Class::MOP::is_class_loaded($_) }
    => message { "'$_' is not a  Mail::Builder::* class" };

subtype 'Mail::Builder::Type::Priority'
    => as enum([qw(1 2 3 4 5)]);

subtype 'Mail::Builder::Type::ImageMimetype'
    => as enum([qw(image/gif image/jpeg image/png)])
    => message { "'$_' is not a valid image MIME-type" };


subtype 'Mail::Builder::Type::Mimetype'
    => as 'Str'
    => where { m/^(image|message|text|video|x-world|application|audio|model|multipart)\/[^\/]+$/ }
    => message { "'$_' is not a valid MIME-type" };

# Class types

subtype 'Mail::Builder::Type::Address'
    => as class_type('Mail::Builder::Address');

subtype 'Mail::Builder::Type::AddressList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Address' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Address" };

coerce 'Mail::Builder::Type::AddressList'
    => from 'Mail::Builder::Type::Address'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ $_ ] ) }
    => from 'Str'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ Mail::Builder::Address->new($_) ] ) }
    => from 'HashRef'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ Mail::Builder::Address->new($_) ] ) }
    => from class_type('Email::Address')
    => via { 
        return Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [
            Mail::Builder::Address->new($_)
        ] ) 
    }
    => from 'ArrayRef'
    => via { 
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Address')) {
                push(@{$result},$element);
            } else {
                push(@{$result},Mail::Builder::Address->new($element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Address', list => $result ) 
    };

subtype 'Mail::Builder::Type::Attachment'
    => as class_type('Mail::Builder::Attachment');

subtype 'Mail::Builder::Type::AttachmentList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Attachment' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Attachment" };

coerce 'Mail::Builder::Type::AttachmentList'
    => from class_type('Mail::Builder::Attachment')
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => [ $_ ] ) }
    => from 'HashRef'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => [ Mail::Builder::Attachment->new($_) ] ) }
    => from 'ArrayRef'
    => via { 
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Attachment')) {
                push(@{$result},$element);
            } elsif (ref $element eq 'HASH') {
                push(@{$result},Mail::Builder::Attachment->new($element));
            } else {
                push(@{$result},Mail::Builder::Attachment->new(file => $element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => $result ) 
    };

subtype 'Mail::Builder::Type::Image'
    => as class_type('Mail::Builder::Image');

subtype 'Mail::Builder::Type::ImageList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Image' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Image" };

coerce 'Mail::Builder::Type::ImageList'
    => from class_type('Mail::Builder::Image')
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Image', list => [ $_ ] ) }
    => from 'HashRef'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Image', list => [ Mail::Builder::Image->new($_) ] ) }
    => from 'ArrayRef'
    => via { 
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Image')) {
                push(@{$result},$element);
            } elsif (ref $element eq 'HASH') {
                push(@{$result},Mail::Builder::Image->new($element));
            } else {
                push(@{$result},Mail::Builder::Image->new(file => $element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Image', list => $result ) 
    };

no Moose::Role;
no Moose::Util::TypeConstraints;

1;