# Name

Web::Components::Forms - Form building and rendering

# Synopsis

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

# Description

The form object that this class builds is passed to the view which uses
[HTML::FormWidgets](https://metacpan.org/pod/HTML::FormWidgets) to render the markup

# Configuration and Environment

Defines the following attributes;

- `config`

    An immutable hash reference. Defaults empty. Populated with the return value
    from ["load\_config"](#load_config) which is called by the constructors ["BUILDARGS"](#buildargs)

- `data`

    An immutable array reference of hash references. Defaults empty. The form
    is built by the ["BUILD"](#build) method and it's output goes here

- `first_field`

    An immutable simple string with no default. If set to a valid field name then
    that field will have focus when the form is rendered

- `js_object`

    An immutable non empty simple string which defaults to `behaviour`. Used in
    the HTML template it is the name of the JavaScript object which is instantiated
    when the page loads

- `l10n`

    A lazily evaluated immutable code reference. The default constructor returns
    a subroutine which closes over the request object to provide a memoized
    function for translating strings into different languages

- `list_key`

    An immutable non empty simple string that defaults to `fields`. Used by
    [build](#html-formwidgets-build) it identifies which attribute contains
    the list widgets for each region on the form

- `literal_js`

    An immutable array reference of strings which by default is empty. Strings added
    to this list appear on the web page via the template as literal JavaScript.
    Provides configuration data for the JavaScript widgets

- `max_pwidth`

    An immutable integer which default to 1024. Used by [HTML::FormWidgets](https://metacpan.org/pod/HTML::FormWidgets) this
    is the maximum size in pixels allowed for field prompt. See ["pwidth"](#pwidth)

- `model`

    An immutable required object reference. It is the instance to which
    [Web::Components::Forms::Role](https://metacpan.org/pod/Web::Components::Forms::Role) was applied

- `name`

    An immutable required non empty simple string. The name of the form. This is
    used a key into the configuration data

- `ns`

    A lazily evaluated non empty simple string which defaults to the value of the
    request objects `domain` attribute. Form configuration can be stored in a
    common file or in model specific file. The model name (moniker) is stored
    on the request and used for this purpose

- `optional_js`

    The list of Javascript filenames (with extension, without path) are added
    to the list of files which will be included on the page. An array reference
    of strings

- `pwidth`

    An immutable integer which defaults to 40. The size (as a percentage of the
    screen width) to use for the field prompt

- `request`

    An immutable required weakened object reference. The request object

- `result_class`

    An immutable simple string with no default usually set from the configuration
    file. Used by the server side field checking function to load the result class
    that contains the validation parameters

- `skin`

    A lazily evaluated non empty simple string which defaults to the configuration
    value provided by the model. See ["template\_dir"](#template_dir)

- `template`

    The name of the layout to use in the templating engine. Defaults to `forms`

- `template_dir`

    A lazily evaluated directory which is the parent of the ["skin"](#skin) directories

- `uri_for`

    A lazily evaluated code reference which closes over the request object to
    provide a function that generates URI objects from partial paths

- `width`

    A lazily evaluated integer that defaults to 1024 but will be overridden
    by the value in the cookie if one is provided by the request object. The
    size in pixels of the users browser window

# Subroutines/Methods

## `BUILDARGS`

Loads the form configuration files and uses the defaults that they contain
to set some attribute values

## `BUILD`

Builds the form

## `load_config`

    $config = Web::Components::Forms->load_config( $model, $req );

Loads the form configuration files. This is a class method

# Diagnostics

None

# Dependencies

- [Class::Usul](https://metacpan.org/pod/Class::Usul)
- [File::DataClass](https://metacpan.org/pod/File::DataClass)
- [File::Gettext](https://metacpan.org/pod/File::Gettext)
- [Moo](https://metacpan.org/pod/Moo)
- [Web::Components::Forms::Field](https://metacpan.org/pod/Web::Components::Forms::Field)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Forms.
Patches are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2015 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
