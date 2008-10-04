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

Mail::Builder::Image - Module for handling inline images

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $image = Mail::Builder::Image('/home/guybrush/invitation.gif');
  # Change CID
  $image->id('invitation_location');
  
  # Mail::Builder object
  $mb->image($image);
  OR
  $mb->image->add($image);
  
  # In the e-mail body
  <img src="cid:invitation_location" alt=""/>
  
=head1 DESCRIPTION

This is a simple module for handling inline images. The module needs the path 
to the file and optional an id which can be used to reference the file from
within the e-mail text.

=head1 METHODS

=head2 Constructor

=head3 new

 Mail::Builder::Image->new(PATH[,REFERENCE ID]);

Simple constructor

=cut

sub new {
	my $class = shift;
	
	my $obj = bless {
		path	=> undef,
		id		=> undef,
		cache	=> undef,
		type	=> undef,
	},$class;
	
	$obj->path(shift);
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
    
    unless ($obj->{'id'}) {
        $obj->{'id'} = $obj->{'path'};
        #$obj->{'id'} =~ s/(^[\/]+)$/$1/;
        $obj->{'id'} =~ s/^.+[\/\\]//;
        $obj->{'id'} =~ s/(.+)\.(JPE?G|GIF|PNG)$/$1/i;
    }

    $obj->{'cache'} = build MIME::Entity(
        Disposition     => 'inline',
        Type            => qq[image/$obj->{'type'}],
        Top             => 0,
        Id              => qq[<$obj->{'id'}>],
        Encoding        => 'base64',
        Path            => $obj->{'path'},
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
        return ($compare->{path} eq $obj->{path}) ? 1:0;
    } else {
        return ($compare eq $obj->{path}) ? 1:0;  
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

=head3 path

Accessor which takes/returns the path of the file on the filesystem. The file
must be readable. Only .jpeg, .jpg, .gif and .png files may be added.

=cut

sub path {
    my $obj = shift;
    if (@_) {
        $obj->{'path'} = shift;
        croak(q[Filename missing]) 
            unless ($obj->{'path'});
        croak(qq[Invalid file type: $obj->{'path'}]) 
            unless ($obj->{'path'} =~ /.(JPE?G|GIF|PNG)$/i);
        croak(qq[Could not find/open file: $obj->{'path'}]) 
            unless (-r $obj->{'path'});
         
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

