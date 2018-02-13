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

DEFAULT_SHELL = '/bin/bash'
HELP_TXT = File.read(File.join(ROOT, 'help.txt'))
VERSION = 'ShortStrokes 1.0'

VALID_ARGUMENTS = {
	single: {
		help:          [["h"],                               false],
		version:       [["v"],                               false],
		config:        [["c"],                               true],
		force:         [["f"],                               false],
		shell:         [["s"],                               true],
		text_padding:  [["p"],                               true],
		exec_bg:       [["b"],                               false],
		exec_fg:       [["f"],                               false]
	},
	double: {
		help:          [["help"],                            false],
		version:       [["version"],                         false],
		config:        [["config"],                          true],
		force:         [["force"],                           false],
		shell:         [["shell"],                           true],
		text_padding:  [["text_padding"],                    true],
		exec_bg:       [["bg","exec-background","exec-bg"],  false],
		exec_fg:       [["fg","exec-foreground","exec-fg"],  false]
	}
}

def handle_arguments args
	return  if (args.nil? || args[:options].nil?)
	settings = {}
	if    (args[:options][:help])
		puts HELP_TXT
		exit

	elsif (args[:options][:version])
		puts VERSION
		exit
	end

	## Config File
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

	## Shell
	if (shell = args[:options][:shell])
		unless (shell.downcase == 'false')
			settings[:shell] = shell
		else
			settings[:shell] = false  # Don't use shell, execute command directly
		end
	end

	## Text Padding
	if (padding = args[:options][:text_padding])
		settings[:text_padding] = padding.to_i
	end

	## Execute Command In Background
	if (args[:options][:exec_bg])
		settings[:exec_bg] = true
	end

	## Execute Command In Foreground
	if (args[:options][:exec_fg])
		settings[:exec_bg] = false
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

ARGUMENTS = ArgumentParser.get_arguments VALID_ARGUMENTS
argument_settings = handle_arguments ARGUMENTS

# Get settings from config file
config = argument_settings[:config] || get_config_file
# Set config
CONFIG = config['config'] ? (config['config'].map do |k,v|
	# Convert 'true' and 'false' strings to booleans
	if    (v.is_a?(String) && v.downcase == 'true')
		next [k.to_sym, true]
	elsif (v.is_a?(String) && v.downcase == 'false')
		next [k.to_sym, false]
	end
	next [k.to_sym, v]
end .to_h) : {}
# Convert string keys in hash to symbols
argument_settings.each do |key,val|
	next  if (key == :config)
	CONFIG[key] = val
end
# Set keybindings
KEYBINDINGS = config['keybindings']

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
		@width = [Curses.cols, (CONFIG['width'] || 47)].min
		@height = [Curses.lines, (CONFIG['height'] || 7)].min

		@window = Curses::Window.new @height, @width, ((Curses.lines / 2) - (@height  / 2)), ((Curses.cols / 2) - (@width / 2))
		@window.box "|", "-"

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
			if (CONFIG[:exec_bg])
				## Execute command in background, instead of current shell
				if (CONFIG[:shell])
					pid = Process.spawn "#{SHELL} -c \"#{cmd}\"", out: "/dev/null", err: "/dev/null", pgroup: true
					Process.detach pid
				else
					cmd = cmd.gsub "~", Dir.home  # Replace '~' with full home path, because '~' doesn't work unless you start command bash
					pid = Process.spawn cmd, out: "/dev/null", err: "/dev/null", pgroup: true
					Process.detach pid
				end
			else
				## Execute command in current process
				if (CONFIG[:shell])
					## Execute command in new shell
					`#{SHELL} -c \"#{cmd}\"`
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
		@window.box "|", "-"
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

