#!/usr/bin/env perl

use Mojolicious::Lite;

@ARGV = qw(daemon --listen http://*:3029);
# storage
my $clients = {};

# helpers (methods on app/controller/template)
helper 'send_to_all' => sub {
	my ($self, $message) = @_;
	$_->send($message) for values %$clients;
};

helper 'add_client' => sub {
	my ($self, $username) = @_;
	$clients->{$username} = $self;
	$self->send_to_all( "$username has joined" );
};

helper 'remove_client' => sub {
	my ($self, $username) = @_;
	delete $clients->{$username};
	$self->send_to_all( "$username has left" );
};

# routing
any '/' => 'index';

any '/login' => sub {
	my $self = shift;
	$self->session( 'username' => $self->param('username') );
	$self->redirect_to('chat');
};

any '/chat' => sub {
	my $self = shift;
	$self->redirect_to('/') unless $self->session('username');
	$self->render('chat');
};

websocket '/stream' => sub {
	my $self = shift;
	Mojo::IOLoop->stream($self->tx->connection)->timeout(12000);

	my $username = $self->session('username');
	$self->add_client( $username );

	$self->on( message => sub {
		my ($self, $text) = @_;
		$self->send_to_all( "$username: $text" );
	} );

	$self->on( finish => sub {
		my $self = shift;
		$self->remove_client( $username );
	} );
};

# start the app
app->start;

# templates
__DATA__
@@ layouts/standard.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>
      %= title
    </title>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
  </head>
  <body>
    %= content
  </body>
</html>
@@ index.html.ep
% layout 'standard';
% title 'Welcome to Mojo Chat';
<h1><%= title %></h1>
<p>Please choose a username:</p>
%= form_for 'login' => begin
  %= input_tag 'username'
  %= submit_button
% end
@@ chat.html.ep
% layout 'standard';
% title 'Mojo Chat';
<p>
  %= session('username') . ':'
  <input type="text" id="message"/>
  <button onclick="wssend()">Send</button>
</p>
<div id="log"></div>
%= javascript begin
  var ws;
  function wssend () {
    var text = $('#message').val();
    ws.send(text);
    $('#message').val('');
  }
  $(function(){
    ws = new WebSocket( '<%= url_for('stream')->to_abs %>' );
    ws.onmessage = function (event) {
      $('#log').prepend('<p>' + event.data + '</p>');
    };
    ws.onerror = function(evt) {
    	console.log("WS Error" + evt.data);
    	//onError(evt)
    };
  });
% end
