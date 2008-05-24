# ================================================================
package Mail::Builder::Attachment;
# ================================================================
use strict;
use warnings;

use Carp;

use vars qw($VERSION);
$VERSION = $Mail::Builder::VERSION;

=encoding utf8
=head1 NAME

Mail::Builder::Attachment - Helper module for handling attachments

=head1 SYNOPSIS

This is an abstract class. Please Use L<Mail::Builder::Attachment::Data> or
L<Mail::Builder::Attachment::Path>.
  
=head1 DESCRIPTION

This is a simple module for handling attachments with Mail::Builder.

=head1 METHODS

=head2 Constructor

Shortcut to the constructor from L<Mail::Builder::Attachment::File>.

=cut

sub new {
    my $class = shift;
    
    return Mail::Builder::Attachment::File->new(@_);
}

=head2 Accessors

=head3 name

Accessor which takes/returns the name of the file as displayed in the e-mail
message.

=head3 mime

Accessor which takes/returns the mime type of the file. 

=cut

sub name {
    my $obj = shift;
    if (@_) {
        $obj->{'name'} = shift;
        undef $obj->{'cache'};
    }
    return $obj->{'name'};
}

sub mime {
    my $obj = shift;
    if (@_) {
        $obj->{'mime'} = shift;
        croak(q[Invalid mime type]) unless ($obj->{'mime'} =~ /^[a-z]+\/[a-z0-9.-]+$/);
        undef $obj->{'cache'};
    }
    return $obj->{'mime'};
}


1;

__END__


=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut

