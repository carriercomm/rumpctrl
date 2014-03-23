#include <stdint.h>
#include <stdio.h>
#include <setjmp.h>

extern char *_netbsd__progname;

static jmp_buf buf;

int _netbsd_main(int argc, char **argv);
void _netbsd_exit(int status);

static int ret = 0;

int
main(int argc, char **argv)
{

	_netbsd__progname = argv[0];

	if (! setjmp(buf)) {
        	_netbsd_exit(_netbsd_main(argc, argv));
		/* will call _exit so will not reach here */
	}
	return ret;
}

void
emul__exit(int status)
{

	ret = status;
	longjmp(buf, status);
}
