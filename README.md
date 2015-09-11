# ig
Customizeable thing meant to mimic god-mode

god-mode does a few things that annoy me. probably the first is the lack of configurable implicit modifier keys.
Most of the time I don't want an implied control except at the very beginning, and possibly for a few things like C-x C-f.

the other is the lack of a function from a keymap to a god-like prefix command. That would probably not be that useful now that I think of it, but I am going to make it anyway.

Anyway, the approach that this thing will take is far, far worse than god-mode's actual approach. I am maintaining a hash-table in addition to the existing keymaps, and using it like a prefix tree until I find an actual elisp prefix tree implementation. This initial grand unified keymap thing is also generated by a perl script, which is stupid and unnecessary.

the end goal, however, is to make a more configureable god-mode where you can do stuff like apply rules for which modifiers should be implict, and have it fail informatively when there's a conflict.
