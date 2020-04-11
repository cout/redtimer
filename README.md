Redtimer
========

Redtimer is a split timer for speedrunning for the terminal, built using
livesplit-core.

![Example](./docs/redtimer.svg)

Features
--------

* A simple UI that resembles the original livesplit
* Autosplitters, written in Ruby
* Loading of livesplit splits files

Requirements
------------

* Ruby
* Ncurses
* Toilet
* Livesplit-core
* A terminal that supports 256 colors

Build instructions
------------------

```
# Get livesplit-core
git clone https://github.com/LiveSplit/livesplit-core.git
cd livesplit-core
cargo build --release -p cdylib
cd capi/bind_gen
cargo run
cd ../../..
cp livesplit-core/capi/bindings/LiveSplitCore.rb .
cp livesplit-core/target/release/liblivesplit_core.so .

# Install ruby dependencies
bundle install
```

Basic Usage
-----------

```
$ bundle exec ruby bin/redtimer.rb -h
Usage: redtimer [options]
    -L, --layout=FILENAME
    -S, --splits=FILENAME
    -s, --segments=SEGMENTS
        --game=NAME
        --category=NAME
        --timer-font=FONT
        --autosplitter=SCRIPT
        --autosplitter-events=EVENTS
        --autosplitter-debug
    -C, --config=FILENAME
```

You can load splits created with livesplit, or provide game, category, and
segment names on the command-line.

The config format is a json object with the above arguments as keys.
See [super_metroid_autosplit.json](configs/super_metroid_autosplit.json)
for an example.

Redtimer can use any font supported by Toilet.  Run
`demos/toilet_demo.rb` to see examples.

Loading layout files does not yet work.

Key bindings
------------

Key bindings are not (yet) configurable.

| Key     | Action                   |
| ------- | ------------------------ |
| `Space` | Toggle pause or start    |
| `Enter` | Split                    |
| `s`     | Skip split               |
| `u`     | Undo split               |
| `p`     | Timer pause (not toggle) |
| `r`     | Reset timer              |
| `q`     | Quit                     |
| `S`     | Save splits              |


Autosplitters
-------------

Autosplitters for redtimer are written in ruby and are modeled after the
autosplitters in [livesplit-core](https://github.com/CryZe/livesplit-core/tree/auto-splitting).
The intent is that once autosplitters are part of the mainline
livesplit-core, it will be easy to port them to wasm using
[wruby](https://github.com/pannous/wruby) or
[rlang](https://github.com/ljulliar/rlang).

To write an autosplitter for redtimer, create a class that inherits from
`Redtimer::Autosplitter` and implement the appropriate methods.

The mechanism provided for reading from game memory is Retroarch's
Network control interface.  This protocol allows an application to read
from game memory, without having to know where the process stores game
RAM.  This allows the autosplitter to work without modification across
different versions of retroarch.

Network control is disable by default in Retroarch.  To enable it, go to
Settings, then Network, and enable Network Commands.  The port must be
the default port (55354).

See [super_metroid_autosplitter.rb](autosplitters/super_metroid_autosplitter.rb)
for an example.

Other terminal-based timers
---------------------------

Other great timers for your terminal:

* [livesplit-one-terminal](https://github.com/CryZe/livesplit-one-terminal) -
  a very simple terminal-based timer built on livesplit-core, written in
  Rust
* [pyvesplit-terminal](https://github.com/stevensmedia/pyvesplit-terminal) -
  a port of livesplit-one-terminal to python.  Uses pyfiglet to draw a
  big timer.
* [flitter](https://github.com/alexozer/flitter) - a clone of livesplit
  written in ocaml.  Uses custom code to draw a big timer, and some nice
  eye candy.
