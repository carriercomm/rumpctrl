DEFUNDEF=-D__NetBSD__ -U__FreeBSD__ -Ulinux -U__linux -U__linux__ -U__gnu_linux__
NBCFLAGS=-nostdinc -nostdlib -Irump/include -O2 -g -Wall -fPIC  ${DEFUNDEF}
HOSTCFLAGS=-O2 -g -Wall -Irumpdyn/include
RUMPLIBS=-Lrumpdyn/lib -Wl,--no-as-needed -lrumpvfs -lrumpfs_kernfs -lrumpdev -lrumpnet_local -lrumpnet_netinet -lrumpnet_net -lrumpnet -lrump -lrumpuser
RUMPCLIENT=-Lrumpdyn/lib -lrumpclient

all:		ifconfig.so rumprun rumpremote

stub.o:		stub.c
		${CC} ${NBCFLAGS} -fno-builtin-execve -c $< -o $@

rumprun.o:	rumprun.c
		${CC} ${HOSTCFLAGS} -c $< -o $@

rumprun:	rumprun.o
		${CC} $< -o $@ ${RUMPLIBS} -lc -ldl

rumpremote.o:	rumpremote.c
		${CC} ${HOSTCFLAGS} -c $< -o $@

rumpremote:	rumpremote.o
		${CC} $< -o $@ ${RUMPCLIENT} -lc -ldl

emul.o:		emul.c
		${CC} -O2 -g -Wall -fPIC -D_FILE_OFFSET_BITS=64 -c $< -o $@

rump.map:	
		cat ./rumpsrc/sys/rump/librump/rumpkern/rump_syscalls.c | \
			grep rsys_aliases | grep -v -- '#define' | \
			sed -e 's/rsys_aliases(//g' -e 's/);//g' -e 's/\(.*\),\(.*\)/\1@\2/g' | \
			awk '{gsub("@","\t"); print;}' > $@

ifconfig/ifall.o:	
		cd ifconfig && make && cd ..

ifall.o:	ifconfig/ifall.o
		cp ifconfig/ifall.o $@

ifconfig.so:	ifall.o emul.o stub.o rump.map rump/lib/libc.a
		${CC} -Wl,-r -nostdlib ifall.o rump/lib/libc.a -o tmp1.o
		objcopy --redefine-syms=extra.map tmp1.o
		objcopy --redefine-syms=emul.map tmp1.o
		objcopy --redefine-syms=rump.map tmp1.o
		objcopy --redefine-sym environ=_netbsd_environ tmp1.o
		${CC} -Wl,-r -nostdlib tmp1.o emul.o stub.o -o tmp2.o
		objcopy -w -L '*' tmp2.o
		objcopy --globalize-symbol=emul_exit_wrapper tmp2.o
		${CC} tmp2.o -nostdlib -shared -Wl,-soname,example.so -o $@

clean:		
		rm -f *.o *.so *~ rump.map
		cd ifconfig && make clean && cd ..

cleanrump:	clean
		rm -rf obj rump rumpobj rumpsrc rumptools rumpdyn
