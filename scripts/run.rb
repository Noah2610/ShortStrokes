#!/bin/env ruby

### Simple script to make running shell script in specific shell
### in specific terminal emulator with specific parameters easier.

require 'pathname'
ROOT = File.dirname(Pathname.new(File.absolute_path(__FILE__)).realpath)

if (Gem::Specification.find_all_by_name('argument_parser').any?)
	require 'argument_parser'
else
	require File.join(ROOT, '../argument_parser')
end

## Set stdout and stderr for both this script and the executed command.
# TODO:
# Make stdout and stderr for run.rb and for executed command
# be available CL options; remove this hard-coding:
OUTDIR = File.join ROOT, '.run_out'
Dir.mkdir OUTDIR  unless (File.directory? OUTDIR)
#$stdout.reopen(File.join(OUTDIR, 'run_stdout'), "w")
#$stderr.reopen(File.join(OUTDIR, 'run_stderr'), "w")
CMDOUT = File.join OUTDIR, 'cmd_stdout'
CMDERR = File.join OUTDIR, 'cmd_stderr'

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
	'    e, edit FILE1 [FILE2 ...]',
	'      Start terminal emulator (-t) with role (-r) and shell (-s)',
	'      and edit file(s) FILE1 [, FILE2, ...] with editor (-e).',
	'    r, run exec COMMAND1 [COMMAND2 ...]',
	'      Start terminal emulator (-t) with role (-r) and shell (-s)',
	'      and run command COMMAND1 [, then COMMAND2, ...].',
	'      Multiple commands are chained together using a semi-colon (\';\')',
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
	shell:    '/bin/bash --login',
	editor:   'vim',
	role:     nil
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
		edit:      [['edit','e'],       :INPUTS],
		run:       [['run','r','exec'], :INPUTS]
	}
}

ARGUMENTS = ArgumentParser.get_arguments VALID_ARGUMENTS

## Show help text and exit
if (ARGUMENTS[:options][:help])
	puts HELP
	exit
end

## Get keyword chain
abort 'Error: No keywords given. Nothing to do.'        if (ARGUMENTS[:keywords].empty?)

## Set settings from options
TERMINAL = ARGUMENTS[:options][:terminal] || DEFAULTS[:terminal]
SHELL    = ARGUMENTS[:options][:shell]    || DEFAULTS[:shell]
EDITOR   = ARGUMENTS[:options][:editor]   || DEFAULTS[:editor]
ROLE     = ARGUMENTS[:options][:role]     || DEFAULTS[:role]

## Handle Keyword(s)
# Edit
if    (edit = ARGUMENTS[:keywords][:edit])
	to_edit = edit[1 .. -1]
	abort "Error: No file(s) given."                      if (to_edit.empty?)
	abort [
		"Error: One of the files given doesn't exist:",
		"  #{to_edit.join(",\n")}"
	].join("\n")                                          if (to_edit.any? { |f| !File.exists?(f) })
	pid = Process.spawn "#{TERMINAL}#{ROLE ? " --role '#{ROLE}'" : ""} --exec '#{SHELL} -c \"#{EDITOR} #{to_edit.join(' ')}\"'", out: CMDOUT, err: CMDERR, pgroup: true
	Process.detach pid

# Run
elsif (run = ARGUMENTS[:keywords][:run])
	to_run = run[1 .. -1].join '; '
	abort "Error: No command(s) given."                   if (to_run.empty?)
	pid = Process.spawn "#{TERMINAL}#{ROLE ? " --role '#{ROLE}'" : ""} --exec '#{SHELL} -c \"#{to_run}\"'", out: CMDOUT, err: CMDERR, pgroup: true
	Process.detach pid

end

