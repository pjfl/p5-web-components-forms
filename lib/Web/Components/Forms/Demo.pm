package Web::Components::Forms::Demo;

use namespace::autoclean;

use HTTP::Status qw( HTTP_OK );
use Moo;

with 'Web::Components::Role';
with 'Web::Components::Role::Forms';

has '+moniker' => default => 'demo';

sub get_stash {
   my ($self, $req, $page) = @_; my $stash = $self->initialise_stash( $req );

   $stash->{page} = $self->load_page( $req, $page );

   return $stash;
}

sub initialise_stash {
   return { code => HTTP_OK, skin => 'default', view => 'HTML', };
}

sub load_page {
   my ($self, $req, $page) = @_; $page //= {}; return $page;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Forms::Demo - Demonstrate the form handler

=head1 Synopsis

   package YourApp::Model::YourModel;

   use Moo;

   with 'Web::Components::Role::Forms';
   with 'Web::Components::Role::Forms::Demo';

=head1 Description

Demonstrate the form handler

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

=head2 C<get_stash>

=head2 C<initialise_stash>

=head2 C<load_page>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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

Copyright (c) 2015 Peter Flanigan. All rights reserved

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
