# perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use PerlIO::Layers qw/query_handle get_layers/;
use IO::Socket::UNIX;
use Time::HiRes qw/sleep/;

alarm 5;
$SIG{ALRM} = sub { die "Timeout\n" };

my $server = IO::Socket::UNIX->new(Local=> 'test.sock', Listen => 1) or BAILOUT("Can't make listening socket: $!");
my $child = fork;
if (not $child) {
	my $client = $server->accept;
	$client->autoflush(1);
	print {$client} "Connected\n";
	print {$client} $_ while <$client>;
	exit;
}
sleep 1;

my $fh;
lives_ok { open $fh, '+<:socket', 'test.sock' or die "Can't connect to test.sock: $!" } 'Can connect to socket test.sock';

my $connected = <$fh>;
is $connected, "Connected\n", 'Got "Connected"';

$fh->autoflush(1);
ok print($fh "hello world,\n"), 'Can write to socket buffer';
my $reply = <$fh>;

is $reply, "hello world,\n", 'Got reply "hello world,"';

ok close($fh), 'Can close socket';

unlink 'test.sock';

kill 'TERM', $child;

done_testing;
