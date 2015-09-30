package Web::Components::Role::Forms::View;

use namespace::autoclean;

use HTML::FormWidgets;
use Scalar::Util qw( blessed );
use Moo::Role;

requires qw( serialize );

around 'serialize' => sub {
   my ($orig, $self, $req, $stash) = @_;

   if (exists $stash->{form} and blessed $stash->{form}) {
      my $widgets = HTML::FormWidgets->build( $stash->{form} );

      $stash->{page}->{literal_js} = $stash->{form}->{literal_js};
      $stash->{form} = $widgets;
   }

   return $orig->( $self, $req, $stash );
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Role::Forms::View - Renders the form as HTML

=head1 Synopsis

   package YourApp::View::HTML;

   use Moo;

   with 'Web::Components::Role::Forms::View';

=head1 Description

Renders the form as HTML

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<serialize>

   $plack_response = $self->serialize( $req, $stash );

Modifies the method in the consuming class. Detects the presence of a
L<Web::Components::Forms> in the stash an renders it by passing it to
L<HTML::FormWidgets>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::FormWidgets>

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
