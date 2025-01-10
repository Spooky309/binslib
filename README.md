currently supports:

* macos
* linux (x11)

i'll add wayland support when i feel like it. it's a pain in the arse and it doesn't work with renderdoc so i won't be doing that yet.
win32 support is as easy as adding an extra case prong but again, i can't be arsed.

maintained by spooky309 (kole) and gonzo.

TO ADD A NEW EXAMPLE

* make a new directory in examples, no spaces in the name!
* in there, make a main.zig file
* now it'll appear in the zig-out/bin directory when you build.
