#!/bin/env ruby

require 'curses'
require 'yaml'
require 'pathname'

ROOT = File.dirname(Pathname.new(File.absolute_path(__FILE__)).realpath)

KEYBINDINGS = YAML.load_file File.join(ROOT, 'keybindings.yml')

class MainWindow
	def initialize
		Curses.init_screen
		Curses.crmode
		Curses.noecho
		Curses.curs_set 0
		@width = [Curses.cols, 47].min
		@height = [Curses.lines, 7].min

		@window = Curses::Window.new @height, @width, ((Curses.lines / 2) - (@height  / 2)), ((Curses.cols / 2) - (@width / 2))
		@window.box "|", "-"

		@window.setpos (@height / 2), (@width / 2)

		@text = ""
		# Padding between edges of window and text
		@text_padding = 8
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

	def check_text
		if (cmd = KEYBINDINGS[@text])
			pid = Process.spawn cmd, out: "/dev/null", err: "/dev/null", pgroup: true
			Process.detach pid
			exit
		end
	end

	def update_text
		max_width = @width - @text_padding
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

main_window = MainWindow.new

running = true
while running
	main_window.update
end

