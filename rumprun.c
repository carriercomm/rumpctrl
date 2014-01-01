#include <sys/types.h>
#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>

#include <rump/rump.h>
#include <rump/rump_syscalls.h>

extern void *_netbsd_environ;
extern const char *__progname;

static char *the_env[1] = { NULL } ;

static void
die(const char *fmt, ...)
{
        va_list va;

        va_start(va, fmt);
        vfprintf(stderr, fmt, va);
        va_end(va);
        exit(1);
}

int
main(int argc, char *argv[])
{
	void *dl;
	int (*dlmain)(int, char **);
	int ret;
        char ***env;

	if (argc == 1)
		die("supply a program to load");
	rump_init();
	dl = dlopen(argv[1], RTLD_LAZY | RTLD_LOCAL);
	if (! dl)
		die("could not open library");
	dlmain = dlsym(dl, "emul_exit_wrapper");
	if (! dlmain)
		die("could not find exit wrapper in library");
        __progname = argv[1];
        env = dlsym(dl, "_netbsd_environ");
        *env = the_env;
	ret = (*dlmain)(argc - 1, argv + 1);	
	rump_sys_reboot(0, NULL);
	return ret;
}

