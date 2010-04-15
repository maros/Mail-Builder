# ============================================================================
package Mail::Builder::Role::TypeConstraints;
# ============================================================================

our $VERSION = $Mail::Builder::VERSION;

use Moose::Role;
use Moose::Util::TypeConstraints;

# Simple types

subtype 'Mail.Builder.EmailAddress'
    => as 'Str'
    => where { 
        Email::Valid->address( 
            -address => $_,
            -tldcheck => 1 
        );
    }
    => message { "'$_' is not a valid e-mail address" };

subtype 'Mail.Builder.Class'
    => as 'Str'
    => where { m/^Mail::Builder::(.+)$/ && Class::MOP::is_class_loaded($_) }
    => message { "'$_' is not a  Mail::Builder::* class" };

subtype 'Mail.Builder.Priority'
    => as enum([qw(1 2 3 4 5)]);

subtype 'Mail.Builder.ImageMimetpe'
    => as enum([qw(image/gif image/jpeg image/png)]);

subtype 'Mail.Builder.Mimetype'
    => as 'Str'
    => where { m/^(image|message|text|video|x-world|application|audio|model|multipart)\/[^\/]+$/ }
    => message { "'$_' is not a valid MIME-type" };

# Class types

subtype 'Mail.Builder.Address'
    => as class_type('Mail::Builder::Address');

subtype 'Mail.Builder.AddressList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Address' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Address" };

coerce 'Mail.Builder.AddressList'
    => from 'Mail.Builder.Address'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ $_ ] ) }
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

subtype 'Mail.Builder.Attachment'
    => as class_type('Mail::Builder::Attachment');

subtype 'Mail.Builder.AttachmentList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Attachment' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Attachment" };

coerce 'Mail.Builder.AttachmentList'
    => from class_type('Mail::Builder::Attachment')
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => [ $_ ] ) }
    => from 'ArrayRef'
    => via { 
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Attachment')) {
                push(@{$result},$element);
            } else {
                push(@{$result},Mail::Builder::Attachment->new(file => $element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => $result ) 
    };

subtype 'Mail.Builder.Image'
    => as class_type('Mail::Builder::Image');

subtype 'Mail.Builder.ImageList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Image' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Image" };

coerce 'Mail.Builder.ImageList'
    => from class_type('Mail::Builder::Image')
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Image', list => [ $_ ] ) }
    => from 'ArrayRef'
    => via { 
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Image')) {
                push(@{$result},$element);
            } else {
                push(@{$result},Mail::Builder::Image->new(file => $element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Image', list => $result ) 
    };

1;