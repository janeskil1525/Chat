#!/usr/bin/env perl

use Moo;
use MooX::Options;
use Config::Tiny;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use feature qw(signatures say);
no warnings qw(experimental::signatures);

use Data::Dumper;
use Net::WebSocket::Server;
use Mojo::Pg;
use Log::Log4perl qw(:easy);
use Mojo::JSON qw {decode_json};

use Chat::Helper::Clients;

use namespace::clean -except => [qw/_options_data _options_config/];

option 'configpath' => (
	is 			=> 'ro',
	required 	=> 1,
	reader 		=> 'get_configpath',
 	format 		=> 's',
 	doc 		=> 'Configuration file',
 	default 	=> '/home/jan/Project/Laga-Intern/Admin/conf/'
);

sub chat_server ($self) {

	my $config = get_config($self->get_configpath() . 'config.ini');
	my $port = $config->{LISTEN}->{port};

	say "Starting WebSocket chat server on port $port, press Ctr-C to disconnect";
	Log::Log4perl->easy_init($ERROR);
	Log::Log4perl::init($self->get_configpath() . 'log4perl.conf');

	my $pg = Mojo::Pg->new->dsn($config->{DATABASE}->{pg});
	say "NetChat " . $pg->db->query('select version() as version')->hash->{version};

	my $client = Chat::Helper::Clients->new();

	Net::WebSocket::Server->new(
		listen => $port,
		on_connect => sub {
			my ($serv, $conn) = @_;
			$conn->on(
				utf8 => sub ($conn, $msg) {

					#print Dumper($msg ) . "\n";

					my $message = decode_json($msg);
					my $output = $message->{username} . ": " . $message->{text};
					print "got utf8: $output\n";
					#print Dumper($msg ) . "\n";
					$client->add_client($message->{company}, $conn);
say $message->{company};
					my $clients = $client->clients;
					if ($message->{company} eq 'LA')
					{
						$_->send_utf8($output) for values %$clients ; #( $serv->connections() );
					} else {
						$_->send_utf8($output) for values %$clients ; #( $serv->connections() );
					}


					$pg->db->insert('chat',{
						userid   => $message->{userid},
						company  => $message->{company},
						username => $message->{username},
						message  => $output
					});
				},
				binary => sub ($conn, $msg) {

					print "got binary: $msg\n";
					#print Dumper($serv->connections() ) . "\n";

					$_->send_utf8($msg) for( $serv->connections() );
				},
				disconnect => sub ($conn, $code, $reason) {

					print "closed $code, $reason\n";

				},
			);
		},
	)->start;
}

sub get_config{
	my ($configfile) = @_;

 	my $log = Log::Log4perl->get_logger();
	$log->logdie("config file name is empty")
 		unless ($configfile);

	my $config = Config::Tiny->read($configfile);
 	$log->logdie("config file could not be read")
 		unless ($config);

	return $config;
}

main->new_with_options->chat_server();

1;