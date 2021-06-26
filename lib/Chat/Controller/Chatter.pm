package Chat::Controller::Chatter;
use Mojo::Base 'Mojolicious::Controller', -signatures;

my $clients = {};
sub chat ($self) {

    $self->redirect_to('/') unless $self->session('username');
    $self->render('layouts/chat');
}

sub stream ($self) {
    Mojo::IOLoop->stream($self->tx->connection)->timeout(12000);

    my $username = $self->session('username');
    $username = 'kalle' unless $username;

    $self->add_client( $username );

    $self->on( message => sub {
        my ($self, $text) = @_;
        $self->send_to_all( "$username: $text" );
    } );

    $self->on( finish => sub {
        my $self = shift;
        $self->remove_client( $username );
    } );
}

sub send_to_all ($self, $message) {
    if (index($message, 'heartbeat') == -1) {
        my $clients = $self->clients->clients;
        $_->send($message) for values %$clients
    }
}

sub add_client ($self, $username) {

    $self->clients->add_client($username, $self);
    $self->send_to_all( "$username has joined" );
}

sub remove_client ($self, $username) {
    delete $clients->{$username};
    $self->send_to_all( "$username has left" );
}


1;