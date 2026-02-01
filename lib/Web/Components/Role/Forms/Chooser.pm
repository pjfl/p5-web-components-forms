package Web::Components::Role::Forms::Chooser;

use namespace::autoclean;

use Class::Usul::Constants qw( FALSE NUL TRUE );
use Class::Usul::Functions qw( pad );
use App::MCP::Response::Table;
use Moo::Role;

# Private functions
my $_dots = sub { "\x{2026}" };

my $_new_grid_table = sub {
   my ($values, $label) = @_; $values //= [];

   return Class::Usul::Response::Table->new( {
      class    => { item     => 'grid_cell',
                    item_num => 'grid_cell lineNumber first', },
      count    => scalar @{ $values },
      fields   => [ 'item_num', 'item' ],
      hclass   => { item     => 'grid_header most',
                    item_num => 'grid_header minimal first', },
      labels   => { item     => $label // 'Select Item', item_num => chr 35, },
      typelist => { item_num => 'numeric', },
      values   => $values,
   } );
};

# Private methods
my $_new_grid_row = sub {
   my ($self, $req, $args, $rowid, $row) = @_;

   my $form     = $args->{form};
   my $method   = $args->{method};
   my $link_num = $args->{link_num};
   my $params   = $req->query_params;
   my $id       = $params->( 'id' );
   my $button   = $params->( 'button', { optional => TRUE } ) // NUL;
  (my $field    = $id) =~ s{ _grid \z }{}msx;
      $field    = (split m{ _ }mx, $field)[ 1 ];
   my $item     = $self->$method( $req, $args->{link_num}, $row );
   my $rv       = (delete $item->{value}) || $item->{text};
   my $iargs    = "[ '${form}', '${field}', '${rv}', '${button}' ]";

   $item->{class    } //= 'chooser_grid fade submit';
   $item->{config   }   = { args => $iargs, method => "'returnValue'", };
   $item->{container}   = FALSE;
   $item->{id       }   = "${id}_link${link_num}";
   $item->{type     }   = 'anchor';
   $item->{widget   }   = TRUE;

   return {
      class   => 'grid',
      classes => { item     => 'grid_cell',
                   item_num => 'grid_cell lineNumber first' },
      fields  => [ 'item_num', 'item' ],
      id      => $rowid,
      type    => 'tableRow',
      values  => { item => $item, item_num => $link_num + 1, }, };
};

# Public methods
sub build_chooser {
   my ($self, $req, $args) = @_; my $params = $req->query_params; $args //= {};

   my $form    = $params->( 'form'  );
   my $field   = $params->( 'field' );
   my $button  = $params->( 'button', { optional => TRUE } ) // NUL;
   my $event   = $params->( 'event',  { optional => TRUE } ) || 'load';
   my $p_opts  = { optional => TRUE }; $args->{scrubber}
      and $p_opts->{scrubber} = $args->{scrubber};
   my $fval    = $params->( 'val', $p_opts ) // NUL;
   my $toggle  = $params->( 'toggle', { optional => TRUE } ) ? 'true' : 'false';
   my $show    = "function() { this.window.dialogs[ '${field}' ].show() }";
   my $id      = "${form}_${field}";

   $fval =~ s{ [\*] }{%}gmx;

   return {
      'meta'    => { id => $params->( 'id' ) },
      $id       => {
         id     => $id,
         config => { button     => "'${button}'",
                     event      => "'${event}'",
                     fieldValue => "'${fval}'",
                     gridToggle => $toggle,
                     onComplete => $show }, } };
}

sub build_chooser_rows {
   my ($self, $req, $args) = @_; my $params = $req->query_params;

   my $id        = $params->( 'id'        );
   my $page      = $params->( 'page'      ) || 0;
   my $page_size = $params->( 'page_size' ) || 10;
   my $start     = $page * $page_size;
   my $rows      = {};
   my $count     = 0;

   for my $row (@{ $args->{values} }) {
      $args->{link_num} = $start + $count;

      my $rowid  = 'row_'.(pad $args->{link_num}, 5, 0, 'left');

      $rows->{ $rowid } = $self->$_new_grid_row( $req, $args, $rowid, $row );
      $count++;
   }

   $rows->{meta} = { count => $count, id => "${id}${start}", offset => $start };

   return $rows;
}

sub build_chooser_table {
   my ($self, $req, $args) = @_; my $params = $req->query_params;

   my $form   = $args->{form};
   my $field  = $params->( 'id' );
   my $psize  = $params->( 'page_size' ) || 10;
   my $p_opts = { optional => TRUE }; $args->{scrubber}
      and $p_opts->{scrubber} = $args->{scrubber};
   my $fval   = $params->( 'field_value', $p_opts ) // NUL;
   my $label  = $req->loc( $args->{label} );
   my $id     = "${form}_${field}";
   my $count  = 0;
   my @values = ();

   while ($count < $args->{total} && $count < $psize) {
      push @values, { item => $_dots->(), item_num => ++$count, };
   }

   return {
      'meta'         => {
         id          => $id,
         field_value => $fval,
         totalcount  => $args->{total}, },
      "${id}_header" => {
         id          => "${id}_header",
         text        => $req->loc( 'Loading' ).$_dots->(), },
      "${id}_grid"   => {
         id          => "${id}_grid",
         data        => $_new_grid_table->( \@values, $label ), },
   };
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Role::Forms::Chooser - Helper methods for record choosing widget

=head1 Synopsis

   package YourApp::Model::YourModel;

   use Moo;

   with 'Web::Components::Role::Forms::Chooser';

=head1 Description

Helper methods to create a chooser widget that performs paged queries with
a scroll buffer which permits the selection of a desired record

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<build_chooser>

   my $chooser = $self->build_chooser( $req );
   my $page    = { meta => delete $chooser->{meta} };
   my $stash   = $self->get_stash( $req, $page, 'chooser_form' => $chooser );

The hash reference that this method returns is used as the value of the
C<source> attribute in the call to L<Web::Components::Forms>'s constructor

The C<chooser_form> should define a single widget of type C<chooser>

=head2 C<build_chooser_rows>

   my $rows  = $self->build_chooser_rows( $req, $args );
   my $page  = { meta => delete $rows->{meta} };
   my $stash = $self->get_stash( $req, $page, 'grid_rows_form' => $rows );

The hash reference that this method returns is used as the value of the
C<source> attribute in the call to L<Web::Components::Forms>'s constructor

The C<grid_rows_form> defines no widgets

=head2 C<build_chooser_table>

   my $table = $self->build_chooser_table( $req, $args );
   my $page  = { meta => delete $table->{meta} };
   my $stash = $self->get_stash( $req, $page, 'grid_table_form' => $table );

The hash reference that this method returns is used as the value of the
C<source> attribute in the call to L<Web::Components::Forms>'s constructor

The C<grid_table_form> should define widgets for both C<header> and C<grid>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moo::Role>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Role-Forms.
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
