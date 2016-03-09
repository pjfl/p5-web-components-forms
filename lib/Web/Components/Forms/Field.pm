package Web::Components::Forms::Field;

use namespace::autoclean;

use Class::Usul::Constants qw( NUL TRUE );
use Class::Usul::Functions qw( first_char );
use Class::Usul::Types     qw( HashRef );
use Moo;

# Public attributes
has 'properties' => is => 'ro', isa => HashRef, required => TRUE;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, $conf, $form_name, $field_name) = @_;

   my $fqfn  = first_char $field_name eq '+'
             ? substr $field_name, 1 : "${form_name}.${field_name}";
   my $props = { %{ $conf->{ $fqfn } // {} } }; $field_name =~ s{ \A \+ }{}mx;

   exists $props->{name} or $props->{name} = $field_name;
   exists $props->{form} or exists $props->{group} or exists $props->{widget}
       or $props->{widget} = TRUE;

   return { properties => $props };
};

# Private methods
my $_key_attribute = sub {
   my $self = shift; my $type = $self->properties->{type} // NUL;

   return $type eq 'button'  ? 'name'
        : $type eq 'chooser' ? 'href'
        : $type eq 'label'   ? 'text'
        : $type eq 'tree'    ? 'data'
                             : 'default';
};

# Public methods
sub add_properties {
   my ($self, $v) = @_; my $props = $self->properties;

   $props->{ $_ } = $v->{ $_ } for (keys %{ $v });

   return;
}

sub value {
   my ($self, $v) = @_;

   defined $v and return $self->properties->{ $self->$_key_attribute } = $v;

   return $self->properties->{ $self->$_key_attribute };
}

sub name {
   return $_[ 0 ]->properties->{name};
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Forms::Field - Represents a single field on a form

=head1 Synopsis

   use Web::Components::Forms::Field;

   my $field = Web::Components::Forms::Field->new( $field_config, $form_name, $field_name );

=head1 Description

Represents a single field on a form

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<properties>

An immutable required hash reference. The field properties

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Sets the fields property attributes from the passed configuration

=head2 C<add_properties>

Adds the keys and values passed to the L</properties> attribute

=head2 C<value>

For each properties C<type> attribute value there is a key attribute. This
method is an accessor / mutator for that property attribute value

=head2 C<name>

Returns the properties C<name> attribute

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Forms.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
