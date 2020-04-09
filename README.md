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

Redtimer does support autosplitter scripts written in ruby.  They are
intended to be similar to autosplitter functionality currently being
implemented for Livesplit One.  Inherit from the
`Redtimer::Autosplitter` class and implement the required methods.  See
[super_metroid_autosplitter.rb](autosplitters/super_metroid_autosplitter.rb)
for an example.

Redtimer can use any font supported by Toilet.  Run
`demos/toilet_demo.rb` to see examples.

Loading layout files does not yet work.
