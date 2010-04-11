# ============================================================================
package Mail::Builder::Image::Data;
# ============================================================================

use Moose;
extends qw(Mail::Builder::Image);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

sub BUILD {
    carp '<Mail::Builder::Image::Data> is deprecated, use <Mail::Builder::Image> instead';
}

__PACKAGE__->meta->make_immutable;


1;