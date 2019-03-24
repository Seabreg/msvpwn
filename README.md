# Introduction

`msvpwn` (MIT-licensed, see `LICENSE`) patches a DLL from Windows (`msv1_0.dll`) to completely disable the password check: you'll be able to get in with every conceivable password.

# Usage

**msvpwn** [**-s**] *file*

You need to supply the DLL as an argument. **msvpwn** will patch it if it is unpatched, and vice-versa.
If the **-s** option is supplied, **msvpwn** will only display the DLL's status (patched, unpatched).

To add more signatures, edit `src/config.h`, there's an array of `PatchInfo` structures to edit. See [CONTRIBUTING.md](CONTRIBUTING.md)

# Build

The only dependency is OpenSSL (some `make` targets, detailed lower, also require [ronn](1) to generate a manpage, but I provide one so you won't need `ronn`; it's for developers only), compiled with SHA256 support.

```
make
make install
```

I provide `clean` and `uninstall` targets, and you can override the `CC`, `CFLAGS`, `LDFLAGS` and `PREFIX` variables.
Object files get stowed in `obj/`, and the binary goes to `bin/` (I'll let you guess its name).
By the way, my fellow Archers can use the `PKGBUILD` provided in `package/arch` (it's git-based).

`msvpwn` is also bundled with [BlackArch](2), a set of pentesting tools for ArchLinux (a LiveCD is available too).

# Makefile targets

* regen_man: regenerate the manpage to reflect the changes made to `doc/msvpwn.1.ronn`. [ronn](1) is needed.
* html: generate an HTML version of the manpage (`doc/msvpwn.1.html`). [ronn](1) is needed.

[1]: https://github.com/rtomayko/ronn
[2]: http://blackarch.org/
