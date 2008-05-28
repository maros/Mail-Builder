# ================================================================
package Mail::Builder::Attachment::File;
# ================================================================
use strict;
use warnings;

use Carp;

use base qw(Mail::Builder::Attachment);

use Encode qw(encode decode); 

use vars qw($VERSION);
$VERSION = $Mail::Builder::VERSION;

use MIME::Types;

=encoding utf8

=head1 NAME

Mail::Builder::Attachment - Helper module for handling attachments from files

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $attachment = Mail::Builder::Attachment::File('/home/guybrush/2007_10_11_invitation.pdf','invitation.pdf','application/pdf');
  $attachment->name('party_invitation.pdf');
  print $attachment->serialize;
  
  # Append the attachment to an Mail::Builder object
  $mb->attachment($attachment); # this removes all other attachments
  OR
  $mb->attachment->add($mail);

=head1 DESCRIPTION

This is a simple module for handling attachments with Mail::Builder.

=head1 METHODS

=head2 Constructor

=head3 new

 my $obj = Mail::Builder::Attachment->new(PATH[,NAME,MIME]);
 
Takes the path to the attached file on the local filesystem. Optionally takes 
the file name as it should be diplayed in the e-mail message and a mime type. 

=cut

sub new {
    my $class = shift;
    
    my $obj = bless {
        path    => undef,
        name    => undef,
        mime    => undef,
        cache   => undef,
    },$class;
    
    $obj->path(shift || '');
    $obj->name(shift) if (@_);
    $obj->mime(shift) if (@_);
    
    return $obj;
}

=head2 Public methods

=head3 compare

 $obj->compara(OBJECT);
 or 
 $obj->compara(PATH);

Checks if two attachment objectscontain the same file. Returns true or false.
The compare method does not check if the mime types and name attributes of the
two objects are identical.

Instead of a C<Mail::Builder::Attachment::File> object you can also pass a 
scalar value representing the path.

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

=head3 serialize

Returns the attachment as a MIME::Entity object.

=cut

sub serialize {
    my $obj = shift;
    return $obj->{'cache'} if (defined $obj->{'cache'});
    croak(q[Filename missing]) unless ($obj->{'path'});
    
    $obj->_get_mime unless ($obj->{'mime'});
    $obj->_get_name unless ($obj->{'name'});
    
    
    $obj->{'cache'} = build MIME::Entity (
        Path        => $obj->{'path'},
        Type        => $obj->{'mime'},
        Top         => 0,
        Filename    => encode('MIME-Header', $obj->{'name'}),
        Encoding    => 'base64',
        Disposition => 'attachment',
    );
    return $obj->{'cache'};
}
=head2 Accessors

=head3 path

Accessor which takes/returns the path of the file on the filesystem. The file
must be readable by the current uid.

=head3 name

Accessor which takes/returns the name of the file as displayed in the e-mail
message. If no name is provided the filename will be extracted from the path
attribute.

=head3 mime

Accessor which takes/returns the mime type of the file. If no mime type is 
provided the module tries to determine the correct mime type for the given
filename extension. If this fails 'application/octet-stream' will be used.

=cut

sub path {
    my $obj = shift;
    if (@_) {
        $obj->{'path'} = shift;
        croak(qq[Could not find/open file: $obj->{'path'}]) unless (-r $obj->{'path'});
        undef $obj->{'cache'};
    }
    return $obj->{'path'};
}

=head3 Private methods

=head2 _get_mime

Try to determine the mime type by parsing the filename.

=cut

sub _get_mime {
    my $obj = shift;
    if ($obj->{'path'} =~ m/\.([a-zA-Z0-9]+)$/) {
        my $file_extension = $1;
        my $mimetypes = MIME::Types->new;
        $obj->{'mime'} = $mimetypes->mimeTypeOf($file_extension);
    }
    $obj->{'mime'} ||= 'application/octet-stream';
    undef $obj->{'cache'};
    return $obj->{'mime'};
}

=head2 _get_name

Fetch the e-mail filename from the path attribute.

=cut
    
sub _get_name {
    my $obj = shift;
    $obj->{'name'} = $obj->{'path'};
    $obj->{'name'} = $1 if ($obj->{'name'} =~ m/([^\\\/]+)$/);
    undef $obj->{'cache'};
    return $obj->{'name'};
}

1;

__END__


=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
