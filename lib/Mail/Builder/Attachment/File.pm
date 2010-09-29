# ============================================================================
package Mail::Builder::Attachment::File;
# ============================================================================

use Moose;
extends qw(Mail::Builder::Attachment);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

before BUILDARGS => sub{
    carp '<Mail::Builder::Attachment::File> is deprecated, use <Mail::Builder::Attachment> instead';
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
