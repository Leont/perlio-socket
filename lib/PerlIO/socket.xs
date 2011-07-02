#include <sys/socket.h>
#include <sys/un.h>

#ifndef UNIX_PATH_MAX
#define UNIX_PATH_MAX 108
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

static IV PerlIOSocket_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab) {
	if (!PerlIOValid(f))
		SETERRNO(EBADF, SS_IVCHAN);
	else
		SETERRNO(EINVAL, LIB_INVARG);
	return -1;
}

static PerlIO* PerlIOSocket_open(pTHX_ PerlIO_funcs *self, PerlIO_list_t *layers, IV n, const char *mode, int fd, int imode, int perm, PerlIO *old, int narg, SV **args) {
	if (fd >= 0) {
		return PerlIO_fdopen(fd, mode);
	}
	else {
		SV* arg = narg > 0 ? args[0] : NULL;
		if (!arg || !SvOK(arg)) {
			SETERRNO(EINVAL, LIB_INVARG);
			return NULL;
		}
		else {
			struct sockaddr_un address;
			int unix_socket = socket(AF_UNIX, SOCK_STREAM, 0);
			if (unix_socket == -1)
				return NULL;
			address.sun_family = AF_UNIX;
			strncpy(address.sun_path, SvPV_nolen(arg), UNIX_PATH_MAX);
			if (connect(unix_socket, (struct sockaddr*) &address, sizeof address) == -1)
				return NULL;
			else
				return PerlIO_fdopen(unix_socket, "r+");
		}
	}
}

const PerlIO_funcs PerlIO_socket = {
	sizeof(PerlIO_funcs),
	"socket",
	0,
	PERLIO_K_UTF8 | PERLIO_K_MULTIARG,
	PerlIOSocket_pushed,
	NULL,
	PerlIOSocket_open,
};

MODULE = PerlIO::socket				PACKAGE = PerlIO::socket

BOOT:
	PerlIO_define_layer(aTHX_ (PerlIO_funcs*)&PerlIO_socket);
