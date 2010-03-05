# ================================================================
package Mail::Builder::List;
# ================================================================
use strict;
use warnings;

use Carp;

use vars qw($VERSION);
$VERSION = $Mail::Builder::VERSION;

=encoding utf8

=head1 NAME

Mail::Builder::List - Helper module for handling various lists 

=head1 SYNOPSIS

  use Mail::Builder;
  
  # Create a list that accepts Mail::Builder::Address objects
  my $list = Mail::Builder::List->new('Mail::Builder::Address');
  $list->add($address_object);
  $list->add($another_address_object);
  $list->reset;
  $list->add($email,$name);
  print $list->join(',');

=head1 DESCRIPTION

This is a helper module for handling various lists (e.g. recipient, attachment
lists). The class contains convinient array/list handling functions.

=head1 METHODS

=head2 Constructor 

=head3 new 

 my $list = Mail::Builder::List->new(CLASSNAME);

This constructor takes the class name of the objects it should hold. It is 
only possible to add objects of the given type. It is not possible to change
the assigned type later.

=cut

sub new {
    my $class = shift;
    my $list_type = shift || 'Mail::Builder::Address';
    
    my $obj = bless {
        type    => $list_type,
        list    => [],
    },$class;
    bless $obj,$class;
    return $obj;
}

=head3 convert 

 my $list = Mail::Builder::List->convert(ARRAYREF);

Constructor that converts an array reference into a Mail::Builder::List 
object. The list type is defined by the first element of the array.

=cut

sub convert {
    my $class = shift;
    my $list_data = shift; 
    croak(qq[Tried to convert an invalid value into a Mail::Builder::List object: Must be an array reference])
        unless (ref $list_data eq 'ARRAY');
    croak(qq[Tried to convert an empty list into a Mail::Builder::List object: List must hold at least one element])
        unless (scalar @$list_data);
    
    my $list_type = ref $list_data->[0];
    
    croak(qq[Uanble to determine list type: List must hold objects])
        unless ($list_type);
    
    foreach my $list_item (@{$list_data}) {
        croak(qq[Tried to create a Mail::Builder::List object with mixed objects: Must be only of one type]) 
            unless ref $list_item && $list_item->isa($list_type);
    }
    
    my $obj = $class->new($list_type);
    
    foreach my $item (@$list_data) {
        $obj->add($item);
    }
    return $obj;
}

=head2 Public Methods

=head3 length 

Returns the number of items in the list.

=cut

sub length {
    my $obj = shift;
    return scalar @{$obj->{'list'}};
}

=head3 add

 $obj->add(OBJECT);
 or
 $obj->add(SCALAR VALUE/S)

Pushes a new item into the list. The methods either accepts an object or 
scalar values. Scalar values will be passed to the C<new> method in the
list type class.

=cut

sub add {
    my $obj = shift;
    my $value = shift;
    if (ref($value)) {
        croak(qq[Invalid item added to list: Must be of $obj->{'type'}]) 
            unless ($value->isa($obj->{'type'}));
        
        push @{$obj->{'list'}}, $value;
    } else {
        my $object = $obj->{'type'}->new($value,@_);
        return 0 unless ($object 
            && ref $object 
            && $object->isa($obj->{'type'}));
        push @{$obj->{'list'}}, $object;
    }
    
    return 1;
}

=head3 push

Synonym for L<add>

=cut

sub push {
    my $obj = shift;
    return $obj->add(@_);
}

=head3 remove

 $obj->remove(OBJECT)
 or
 $obj->remove(SCALAR VALUE)
 or
 $obj->remove()

Removes the given element from the list. If no parameter is passed to the 
method the last element from the list will be removed instead.

=cut 

sub remove {
    my $obj = shift;
    my $value = shift;
    unless ($value) {
        pop @{$obj->{'list'}};
    } else {
        my $new_list = [];
        foreach my $item (@{$obj->{list}}) {
            next if (ref($value) && $item == $value);
            next if ($item->compare($value));
            CORE::push @{$new_list},$item;
        }
        $obj->{'list'} = $new_list;
    }
    return 1;
}

=head3 reset

Removes all elements from the list, leaving an empty list.

=cut

sub reset {
    my $obj = shift;
    $obj->{'list'} = [];
    return 1;
}


=head3 item

 my $list_item = $obj->item(INDEX)

Returns the list item with the given index.

=cut

sub item {
    my $obj = shift;
    my $index = shift || 0;
    return unless (defined $obj->{'list'}[$index]);
    return $obj->{'list'}[$index];
}

=head3 join

 my $list = $obj->join(STRING)

Serializes all items in the list and joins them using the given string.

=cut

sub join {
    my $obj = shift;
    my $join_string = shift || ','; 
    return CORE::join $join_string, 
        grep { $_ }
        map { $_->serialize } 
        @{$obj->{'list'}};
}

=head3 has

 $obj->has(OBJECT)
 or
 $obj->has(SCALAR VALUE)

Returns true if the given object is in the list. You can either pass an
object or scalar value. Uses the L<compare> method from the list type class.

=cut

sub has {
    my $obj = shift;
    my $compare = shift;
    
    return 0 unless ($compare);
    foreach my $item (@{$obj->{list}}) {
        return 1 if ($item == $compare);
        return 1 if ($item->compare($compare));
    }
    return 0;
}

=head2 Accessors

=head3 type

Returns the class name which was initially passed to the constructor. 

=cut

sub type {
    my $obj = shift;
    return $obj->{'type'};
}

=head3 list

Raw list as list or array reference.

=cut

sub list {
    my $obj = shift;
    return wantarray ? @{$obj->{'list'}} : $obj->{'list'};
}


1;

__END__

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
