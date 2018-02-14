#!/bin/env ruby

require 'curses'
require 'pathname'
require 'yaml'

ROOT = File.dirname(Pathname.new(File.absolute_path(__FILE__)).realpath)

require File.join(ROOT, 'ArgumentParser.rb')

CONFIG_PATHS = [
	File.join(Dir.home, '.config/shortstrokes/config.yml'),
	File.join(Dir.home, '.shortstrokes.yml'),
	File.join(ROOT, 'config.yml')
]

HELP_TXT = File.read(File.join(ROOT, 'help.txt'))
VERSION = 'ShortStrokes 1.0'
DEFAULT_SHELL = '/bin/bash'
DEFAULT_CONSTANTS = {
	'SHORTSTROKES_ROOT' => ROOT
}

VALID_ARGUMENTS = {
	single: {
		help:          [['h'],                               false],
		version:       [['v'],                               false],
		config:        [['c'],                               true],
		force:         [['f'],                               false],
		width:         [['w'],                               true],
		height:        [['h'],                               true],
		shell:         [['s'],                               true],
		text_padding:  [['p'],                               true],
		exec_bg:       [['b'],                               false],
		exec_fg:       [['f'],                               false]
	},
	double: {
		help:          [['help'],                            false],
		version:       [['version'],                         false],
		config:        [['config'],                          true],
		force:         [['force'],                           false],
		width:         [['width','cols','columns'],          true],
		height:        [['height','rows','lines'],           true],
		shell:         [['shell'],                           true],
		text_padding:  [['text-padding'],                    true],
		exec_bg:       [['bg','exec-background','exec-bg'],  false],
		exec_fg:       [['fg','exec-foreground','exec-fg'],  false],
		no_border:     [['no-border','borderless'],          false]
	}
}

def handle_arguments args
	return  if (args.nil? || args[:options].nil?)
	settings = {}
	## Help - help
	if    (args[:options][:help])
		puts HELP_TXT
		exit

	## Version - version
	elsif (args[:options][:version])
		puts VERSION
		exit
	end

	## Config File - config
	if (args[:options][:config])
		if (File.file?(args[:options][:config]))
			if (args[:options][:config].downcase =~ /\A.+\.(yml|yaml)\z/ || args[:options][:force])
				begin
					settings[:config] = YAML.load_file args[:options][:config]
				rescue
					abort [
						"Error: Seems like your config file (#{args[:options][:config]}) isn't a valid YAML file.",
						"  Please use a proper YAML configuration file."
					].join("\n")
				end
			else
				abort [
					"Error: File #{args[:options][:config]} doesn't have a YAML extension (.yml || .yaml).",
					"  If you are sure it is a YAML file, use -f or --force to ignore this error."
				].join("\n")
			end
		else
			abort "Error: File #{args[:options][:config]} doesn't exist."
		end
	end

	## Width - width
	if (width = args[:options][:width])
		settings[:width] = width
	end

	## Height - height
	if (height = args[:options][:height])
		settings[:height] = height
	end

	## Shell - shell
	if (shell = args[:options][:shell])
		settings[:shell] = shell
	end

	## Text Padding - text_padding
	if (padding = args[:options][:text_padding])
		settings[:text_padding] = padding.to_i
	end

	## Execute Command In Background - exec_bg
	if (args[:options][:exec_bg])
		settings[:exec_bg] = true
	end

	## Execute Command In Foreground - exec_fg
	if (args[:options][:exec_fg])
		settings[:exec_bg] = false
	end

	## No Border - no_border
	if (args[:options][:no_border])
		settings[:no_border] = true
	end

	return settings
end

def get_config_file
	ret = nil
	CONFIG_PATHS.each do |file|
		if (File.file? file)
			ret = YAML.load_file file
			break
		end
	end
	return ret
end

def replace_constants constants, hash, constant_key = '@'
	return hash  if (constants.nil?)
	return {}    if (hash.nil? || hash.empty?)
	hash_str = hash.to_s
	ret_str = hash_str.dup
	scanned = []
	hash_str.scan /#{'\\' + constant_key}\w+/ do |key|
		next  if (scanned.include? key)
		const = key.delete constant_key
		if (val = constants[const])
			ret_str.gsub! /#{key}/, val.to_s
			scanned << key
		else
			abort [
				"Error: Constant '#{key}' hasn't been defined.",
				"  Define it in your config under 'constants' to use it."
			].join("\n")
		end
	end
	return eval(ret_str)
end

ARGUMENTS = ArgumentParser.get_arguments VALID_ARGUMENTS
argument_settings = handle_arguments ARGUMENTS

# Get settings from config file
config_file_content = argument_settings[:config] || get_config_file

