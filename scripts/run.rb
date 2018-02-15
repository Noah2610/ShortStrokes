#!/bin/env ruby

### Simple script to make running shell script in specific shell
### in specific terminal emulator with specific parameters easier.

require 'argument_parser'

HELP = [
	'run.rb',
	'  DESCRIPTION',
	'    This simple script is just for ease of use when you want to',
	'    execute a command which will be started in a new terminal emulator',
	'    in a specific shell with some options.',
	'',
	'  SYNOPSIS',
	'    run.rb KEYWORD(s)... [OPTIONS]',
	'',
	'  KEYWORDS',
	'    edit FILE',
	'      Start terminal emulator (-t) with role (-r) and shell (-s)',
	'      and edit file FILE with editor (-e).',
	'    run COMMAND',
	'      Start terminal emulator (-t) with role (-r) and shell (-s)',
	'      and run command COMMAND.',
	'',
	'  OPTIONS',
	'    -h, --help',
	'      Show this help text.',
	'    -t, --terminal TERMINAL',
	'      Use terminal emulator TERMINAL.',
	'    -s, --shell SHELL',
	'      Use shell SHELL.',
	'    -e, --editor EDITOR',
	'      Use editor EDITOR.',
	'    -r, --role ROLE',
	'      Set role ROLE of terminal emulator.'
].join("\n")

DEFAULTS = {
	terminal: 'termite',
	shell:    '/bin/bash --login -i',
	editor:   'vim',
	role:     'FLOAT'
}

VALID_ARGUMENTS = {
	single: {
		help:      [['h'],              false],
		terminal:  [['t'],              true],
		shell:     [['s'],              true],
		editor:    [['e'],              true],
		role:      [['r'],              true]
	},
	double: {
		help:      [['help'],           false],
		terminal:  [['terminal'],       true],
		shell:     [['shell'],          true],
		editor:    [['editor'],         true],
		role:      [['role'],           true]
	},
	keywords: {
		edit:      [['edit','e'],       :INPUT],
		run:       [['run','r','exec'], :INPUT]
	}
}

ARGUMENTS = ArgumentParser.get_arguments VALID_ARGUMENTS

## Show help text and exit
if (ARGUMENTS[:options][:help])
	puts HELP
	exit
end

## Get keyword chain
abort 'Error: No keywords given. Nothing to do.'  if (ARGUMENTS[:keywords].empty?)

## Set settings from options
TERMINAL = ARGUMENTS[:options][:terminal] || DEFAULTS[:terminal]
SHELL =    ARGUMENTS[:options][:shell]    || DEFAULTS[:shell]
EDITOR =   ARGUMENTS[:options][:editor]   || DEFAULTS[:editor]
ROLE =     ARGUMENTS[:options][:role]     || DEFAULTS[:role]

## Handle Keyword(s)
# Edit
if    (edit = ARGUMENTS[:keywords][:edit])
	to_edit = edit[1]
	abort "Error: No file given."                    unless (to_edit)
	abort "Error: File '#{to_edit}' doesn't exist."  unless (File.exists? to_edit)
	pid = Process.spawn "#{TERMINAL} --role '#{ROLE}' --exec '#{SHELL} -c \"#{EDITOR} #{to_edit}\"'", out: '/dev/null', err: '/dev/null', pgroup: true
	Process.detach pid

# Run
elsif (run = ARGUMENTS[:keywords][:run])
	to_run = run[1]
	abort "Error: No command given."                 unless (to_run)
	pid = Process.spawn "#{TERMINAL} --role '#{ROLE}' --exec '#{SHELL} -c \"#{to_run}\"'", out: "/dev/null", err: "/dev/null", pgroup: true
	Process.detach pid
end

