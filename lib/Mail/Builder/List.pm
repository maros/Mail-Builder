# ============================================================================
package Mail::Builder::List;
# ============================================================================

use Moose;
with qw(Mail::Builder::Role::TypeConstraints);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

has 'type' => (
    is          => 'ro',
    isa         => 'Mail::Builder::Type::Class',
    required    => 1,
);

has 'list' => (
    is          => 'rw',
    isa         => 'ArrayRef[Object]',
    default     => sub { return [] },
    trigger     => \&_check_list,
);

sub _check_list {
    my ($self,$value) = @_;
    
    my $type = $self->type;
    
    foreach my $element (@$value) {
        unless (blessed $element
            && $element->isa($type)) {
            die('NOT A '.$type)
        }
    }
}

around 'list' => sub {
    my $orig = shift;
    my $self = shift;
    
    my $result = $self->$orig(@_);
    
    return wantarray ? @{$result} : $result;
};

__PACKAGE__->meta->make_immutable;

sub _convert_item {
    my ($self) = shift;
    
    croak(qq[Params missing])
        unless scalar @_;
    
    my $type = $self->type;
    
    if (blessed($_[0])) {
        croak(qq[Invalid item added to list: Must be of $type]) 
            unless ($_[0]->isa($type));
        return $_[0];
    } else {
        my $object = $type->new(@_);
        croak(qq[Could not create $type object]) 
            unless (defined $object 
            && blessed $object 
            && $object->isa($type));
        
        return $object;
    }
}

sub convert {
    my ($class,@elements) = @_;
    
    my $elements_ref = (scalar @elements == 1 && ref $elements[0] eq 'ARRAY') ? 
        $elements[0] : \@elements;
    
    return $class->new(
        type    => ref($elements_ref->[0]),
        list    => $elements_ref,
    );
}

sub length {
    my ($self) = @_;
    my $list = $self->list;
    return scalar @$list;
}

sub join {
    my ($self,$join_string) = @_;
    
    return CORE::join $join_string, 
        grep { $_ }
        map { $_->serialize } 
        $self->list;
}

sub contains {
    my ($self,$compare) = @_;
    
    return 0 
        unless (defined $compare);
    
    foreach my $item ($self->list) {
        return 1 
            if (blessed($compare) && $item == $compare);
        return 1 
            if ($item->compare($compare));
    }
    return 0;
}

sub reset {
    my ($self) = @_;
    
    $self->list([]);
    
    return 1;
}

sub push {
    my ($self) = @_;
    
    return $self->add(@_);
}

sub remove {
    my ($self,$remove) = @_;
    
    my $list = $self->list;
    
    # No params: take last param
    unless (defined $remove) {
        return pop @{$list};
    # Element
    } else {
        my $new_list = [];
        my $old_value;
        my $index = 0;
        foreach my $item (@{$list}) {
            if (blessed($remove) && $item == $remove
                || ($remove =~ /^\d+$/ && $index == $remove)
                || $item->compare($remove)) {
                $remove = $item;
            } else {
                CORE::push(@{$new_list},$item);
            }
            $index ++;
        }
        $self->list($new_list);
        
        # Return old value
        return $remove
            if defined $remove;
    }
    return;
}

sub add {
    my ($self) = shift;
    
    my $item = $self->_convert_item(@_);
    
    unless ($self->contains($item)) {
        CORE::push(@{$self->list}, $item);
    }
    
    return $item;
}


sub item {
    my ($self,$index) = @_;
    
    $index //= 0;
    
    return 
        unless ($index =~ /^\d+$/ 
        && defined $self->list->[$index]);
    
    return $self->list->[$index];
}

#sub convert {
#    my $class = shift;
#    my $list_data = shift; 
#    croak(qq[Tried to convert an invalid value into a Mail::Builder::List object: Must be an array reference])
#        unless (ref $list_data eq 'ARRAY');
#    croak(qq[Tried to convert an empty list into a Mail::Builder::List object: List must hold at least one element])
#        unless (scalar @$list_data);
#    
#    my $list_type = ref $list_data->[0];
#    
#    croak(qq[Uanble to determine list type: List must hold objects])
#        unless ($list_type);
#    
#    foreach my $list_item (@{$list_data}) {
#        croak(qq[Tried to create a Mail::Builder::List object with mixed objects: Must be only of one type]) 
#            unless ref $list_item && $list_item->isa($list_type);
#    }
#    
#    my $obj = $class->new($list_type);
#    
#    foreach my $item (@$list_data) {
#        $obj->add($item);
#    }
#    return $obj;
#}

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

=head3 convert 

 my $list = Mail::Builder::List->convert(ARRAYREF);

Constructor that converts an array reference into a Mail::Builder::List 
object. The list type is defined by the first element of the array.

=cut



=head2 Public Methods

=head3 length 

Returns the number of items in the list.

=cut



=head3 add

 $obj->add(OBJECT);
 or
 $obj->add(SCALAR VALUE/S)

Pushes a new item into the list. The methods either accepts an object or 
scalar values. Scalar values will be passed to the C<new> method in the
list type class.

=cut


=head3 push

Synonym for L<add>

=cut



=head3 remove

 $obj->remove(OBJECT)
 or
 $obj->remove(SCALAR VALUE)
 or
 $obj->remove()

Removes the given element from the list. If no parameter is passed to the 
method the last element from the list will be removed instead.

=cut 





=head3 reset

Removes all elements from the list, leaving an empty list.

=cut




=head3 item

 my $list_item = $obj->item(INDEX)

Returns the list item with the given index.

=cut



=head3 join

 my $list = $obj->join(STRING)

Serializes all items in the list and joins them using the given string.

=cut



=head3 has

 $obj->has(OBJECT)
 or
 $obj->has(SCALAR VALUE)

Returns true if the given object is in the list. You can either pass an
object or scalar value. Uses the L<compare> method from the list type class.

=cut


=head2 Accessors

=head3 type

Returns the class name which was initially passed to the constructor. 

=cut



=head3 list

Raw list as list or array reference.

=cut



1;

__END__

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