# Set Constants
CONSTANTS = DEFAULT_CONSTANTS.merge(replace_constants(DEFAULT_CONSTANTS, config_file_content['constants']))

# Set config
CONFIG = replace_constants(
	CONSTANTS,
	config_file_content['config'] ? (config_file_content['config'].map do |key,val|
		value = val.to_s =~ /\A[0-9]+\z/ ? val.to_i : val.to_s
		nex = [key.to_sym, value]
		# Convert 'true' and 'false' strings to booleans
		if    (value.downcase == 'true')
			nex[1] = true
		elsif (value.downcase == 'false')
			nex[1] = false
		end  if (value.is_a?(String))
		# Check VALID_ARGUMENTS for aliases
		unless (VALID_ARGUMENTS[:double][key.to_sym])
			VALID_ARGUMENTS[:double].each do |optk,optv|
				if (optv.first.include? key)
					nex[0] = optk
					next
				end
			end
		end
		next nex
	end .to_h) : {}
)

# Add command-line options to CONFIG
replace_constants(CONSTANTS, argument_settings).each do |key,val|
	next  if (key == :config)
	value = val.to_s =~ /\A[0-9]+\z/ ? val.to_i : val.to_s
	if    (value.downcase == 'true')
		value = true
	elsif (value.downcase == 'false')
		value = false
	end  if (value.is_a?(String))
	CONFIG[key] = value
end
CONFIG[:shell] = DEFAULT_SHELL  if (CONFIG[:shell].nil?)
# Set keybindings
KEYBINDINGS = replace_constants(
	CONSTANTS,
	config_file_content['keybindings']
)

abort [
	"Error: No keybindings given.",
	"  Check that your config file contains keybindings",
	"  under a key named 'keybindings'."
].join("\n")  if (KEYBINDINGS.nil?)


class ShortStroke
	def initialize
		Curses.init_screen
		Curses.crmode
		Curses.noecho
		Curses.curs_set 0
		@width = [Curses.cols, (CONFIG[:width] || 47)].min
		@height = [Curses.lines, (CONFIG[:height] || 7)].min

		@window = Curses::Window.new @height, @width, ((Curses.lines / 2) - (@height  / 2)), ((Curses.cols / 2) - (@width / 2))
		@window.box "|", "-"  unless (CONFIG[:no_border])

		@window.setpos (@height / 2), (@width / 2)

		@text = ""
		# Padding between edges of window and text
		@text_padding = CONFIG[:text_padding] || 4
	end

	def handle_input char = nil
		char ||= @window.getch
		case char
		# ESCAPE
		when 27
			if (@text.empty?)
				exit
			else
				@text.clear
				update_text
			end
		# BACKSPACE
		when 127
			@text = @text[0 .. -2]
			update_text
		# ENTER / RETURN
		when 10
			@text << "\n"
			update_text
		else
			@text << Curses.keyname(char)
			#@text << char
			update_text
			check_text
		end
		@window.refresh
	end

	## Check if @text is valid command,
	#  if it is, execute and exit
	def check_text
		if (cmd = KEYBINDINGS[@text])
			cmd = cmd.gsub "~", Dir.home  # Replace '~' with full home path
			if (CONFIG[:exec_bg])
				## Execute command in background, instead of current shell
				if (CONFIG[:shell])
					pid = Process.spawn "#{CONFIG[:shell]} -c '#{cmd}'", out: "/dev/null", err: "/dev/null", pgroup: true
					Process.detach pid
				else
					pid = Process.spawn cmd, out: "/dev/null", err: "/dev/null", pgroup: true
					Process.detach pid
				end
			else
				## Execute command in current process
				if (CONFIG[:shell])
					## Execute command in new shell
					`#{CONFIG[:shell]} -c '#{cmd}'`
				else
					## Just execute command, probably spawns /bin/sh anyway
					`#{cmd}`
				end
			end

			exit
		end
	end

	## Redraw and center @text to terminal
	def update_text
		max_width = @width - (@text_padding * 2)
		text_lns = @text.split("\n").map.with_index do |ln,index|
			if (ln.size > max_width)
				next (0 ... ((ln.size / (max_width)) + 1).floor).map do |n|
					next ln[((max_width) * n) ... ((max_width) * (n + 1))]
				end
			else
				next ln
			end
		end .flatten

		@window.clear
		@window.box "|", "-"  unless CONFIG[:no_border]
		text_lns.each_with_index do |ln,row_n|
			x = (@width / 2) - (ln.size / 2)
			y = (@height / 2) - ((text_lns.size / 2) - (row_n))
			@window.setpos y, x
			@window.addstr ln
		end
	end

	def update
		handle_input
	end

end

short_stroke = ShortStroke.new

running = true
while running
	short_stroke.update
end

