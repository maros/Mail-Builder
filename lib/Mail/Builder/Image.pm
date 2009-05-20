# ================================================================
package Mail::Builder::Image;
# ================================================================
use strict;
use warnings;

use Carp;

use vars qw($VERSION);
$VERSION = $Mail::Builder::VERSION;

=encoding utf8

=head1 NAME

Mail::Builder::Image - Abstract class for handling inline images

=head1 SYNOPSIS

This is an abstract class. Please Use L<Mail::Builder::Image::Data> or
L<Mail::Builder::Image::Path>.
  
=head1 DESCRIPTION

This is a simple module for handling inline images. 

=head1 METHODS

=head2 Constructor

=head3 new

Shortcut to the constructor from L<Mail::Builder::Image::File>.

=cut

sub new {
    my $class = shift;
    
    return Mail::Builder::Image::File->new(@_);
}

=head2 Accessors

=head3 id

Accessor which takes/returns the id of the file. 

The id is needed to reference the image in the e-mail body:
 <img src="cid:invitation_location" alt=""/>

=cut 

sub id {
    my $obj = shift;
    if (@_) {
        $obj->{'id'} = shift;
        $obj->{'cache'} = undef;
    }
    return $obj->{'id'};
}

1;

__END__
=pod

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut

