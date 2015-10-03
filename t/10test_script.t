use t::boilerplate;

use Test::More;
use Class::Usul;
use IO::String;
use Web::ComposableRequest;

use_ok 'Web::Components::Forms';
use_ok 'Web::Components::Forms::Field';
use_ok 'Web::Components::Role::Forms';
use_ok 'Web::Components::Role::Forms::View';
use_ok 'Web::Components::Role::Forms::Chooser';
use_ok 'Web::Components::Forms::Demo';

my $config  = {
   max_sess_time => 1,
   prefix        => 'my_app',
   request_roles => [ 'L10N', 'Cookie', 'JSON' ], };
my $factory = Web::ComposableRequest->new( config => $config );
my $session = { authenticated => 1 };
my $args    = 'arg1/arg2/arg-3';
my $query   = { _method => 'update', key => '123-4', };
my $cookie  = 'my_app_cookie1=key1%7Eval1%2Bkey2%7Eval2; '
            . 'my_app_cookie2=key3%7Eval3%2Bkey4%7Eval4';
my $input   = '{ "_method": "delete", "key": "value-1" }';
my $env     = {
   CONTENT_LENGTH       => length $input,
   CONTENT_TYPE         => 'application/json',
   HTTP_ACCEPT_LANGUAGE => 'en-gb,en;q=0.7,de;q=0.3',
   HTTP_COOKIE          => $cookie,
   HTTP_HOST            => 'localhost:5000',
   PATH_INFO            => '/api',
   QUERY_STRING         => 'key=124-4',
   REMOTE_ADDR          => '127.0.0.1',
   REQUEST_METHOD       => 'POST',
   'psgi.input'         => IO::String->new( $input ),
   'psgix.logger'       => sub { warn $_[ 0 ]->{message}."\n" },
   'psgix.session'      => $session,
};
my $app   =  Class::Usul->new( {
   config => { appclass  => 'Class::Usul',
               localedir => 't',
               tempdir   => 't' } } );
my $demo  =  Web::Components::Forms::Demo->new( application => $app );
my $req   =  $factory->new_from_simple_request( {
   domain => $demo->moniker }, $args, $query, $env );
my $stash =  $demo->get_stash( $req, {}, login => {} );

is $stash->{view}, 'HTML', 'Stashes view';
is $stash->{form}->data->[ 2 ]->{fields}->[ 0 ]->{content}->{name}, 'username',
   'Loads form data';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
