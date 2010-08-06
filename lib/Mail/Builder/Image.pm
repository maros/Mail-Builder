# ============================================================================
package Mail::Builder::Image;
# ============================================================================

use Moose;
with qw(Mail::Builder::Role::File);
use Mail::Builder::Role::TypeConstraints;

use Carp;

our $VERSION = $Mail::Builder::VERSION;

has 'id' => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
    trigger     => sub { shift->clear_cache },
);

has 'mimetype' => (
    is          => 'rw',
    isa         => 'Mail::Builder::Type::ImageMimetype',
    lazy_build  => 1,
    trigger     => sub { shift->clear_cache },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( scalar @_ == 1 && ref $_[0] eq 'HASH' ) {
        return $class->$orig($_[0]);
    }
    else {
        my $params = {
            file    => $_[0],
        };
        if (defined $_[1]) {
            $params->{id} = $_[1];
        }
        if (defined $_[2]) {
            $params->{mimetype} = $_[2];
        }
        return $class->$orig($params);
    }
};

sub _build_mimetype {
    my ($self) = @_;
    
    my $filename = $self->filename;
    my $filetype;
    
    if (defined $filename
        && $filename->basename =~ m/\.(PNG|JPE?G|GIF)$/i) {
        $filetype = 'image/'.lc($1);
        $filetype = 'image/jpeg'
            if $filetype eq 'image/jpg';
    } else {
        my $filecontent = $self->filecontent;
        $filetype = $self->_check_magic_string($filecontent);
    }
    
    unless (defined $filetype) {
        return __PACKAGE__->_throw_error('Could not determine the file type automatically and/or invalid file type (only image/png, image/jpeg an image/gif allowed)');
    }
    
    return $filetype;
}

sub _build_id {
    my ($self) = @_;
    
    my $filename = $self->filename;
    my $id;
    
    if (defined $filename) {
        $id = $filename->basename;
        $id =~ s/[.-]/_/g;
        $id =~ s/(.+)\.(JPE?G|GIF|PNG)$/$1/i;
    }
    
    unless (defined $id
        && $id !~ m/^\s*$/) {
        return __PACKAGE__->_throw_error('Could not determine the image id automatically');
    }
    
    return $id;
}

sub serialize {
    my ($self) = @_;

    return $self->cache 
        if ($self->has_cache);
    
    my $file = $self->file;
    my $accessor;
    my $value;
    
    if (blessed $file) {
        if ($file->isa('IO::File')) {
            $accessor = 'Data';
            $value = $self->filecontent;
        } elsif ($file->isa('Path::Class::File')) {
            $accessor = 'Path';
            $value = $file->stringify;
        }
    } else {
        $accessor = 'Data';
        $value = $file;
    }
    
    my $entity = build MIME::Entity(
        Disposition     => 'inline',
        Type            => $self->mimetype,
        Top             => 0,
        Id              => '<'.$self->id.'>',
        Encoding        => 'base64',
        $accessor       => $value,
    );
    
    $self->cache($entity);
    
    return $entity;
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Mail::Builder::Image - Abstract class for handling inline images

=head1 SYNOPSIS

This is an abstract class. Please Use L<Mail::Builder::Image::Data> or
L<Mail::Builder::Image::Path>.
  
=head1 DESCRIPTION

This is a simple module for handling inline images. 


1;

__END__
=pod

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut

