package Chat;
use Mojo::Base 'Mojolicious', -signatures;

use Chat::Helper::Clients;
use Data::Dumper;

use Mojo::Pg;
use Mojo::File;
use File::Share;
use Translations::Helper::Client;
use Authenticate::Helper::Client;
use Parameters::Helper::Client;

$ENV{CHAT_HOME} = '/home/jan/Project/Chat/'
    unless $ENV{CHAT_HOME};

has dist_dir => sub {
  return Mojo::File->new(
      File::Share::dist_dir('Chat')
  );
};

has home => sub {
  Mojo::Home->new($ENV{CHAT_HOME});
};


# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('Config');
  $self->log->path($self->config('log'));
  # Configure the application
  $self->secrets($config->{secrets});

  $self->helper(pg => sub {state $pg = Mojo::Pg->new->dsn(shift->config('pg'))});
  $self->renderer->paths([
      $self->dist_dir->child('templates'),
  ]);
  $self->static->paths([
      $self->dist_dir->child('public'),
  ]);
  say "Chat " . $self->pg->db->query('select version() as version')->hash->{version};

  $self->pg->migrations->name('chat')->from_file(
      $self->dist_dir->child('migrations/chat.sql')
  )->migrate(1);

  $self->helper(authenticate => sub {
    state $authenticate = Authenticate::Helper::Client->new(pg => shift->pg)}
  );
  $self->authenticate->endpoint_address($self->config->{authenticate}->{endpoint_address});
  $self->authenticate->key($self->config->{authenticate}->{key});

  $self->helper(
      translations => sub {# Router
        state $translations = Translations::Helper::Client->new();
      }
  );
  $self->translations->endpoint_address($self->config->{translations}->{endpoint_address});
  $self->translations->key($self->config->{translations}->{key});

  $self->helper(
      settings => sub {
        state $settings = Parameters::Helper::Client->new(pg => shift->pg)
      }
  );
  $self->settings->endpoint_address($self->config->{parameters}->{endpoint_address});
  $self->settings->key($self->config->{parameters}->{key});

  my $sessions    = $self->sessions->samesite('Strict');
  #$self->sessions->secure(0);
  #say Dumper($sessions);
  #$self->sessions->cookie_path('/chat');
  $self->helper(clients => sub {state $clients = Chat::Helper::Clients->new()});
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->any('/ss')->to('index#open');
  $r->any('/login')->to('logon#login');
  $r->any('/')->to('chatter#chat');
  $r->websocket('/stream')->to('chatter#stream');
}

1;
