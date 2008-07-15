# ================================================================
package Mail::Builder::Attachment::Data;
# ================================================================
use strict;
use warnings;

use Carp;

use base qw(Mail::Builder::Attachment);

use Encode qw(encode decode); 

use vars qw($VERSION);
$VERSION = $Mail::Builder::VERSION;

=encoding utf8

=head1 NAME

Mail::Builder::Attachment::Data - Helper module for handling attachments from data

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $attachment = Mail::Builder::Attachment::Data($data,'invitation.pdf','application/pdf');
  $attachment->name('party_invitation.pdf');
  print $attachment->serialize;
  
  # Append the attachment to an Mail::Builder object
  $mb->attachment($attachment); # this removes all other attachments
  OR
  $mb->attachment->add($mail);
  
=head1 DESCRIPTION

This module allows you to add attachments from data.

=head1 METHODS

=head2 Constructor

=head3 new

 my $obj = Mail::Builder::Attachment::Data->new(CONTENT,NAME,MIME);
 
Takes the data ,the file name as it should be diplayed in the e-mail message 
and a mime type. 

=cut

sub new {
    my $class = shift;

    my $obj = bless {
        data    => undef,
        name    => undef,
        mime    => undef,
        cache   => undef,
    },$class;
    
    $obj->data(shift || '');
    $obj->name(shift || '');
    $obj->mime(shift || '');
    
    return $obj;
}

=head2 Public methods

=head3 compare

 $obj->compara(OBJECT);
 or 
 $obj->compara(DATA);

Checks if two attachment objects contains the same data. Returns true or 
false. The compare method does not check if the mime types and name attributes
of the two objects are identical.

Instead of a C<Mail::Builder::Attachment::Data> object you can also pass a 
scalar value representing the data.

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

=head3 serialize

Returns the attachment as a MIME::Entity object.

=cut

sub serialize {
    my $obj = shift;
    return $obj->{'cache'} if (defined $obj->{'cache'});
    croak(q[Data missing]) unless ($obj->{'data'});
    croak(q[Mime type missing]) unless ($obj->{'mime'});
    croak(q[File name missing]) unless ($obj->{'name'});

    $obj->{'cache'} = build MIME::Entity (
        Data        => $obj->{'data'},
        Type        => $obj->{'mime'},
        Top         => 0,
        Filename    => encode('MIME-Header', $obj->{'name'}),
        Encoding    => 'base64',
        Disposition => 'attachment',
    );
    return $obj->{'cache'};
}
=head2 Accessors

=head3 data

Accessor which takes/returns the data. 

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

sub data {
    my $obj = shift;
    if (@_) {
        $obj->{'data'} = shift;
        undef $obj->{'cache'};
    }
    return $obj->{'data'};
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
