#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Net::WebSocket::Server;

my $port = 8082;
print "Starting WebSocket chat server on port $port, press Ctr-C to disconnect\n";
Net::WebSocket::Server->new(
	listen => $port,
	on_connect => sub {
		my ($serv, $conn) = @_;
		$conn->on(
			utf8 => sub {
				my ($conn, $msg) = @_;
				print "got: $msg\n";
				#print Dumper($serv->connections() ) . "\n";

				$_->send_utf8($msg) for( $serv->connections() );
			},
		);
	},
)->start;
