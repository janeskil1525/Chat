package Chat;
use Mojo::Base 'Mojolicious', -signatures;

use Chat::Helper::Clients;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('Config');
  $self->log->path($self->config('log'));
  # Configure the application
  $self->secrets($config->{secrets});

  $self->helper(clients => sub {state $clients = Chat::Helper::Clients->new()});
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->any('/')->to('index#open');
  $r->any('/login')->to('logon#login');
  $r->any('/chat')->to('chatter#chat');
  $r->websocket('/stream')->to('chatter#stream');
}

1;
