package Chat::Controller::Logon;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub login ($self) {

  $self->session( 'username' => $self->param('username') );
  $self->redirect_to('chat');
}

1;
