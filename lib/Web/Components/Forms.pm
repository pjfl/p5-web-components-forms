package Web::Components::Forms;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 5 $ =~ /\d+/gmx );

use Class::Usul::Constants  qw( EXCEPTION_CLASS CONFIG_EXTN NUL TRUE );
use Class::Usul::Functions  qw( is_arrayref is_hashref throw );
use Class::Usul::Types      qw( ArrayRef CodeRef HashRef Int
                                NonEmptySimpleStr SimpleStr Object Str );
use File::DataClass::Types  qw( Directory );
use File::Gettext::Schema;
use Scalar::Util            qw( blessed weaken );
use Unexpected::Functions   qw( Unspecified );
use Web::Components::Forms::Field;
use Moo;

# Requires model->log
# Requires model->config->l10n_attributes, ->root, and ->sharedir

# Private package variables
my $_config_cache = {};
my $_l10n_cache   = {};

# Private methods
my $_model_config = sub {
   my ($self, $name, $default) = @_; my $conf = $self->model->config;

   return $conf->can( $name ) ? $conf->$name() : $default;
};

# Attribute constructors
my $_build_l10n = sub {
   my $self = shift; my $req = $self->request; weaken $req;

   return sub {
      my ($opts, $text, @args) = @_; # Ignore $opts->{ ns, language }

      my $key = $req->domain.'.'.$req->locale.".${text}";

      (exists $_l10n_cache->{ $key } and defined $_l10n_cache->{ $key })
         or $_l10n_cache->{ $key } = $req->loc( $text, @args );

      return $_l10n_cache->{ $key };
   };
};

my $_build_uri_for = sub {
   my $self = shift; my $req = $self->request; weaken $req;

   return sub { $req->uri_for( @_ ) };
};

my $_build_width = sub {
   my $self = shift; my $req = $self->request;

   $req->can( 'get_cookie_hash' ) or return 1_024;

   my $cookie = $self->$_model_config( 'state_cookie', 'state' );

   return $req->get_cookie_hash( $cookie )->{width} // 1_024;
};

# Public attributes
has 'config'       => is => 'ro',   isa => HashRef, builder => sub { {} };

has 'data'         => is => 'ro',   isa => ArrayRef[HashRef],
   builder         => sub { [] };

has 'first_field'  => is => 'ro',   isa => SimpleStr;

has 'js_object'    => is => 'lazy', isa => NonEmptySimpleStr,
   builder         => sub { $_[ 0 ]->$_model_config( 'js_object', 'behaviour')};

has 'l10n'         => is => 'lazy', isa => CodeRef, builder => $_build_l10n;

has 'list_key'     => is => 'ro',   isa => NonEmptySimpleStr,
   default         => 'fields';

has 'literal_js'   => is => 'ro',   isa => ArrayRef[Str], builder => sub { [] };

has 'max_pwidth'   => is => 'ro',   isa => Int, default => 1_024;

has 'model'        => is => 'ro',   isa => Object, required => TRUE;

has 'name'         => is => 'ro',   isa => NonEmptySimpleStr, required => TRUE;

has 'ns'           => is => 'lazy', isa => NonEmptySimpleStr,
   builder         => sub { $_[ 0 ]->request->domain };

has 'optional_js'  => is => 'ro',   isa => ArrayRef[Str], builder => sub { [] };

has 'pwidth'       => is => 'ro',   isa => Int, default => 40;

has 'request'      => is => 'ro',   isa => Object, required => TRUE,
   weak_ref        => TRUE;

has 'result_class' => is => 'ro',   isa => SimpleStr;

has 'skin'         => is => 'lazy', isa => NonEmptySimpleStr,
   builder         => sub { $_[ 0 ]->$_model_config( 'skin', 'default' ) };

has 'template'     => is => 'lazy', isa => NonEmptySimpleStr,
   builder         => sub { $_[ 0 ]->$_model_config( 'form_template', 'forms')};

