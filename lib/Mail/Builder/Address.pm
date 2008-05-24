# ================================================================
package Mail::Builder::Address;
# ================================================================
use strict;
use warnings;

use Carp;
use Encode qw/encode decode/; 
use Email::Valid;

use vars qw($VERSION);
$VERSION = $Mail::Builder::VERSION;

=encoding utf8
=head1 NAME

Mail::Builder::Address - Helper module for handling e-mail addresses

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $mail = Mail::Builder::Address->new('mightypirate@meele-island.mq','Gaybrush Thweedwood');
  # Now correct the display name and address
  $mail->name('Guybrush Threepwood');
  $mail->email('verymightypirate@meele-island.mq');
  # Serialize
  print $mail->serialize;
  
  # Use the address as a recipient for  Mail::Builder object
  $mb->to($mail); # This removes all other recipients 
  OR
  $mb->to->add($mail);

=head1 DESCRIPTION

This is a simple module for handling e-mail addresses. It can store the address
and an optional display name.

=head1 METHODS

=head2 Constructor

=head3 new

 Mail::Builder::Address->new(EMAIL[,DISPLAY NAME]);

Simple constructor

=cut

sub new {
	my $class = shift;
	my $obj = bless {
		email	=> undef,
		name	=> undef,
	},$class;
	
	$obj->email(shift);
	$obj->name(shift) if (@_);
	
	return $obj;
}

=head2 Public Methods

=head3 serialize

Prints the address as required for creating the e-mail header.

=cut

sub serialize {
    my $obj = shift;
    
    return undef 
        unless $obj->{email};
        
    return $obj->{email}
        unless $obj->{'name'};
          
    return '"'.encode('MIME-Header', $obj->{'name'}).'" <'.$obj->{email}.'>';
}

=head3 compare

 $obj->compare(OBJECT);
 or
 $obj->compare(E-MAIL);

Checks if two address objects contain the same e-mail address. Returns true 
or false. The compare method does not check if the address names of the
two objects are identical.

Instead of a C<Mail::Builder::Address> object you can also pass a 
scalar value representing the e-mail address.

=cut

sub compare {
    my $obj = shift;
    my $compare = shift;
    
    return 0 unless ($compare);
    
    if (ref($compare)) {
        return 0 unless $compare->isa(__PACKAGE__);
        return ($compare->{email} eq $obj->{email}) ? 1:0;
    } else {
        return ($compare eq $obj->{email}) ? 1:0;  
    }
}

=head3 empty

Deletes the current address/name values. Leaves an empy object

=cut

sub empty {
    my $obj = shift;
    undef $obj->{'name'};
    undef $obj->{'email'};
}


=head2 Accessors

=head3 name

Display name

=cut

sub name {
	my $obj = shift;
 	if(@_) {
		$obj->{'name'} = shift;
		return unless $obj->{'name'};
		$obj->{'name'} =~ s/\\/\\\\/g;
		$obj->{'name'} =~ s/"/\\"/g;
	}
	return $obj->{'name'};
}
	
=head3 email

E-mail address. Will be checked with L<Email::Valid>

=cut

sub email {
	my $obj = shift;
 	if(@_) {
		my $email_address = shift;
		croak(q[e-mail address missing]) unless ($email_address);
		croak(q[e-mail address is not valid]) unless (Email::Valid->address($email_address));
		$obj->{'email'} = $email_address;
	}
	return $obj->{'email'};
}

1;

__END__


=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
