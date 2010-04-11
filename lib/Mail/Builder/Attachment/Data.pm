# ============================================================================
package Mail::Builder::Attachment::Data;
# ============================================================================

use Moose;
extends qw(Mail::Builder::Attachment);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

sub BUILD {
    carp '<Mail::Builder::Attachment::Data> is deprecated, use <Mail::Builder::Attachment> instead';
}

1;