has 'template_dir' => is => 'lazy', isa => Directory, coerce => TRUE,
   builder         => sub {
      $_[ 0 ]->model->config->root->catdir( 'templates', $_[ 0 ]->skin ) };

has 'uri_for'      => is => 'lazy', isa => CodeRef, builder => $_build_uri_for;

has 'width'        => is => 'lazy', isa => Int, builder => $_build_width;

# Private functions
my $_field_list = sub {
   my ($conf, $region, $src) = @_; my $names;

   if (is_arrayref $region) {
      $names = $region->[ 0 ]
             ? $region
             : [ sort grep { not m{ \A meta \z }mx } keys %{ $src // {} } ];
   }
   else { $names = $conf->{ $region } // [] };

   return grep { not m{ \A (?: _ | related_resultsets ) }mx } @{ $names };
};

# Private methods
my $_assign_value = sub {
   my ($self, $field, $src) = @_; my $v = $field->value;

   my $fname = $field->name; $fname =~ s{ \. }{_}gmx;

   if  ($src and blessed $src and $src->can( $fname )) { $v = $src->$fname()   }
   elsif (is_hashref $src and exists $src->{ $fname }) { $v = $src->{ $fname } }

   my $hook  = $self->model->can( '_'.$self->name."_${fname}_assign_hook" );

   $hook and $v = $hook->( $self->model, $self->request, $field, $src, $v );

   if (is_hashref $v) { $field->add_properties( $v ) }
   elsif (defined $v) { $field->value( "${v}" ) }

   return;
};

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   $attr->{config} //= $self->load_config( $attr->{model}, $attr->{request} );

   exists $attr->{name} or throw Unspecified, [ 'name' ];

   exists $attr->{config}->{ $attr->{name} }
       or throw 'Form name [_1] unknown', [ $attr->{name} ];

   my $defaults = $attr->{config}->{ $attr->{name} }->{defaults} // {};

   $attr->{ $_ } //= $defaults->{ $_ } for (keys %{ $defaults });

   return $attr;
};

sub BUILD {
   my ($self, $attr) = @_; my $cache = {}; my $conf = $self->config;

   my $count = 0; my $form_name = $self->name; my @hooks;

   my $model = $self->model; my $src = $attr->{source};

   # Visit the lazy so ::FormHandler can pass $self to HTML::FormWidgets->build
   $self->l10n; $self->ns; $self->template_dir; $self->uri_for; $self->width;

   for my $region (@{ $conf->{ $form_name }->{regions} // [] }) {
      my $data = $self->data->[ $count++ ] = { fields => [] };

      for my $field_name ($_field_list->( $conf->{_fields}, $region, $src )) {
         my $field = Web::Components::Forms::Field->new
            ( $conf->{_fields}, $form_name, $field_name );

         $self->$_assign_value( $field, $src );

         push @{ $data->{fields} }, { content => $field->properties };

         my $hook = $model->can( "_${form_name}_${field_name}_field_hook" );

         $hook and push @hooks, [ $field_name, $hook ];
         $cache->{ $field_name } = $field;
      }
   }

   for my $tuple (@hooks) {
      $tuple->[ 1 ]->( $model, $self->request, $cache, $tuple->[ 0 ] );
   }

   return;
}

sub load_config { # Class method
   my ($class, $model, $req, $domain) = @_;

   defined $model or throw Unspecified, [ 'model' ];
   defined $req   or throw Unspecified, [ 'request' ];

   $domain //= $req->domain; defined $domain or throw Unspecified, [ 'domain' ];

   my $language = $req->language; my $key = "${domain}.${language}";

   exists $_config_cache->{ $key } and return $_config_cache->{ $key };

   my $conf     = $model->config;
   my $file     = $conf->can( 'form_data' ) ? $conf->form_data : 'forms';
   my $def_path = $conf->sharedir->catfile( $file.CONFIG_EXTN );
   my $dom_path = $conf->sharedir->catfile( $domain.CONFIG_EXTN );
   my @paths    = ($def_path);

   $def_path->exists or ($model->log->error( "File ${def_path} not found" )
                         and return {});

   if ($dom_path->exists) { push @paths, $dom_path }
   else { $model->log->debug( "File ${dom_path} not found" ) }

   my $schema = File::Gettext::Schema->new( {
      builder          => $model,
      cache_class      => 'none',
      gettext_catagory => $conf->l10n_attributes->{gettext_catagory} // NUL,
      language         => $language, } );

   return $_config_cache->{ $key } = $schema->load( @paths );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Forms - Form building and rendering

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

The form object that this class builds is passed to the view which uses
L<HTML::FormWidgets> to render the markup

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<config>

An immutable hash reference. Defaults empty. Populated with the return value
from L</load_config> which is called by the constructors L</BUILDARGS>

=item C<data>

An immutable array reference of hash references. Defaults empty. The form
is built by the L</BUILD> method and it's output goes here

=item C<first_field>

An immutable simple string with no default. If set to a valid field name then
that field will have focus when the form is rendered

=item C<js_object>

An immutable non empty simple string which defaults to C<behaviour>. Used in
the HTML template it is the name of the JavaScript object which is instantiated
when the page loads

=item C<l10n>

A lazily evaluated immutable code reference. The default constructor returns
a subroutine which closes over the request object to provide a memoized
function for translating strings into different languages

=item C<list_key>

An immutable non empty simple string that defaults to C<fields>. Used by
L<build|/HTML::FormWidgets/build> it identifies which attribute contains
the list widgets for each region on the form

=item C<literal_js>

An immutable array reference of strings which by default is empty. Strings added
to this list appear on the web page via the template as literal JavaScript.
Provides configuration data for the JavaScript widgets

=item C<max_pwidth>

An immutable integer which default to 1024. Used by L<HTML::FormWidgets> this
is the maximum size in pixels allowed for field prompt. See L</pwidth>

=item C<model>

An immutable required object reference. It is the instance to which
L<Web::Components::Forms::Role> was applied

=item C<name>

An immutable required non empty simple string. The name of the form. This is
used a key into the configuration data

=item C<ns>

A lazily evaluated non empty simple string which defaults to the value of the
request objects C<domain> attribute. Form configuration can be stored in a
common file or in model specific file. The model name (moniker) is stored
on the request and used for this purpose

=item C<optional_js>

The list of Javascript filenames (with extension, without path) are added
to the list of files which will be included on the page. An array reference
of strings

=item C<pwidth>

An immutable integer which defaults to 40. The size (as a percentage of the
screen width) to use for the field prompt

=item C<request>

An immutable required weakened object reference. The request object

=item C<result_class>

An immutable simple string with no default usually set from the configuration
file. Used by the server side field checking function to load the result class
that contains the validation parameters

=item C<skin>

A lazily evaluated non empty simple string which defaults to the configuration
value provided by the model. See L</template_dir>

=item C<template>

The name of the layout to use in the templating engine. Defaults to C<forms>

=item C<template_dir>

A lazily evaluated directory which is the parent of the L</skin> directories

=item C<uri_for>

A lazily evaluated code reference which closes over the request object to
provide a function that generates URI objects from partial paths

=item C<width>

A lazily evaluated integer that defaults to 1024 but will be overridden
by the value in the cookie if one is provided by the request object. The
size in pixels of the users browser window

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Loads the form configuration files and uses the defaults that they contain
to set some attribute values

=head2 C<BUILD>

Builds the form

=head2 C<load_config>

   $config = Web::Components::Forms->load_config( $model, $req );

Loads the form configuration files. This is a class method

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<File::Gettext>

=item L<Moo>

=item L<Web::Components::Forms::Field>

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
