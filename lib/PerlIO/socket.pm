package PerlIO::socket;
use strict;
use warnings;

use XSLoader;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

__END__

# ABSTRACT: unix domain sockets using open()
