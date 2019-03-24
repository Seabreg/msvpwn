CC=gcc
CFLAGS=-std=c99 -Wall -Wextra
LDFLAGS=-lcrypto
PREFIX=/usr/local

SRC=$(wildcard src/*.c)
OBJ=$(subst src,obj,$(SRC:.c=.o))

all: maketree msvpwn

maketree:
	@mkdir -p obj/
	@mkdir -p bin/

msvpwn: $(OBJ)
	@$(CC) $(OBJ) -o bin/msvpwn $(LDFLAGS)

obj/%.o: src/%.c
	@$(CC) -c $< $(CFLAGS) -o $@

install: msvpwn
	@mkdir -p $(PREFIX)/bin
	@mkdir -p $(PREFIX)/share/man/man1
	@mkdir -p $(PREFIX)/share/licenses/$(PKGNAME)

	@install -m 755 bin/msvpwn $(PREFIX)/bin/
	@install -m 755 doc/msvpwn.1 $(PREFIX)/share/man/man1/
	@gzip $(PREFIX)/share/man/man1/msvpwn.1

uninstall:
	@rm $(PREFIX)/bin/msvpwn
	@rm $(PREFIX)/share/man/man1/msvpwn.1.gz

regen_man: doc/msvpwn.1.ronn
	@ronn --manual="MSVPWN MANUAL" --organization="Matthias Rabault" -r $^ > /dev/null 2>&1

html: doc/msvpwn.1.ronn
	@ronn --manual="MSVPWN MANUAL" --organization="Matthias Rabault" -5 $^ > /dev/null 2>&1

clean:
	@rm -rf obj/
	@rm -rf bin/
	@rm -f doc/*.html

.PHONY: install uninstall clean
