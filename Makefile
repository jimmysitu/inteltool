#
# Makefile for inteltool utility
#
# Copyright (C) 2008 by coresystems GmbH
# written by Stefan Reinauer <stepan@coresystems.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

PROGRAM = inteltool

top ?= $(abspath ./)

CC      ?= gcc
INSTALL ?= /usr/bin/env install
PREFIX  ?= /usr/local
CFLAGS  ?= -O2 -g -Wall -Wextra -Wmissing-prototypes
LDFLAGS += -lpci -lz

CPPFLAGS += -I$(top)/include

OBJS = inteltool.o pcr.o cpu.o gpio.o gpio_groups.o rootcmplx.o powermgt.o \
       memory.o pcie.o amb.o ivy_memory.o spi.o gfx.o ahci.o \

OS_ARCH	= $(shell uname)
ifeq ($(OS_ARCH), Darwin)
LDFLAGS += -framework DirectHW
endif
ifeq ($(OS_ARCH), FreeBSD)
CPPFLAGS += -I/usr/local/include
LDFLAGS += -L/usr/local/lib
LIBS = -lz
endif
ifeq ($(OS_ARCH), NetBSD)
CPPFLAGS += -I/usr/pkg/include
LDFLAGS += -L/usr/pkg/lib -Wl,-rpath-link,/usr/pkg/lib -lz -lpciutils -lpci -l$(shell uname -p)
endif

all: pciutils dep $(PROGRAM)

$(PROGRAM): $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $(PROGRAM) $(OBJS) $(LDFLAGS)

clean:
	rm -f $(PROGRAM) *.o *~ junit.xml .dependencies

distclean: clean
	rm -f .dependencies

dep:
	@$(CC) $(CFLAGS) $(CPPFLAGS) -MM *.c > .dependencies

define LIBPCI_TEST
/* Avoid a failing test due to libpci header symbol shadowing breakage */
#define index shadow_workaround_index
#ifdef __NetBSD__
#include <pciutils/pci.h>
#else
#include <pci/pci.h>
#endif
struct pci_access *pacc;
int main(int argc, char **argv)
{
	(void) argc;
	(void) argv;
	pacc = pci_alloc();
	return 0;
}
endef
export LIBPCI_TEST

pciutils:
	@printf "\nChecking for pciutils and zlib... "
	@echo "$$LIBPCI_TEST" > .test.c
	@$(CC) $(CFLAGS) $(CPPFLAGS) .test.c -o .test $(LDFLAGS)	  \
						>/dev/null 2>&1 &&	  \
		printf "found.\n" || ( printf "not found.\n\n";		  \
		printf "Please install pciutils-devel and zlib-devel.\n"; \
		printf "See README for more information.\n\n";		  \
		rm -f .test.c .test; exit 1)
	@rm -rf .test.c .test .test.dSYM

install: $(PROGRAM)
	mkdir -p $(DESTDIR)$(PREFIX)/sbin
	$(INSTALL) $(PROGRAM) $(DESTDIR)$(PREFIX)/sbin
	mkdir -p $(DESTDIR)$(PREFIX)/share/man/man8
	$(INSTALL) -p -m644 $(PROGRAM).8 $(DESTDIR)$(PREFIX)/share/man/man8

.PHONY: all clean distclean dep pciutils

-include .dependencies
