package Chat::Controller::Index;
use Mojo::Base 'Mojolicious', -signatures;

sub open ($self) {

    $self->render(template => 'open', format => 'html', handler => 'epl');
}
1;
