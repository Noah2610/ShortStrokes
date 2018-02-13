# ShortStrokes
### by Noah Rosenzweig

A simple shortcut script using vim-like keystrokes.  
Written in Ruby using the Curses library.

---

## Installation
Run `git clone https://github.com/Noah2610/ShortStrokes.git` and  
have Ruby (probably like 2.0 or up)  
and ruby-bundler installed, then just run  
`bundle install` in the root of the project and after that  
you should be able to run `./ShortStrokes.rb` without any issues.

## Usage
The basic usage of this script is to bind it to a keyboard shortcut  
and define your desired keybindings as shell script  
in a keybindings YAML file.  
After you have entered text inside the program,  
use the escape key to clear it or to exit the script when the input is empty.  

## Configuration
This script looks for a keybindings/config (yaml) file  
in the following order / locations:
* ~/.config/shortstrokes/keybindings.yml
* ~/.shortstrokes.yml
* \<PROJECT-ROOT\>/keybindings.yml
  
This is overwritten when using the --config option.  
A default config file is included with the project
in `./keybindings.yml`.

## Arguments / Options
```
-h, --help
    Show help text, basically this README
-v, --version
    Show version
-c, --config FILE
    Use keybindings config file FILE (yaml)
-f, --force
    Ignore error when using --config with a file
    without a .yml or .yaml extension
```

