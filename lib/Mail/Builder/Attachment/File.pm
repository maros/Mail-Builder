# ============================================================================
package Mail::Builder::Attachment::File;
# ============================================================================

use Moose;
extends qw(Mail::Builder::Attachment);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

sub BUILD {
    carp '<Mail::Builder::Attachment::File> is deprecated, use <Mail::Builder::Attachment> instead';
}

1;
