package Web::Components::Role::Forms;

use namespace::autoclean;

use Class::Usul::Constants qw( TRUE );
use Class::Usul::Functions qw( ensure_class_loaded first_char );
use Data::Validation;
use HTTP::Status           qw( HTTP_OK );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Web::Components::Forms;
use Moo::Role;

requires qw( log );

# Construction
around 'get_stash' => sub {
   my ($orig, $self, $req, $page, $form_name, $source) = @_;

   my $stash  =  $orig->( $self, $req, $page ); $form_name or return $stash;
   my $form   =  Web::Components::Forms->new( {
      model   => $self,
      name    => $form_name,
      request => $req,
      skin    => $stash->{skin},
      source  => $source, } );

   $stash->{form} = $form;
   $stash->{page}->{first_field} = $form->first_field;
   $stash->{page}->{js_object  } = $form->js_object;
   $stash->{page}->{layout     } = $form->template;

   return $stash;
};

# Private package variables
my $_result_class_cache = {};

# Private functions
my $_set_column = sub {
   my ($obj, $args, $row, $col) = @_;

   my $prefix = $args->{method};
   my $method = $prefix ? "${prefix}${col}" : undef;
   my $value  = $method && $obj->can( $method )
              ? $obj->$method( $args->{params} )
              : $args->{params}->( $col, { optional => TRUE, raw => TRUE } );

   defined $value or return;

   if (blessed $row) { $row->$col( "${value}" ) }
   else { $row->{ $col } = "${value}" }

   return;
};

# Private methods
my $_check_field = sub {
   my ($self, $req, $class_base) = @_;

   my $params   = $req->query_params;
   my $domain   = $params->( 'domain' );
   my $form     = $params->( 'form'   );
   my $id       = $params->( 'id'     );
   my $val      = $params->( 'val', { raw => TRUE } );
   my $config   = Web::Components::Forms->load_config( $self, $req, $domain );
   my $defaults = $config->{ $form }->{defaults};
   my $class    = $defaults->{result_class};

   if    (first_char $class eq '+') { $class = substr $class, 1 }
   elsif (defined $class_base)      { $class = "${class_base}::${class}" }

   $_result_class_cache->{ $class }
      or (ensure_class_loaded( $class )
          and $_result_class_cache->{ $class } = TRUE);

   my $attr = $class->validation_attributes; $attr->{level} = 4;

   return Data::Validation->new( $attr )->check_field( $id, $val );
};

# Public methods
sub check_form_field {
   my ($self, $req, $result_class_base) = @_; my $mesg;

   my $id = $req->query_params->( 'id' ); my $meta = { id => "${id}_ajax" };

   try   { $self->$_check_field( $req, $result_class_base ) }
   catch {
      my $e = $_; my $args = { params => $e->args, quote_bind_values => TRUE };

      $self->log->debug( "${e}" );
      $mesg = $req->loc( $e->error, $args );
      $meta->{class_name} = 'field_error';
   };

   return { code => HTTP_OK,
            form => [ { fields => [ { content => $mesg } ] } ],
            page => { meta => $meta },
            view => 'json' };
}

sub create_form_record {
   my ($self, $args, @cols) = @_; my $rs = $args->{rs}; my $row = {};

   for my $col ($rs->result_source->columns, @cols) {
      $_set_column->( $self, $args, $row, $col );
   }

   return $rs->create( $row );
}

sub find_and_update_form_record {
   my ($self, $args, @cols) = @_; my $rs = $args->{rs};

   my $row = $rs->find( $args->{id} ) or return;

   for my $col ($rs->result_source->columns, @cols) {
      $_set_column->( $self, $args, $row, $col );
   }

   $row->update;
   return $row;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Role::Forms - Model methods used when building and processing forms

=head1 Synopsis

   package YourApp::Model::YourModel;

   use Moo;

   with 'Web::Components::Role::Forms';

   sub your_action {
      my ($self, $req) = @_;

      my $name = 'demo';
      my $page = { title => 'Form Demo' };
      my $rs   = $self->schema->resultset( 'YourTableName' );
      my $row  = $rs->find( $req->uri_params->( 0 ) );

      return $self->get_stash( $req, $page, $name, $row );
   }

=head1 Description

Supplies methods to the model used when building and processing forms

=head1 Configuration and Environment

Defines no attributes. Requires the following to be defined in the consuming
class

=over 3

=item C<log>

A logger object reference

=back

=head1 Subroutines/Methods

=head2 C<get_stash>

   $stash = $self->get_stash( $req, $page, $form_name, $source );

Modifies the method in the consuming class. Creates an instance of
L<Web::Components::Forms> using the form name and data source provided in the
C<get_stash> call. Injects the object reference into the stash

=head2 C<check_form_field>

   $hash_ref = $self->check_form_field( $req, $result_class_base );

Handles client requests to check the validity of a specific form field value.
These requests are generated by JavaScript on the web page making asynchronous
calls to the server to validate a field value. Returns a hash reference
that will be serialised by the JSON view

=head2 C<create_form_record>

   $row_object_ref = $self->create_form_record( $args, @cols );

Create a new record in the database.  The C<args> hash reference takes the
following attributes; C<method>, C<params>, and C<rs>

The C<method> value is prepended to each column name and if the consuming class
defines such a method it is called passing in the value of the C<params>
attribute. The methods return value is the value of the column

The C<params> value is a code reference obtained from the request object. When
called the code reference returns parameter values from the current request

The C<rs> value is the result set used in the database operations

=head2 C<find_and_update_form_record>

   $row_object_ref = $self->find_and_update_form_record( $args, @cols );

Find and updates a record in the database. The C<args> hash reference takes the
following attributes; C<id>, C<method>, C<params>, and C<rs> (see
L</create_form_record>)

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Data::Validation>

=item L<HTTP::Status>

=item L<Web::Components::Forms>

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
