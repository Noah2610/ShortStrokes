ShortStrokes
  by Noah Rosenzweig

  A simple shortcut script using vim-like keystrokes.
  Written in Ruby using the Curses library.

  It also uses my Ruby Argument Parser to parse command-line options.
  ArgumentParser: https://github.com/Noah2610/ArgumentParser


DESCRIPTION
  When started, this script greets you with a Curses window in which you can
  type anything. Whenever your input is matched to a keybinding defined in
  your config, it will execute the associated shell script and exit.

  The basic usage of this script is to bind it to a keyboard shortcut
  and define your desired keybindings as shell script
  in a YAML configuration file.
  After you have entered text inside the program,
  use the escape key to clear it or to exit the script when the input is empty.

INSTALLATION
  Run
    $ git clone https://github.com/Noah2610/ShortStrokes.git
  and have Ruby (probably like 2.0 or up)
  and ruby-bundler installed, then just run
    $ bundle install
  in the root of the project and after that
  you should be able to run
    $ ./ShortStrokes.rb
  without any issues.

CONFIGURATION
  This script looks for a YAML configuration file
  in the following order / locations:
    - ~/.config/shortstrokes/config.yml
    - ~/.shortstrokes.yml
    - <PROJECT-ROOT>/config.yml
  You can define a custom config path with `--config`.
  A default config file is included with the project in ./config.yml.

  The configuration file consists of three sections:
    - 'config'
        This section can contain all command-line options;
        Use a double dash ('--') version of an option without the two dashes
        at the start, and separate it from the value with a colon (':').
        example:
          width: 47
    - 'constants'
        Here you can define any constants/variables you want to be able to use
        in your config. Use them by adding a '@' in front of its name,
        wherever you want it to be replaced by its associated value.
        Currently two constants are set by the script:
        `@SHORTSTROKES_ROOT`, this contains the full path to where the script
        is located; it is dynamically set everytime the script is called.
        `@SHELL`, is set to the shell defined in your config or
        from the command-line. The default shell is `/bin/bash`.
        example:
          # defining it:
            browser: 'firefox'
          # using it:
            ob: '@browser --new-window'
    - 'keybindings'
        This is where you actually define all your keystrokes
        and their associated shell script commands.
        The key is the keystroke and its value is the shell command.
        example:
          hw: 'echo "Hello World!"'

COMMAND-LINE USAGE
  SYNOPSIS
    ShortStrokes [OPTIONS]
    ShortStrokes --config /PATH/TO/CONFIG.yml

  OPTIONS
    Here is a list of all available command-line options.
    Any double dash ('--') version of an option can be used
    in the config file under the 'config' section.

    -h, --help
      Show help text, basically this README;
      and exit.

    -v, --version
      Show version;
      and exit.

    -c, --config FILE
      Use configuration file FILE.

    -f, --force
      Ignore error when using --config with a file
      without a .yml or .yaml extension.

    -w, --width, --cols, --columns CHARS
      The width/columns in characters used for the Curses window.

    -h, --height, --rows, --lines CHARS
      The height/lines used for the Curses window.

    -s, --shell SHELL
      Use SHELL shell to execute commands.
      When set to 'false' it will execute the command directly,
      probably starting /bin/sh anyway.

    -p, --text-padding CHARS
      Text padding in CHARS characters,
      separating your text input from the borders.

    -b, --bg, --exec-background, --exec-bg
      If this flag is set, the command will be executed in another process
      in the background. It is recommended to have this option set to true
      in your config.

    -f, --fg, --exec-foreground, --exec-fg
      The inverse of --exec-background.
      Execute command from inside the ShortStrokes process.
      Not recommended, usually.

    --no-border, --borderless
      With this option set, the border of the Curses window
      will not be drawn. In case you want a cleaner view;
      can look nice without terminal window borders.

    --stdout, --cmdout, --cmd-stdout FILE
      Redirect stdout of executed command to FILE.

    --stderr, --cmderr, --cmd-stderr FILE
      Redirect stderr of executed command to FILE.

