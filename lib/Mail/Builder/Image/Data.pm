# ================================================================
package Mail::Builder::Image::Data;
# ================================================================
use strict;
use warnings;

use Carp;

use parent qw(Mail::Builder::Image);

our $VERSION = $Mail::Builder::VERSION;

=encoding utf8

=head1 NAME

Mail::Builder::Image::Data - Module for handling inline images from data

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $image = Mail::Builder::Image::Data->new($data,'invitation');
  # Change CID
  $image->id('invitation_location');
  
  # Mail::Builder object
  $mb->image($image);
  OR
  $mb->image->add($image);
  
  # In the e-mail body
  <img src="cid:invitation_location" alt=""/>
  
=head1 DESCRIPTION

This is a simple module for handling inline images. The module needs the 
image content and an id which can be used to reference the file from
within the e-mail text.

=head1 METHODS

=head2 Constructor

=head3 new

 Mail::Builder::Image::Data->new(PATH,REFERENCE ID);

Simple constructor

=cut

sub new {
    my $class = shift;
    
    my $obj = bless {
        data    => undef,
        id      => undef,
        cache   => undef,
        type    => undef,
    },$class;
    
    $obj->data(shift);
    $obj->id(shift) if (@_);
    
    return $obj;
}

=head2 Public Methods

=head3 serialize

Returns the image as a MIME::Entity object. 

=cut

sub serialize {
    my $obj = shift;
    return $obj->{'cache'} if (defined $obj->{'cache'});
    
    croak(q[Data missing]) unless ($obj->{'data'});
    croak(q[ID missing]) unless ($obj->{'id'});

    $obj->{'cache'} = build MIME::Entity(
        Disposition     => 'inline',
        Type            => qq[image/$obj->{'type'}],
        Top             => 0,
        Id              => qq[<$obj->{'id'}>],
        Encoding        => 'base64',
        Data            => $obj->{'data'},
    );
}

=head3 compare

 $obj->compare(OBJECT);
 or
 $obj->compare(PATH);

Checks if two image objects contain the same file. Returns true 
or false. The compare method does not check if the image id of the
two objects are identical.

Instead of a C<Mail::Builder::Image> object you can also pass a 
scalar value representing the image path .

=cut

sub compare {
    my $obj = shift;
    my $compare = shift;
    
    return 0 unless ($compare);
    
    if (ref($compare)) {
        return 0 unless $compare->isa(__PACKAGE__);
        return ($compare->{data} eq $obj->{data}) ? 1:0;
    } else {
        return ($compare eq $obj->{data}) ? 1:0;  
    }
}

=head2 Accessors

=head3 id

Accessor which takes/returns the id of the file. If no id is provided the 
lowercase filename without the extension will be used as the id.

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

=head3 data

Accessor which takes/returns the content of the image. Only .jpeg, .jpg, 
.gif and .png files may be added.

=cut

sub data {
    my $obj = shift;
    if (@_) {
        $obj->{'data'} = shift;
        # GIF: 47 49 46 38 39 61
        # JPEG: FF D8
        # PNG: 89 50 4E 47 0D 0A
        
        
         
        $obj->{'cache'} = undef;
        $obj->{'type'} = lc($1);
        $obj->{'type'} =~ s/^jpe?g?$/jpeg/;
    }
    return $obj->{'path'};
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

