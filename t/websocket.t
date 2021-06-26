use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Chat');
$t->websocket_ok('/stream')
    ->send_ok('Hello Mojo!')
    ->message_ok
    ->message_is('echo: Hello Mojo!')
    ->finish_ok;

done_testing();
