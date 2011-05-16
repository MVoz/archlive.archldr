export SHELL = sh
PROGRAM = pylauncher
LDFLAGS = -shared -dll
CC = i486-mingw32-gcc
STRIP = i486-mingw32-strip

all: cpuid.dll

cpuid.dll: cpuid.c
	$(CC) -o $@ $(LDFLAGS) $^
	$(STRIP) $@
