package Chat::Helper::Clients;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Data::Dumper;

has 'clients';

sub add_client ($self, $client, $session) {

    my $clients = $self->clients();
    $clients = {} unless $clients;

    $clients->{$client} = $session;
    #say Dumper($clients);
    $self->clients($clients);

    my $test = 1;
}

1;