#!/bin/env ruby

# Randomize letter cases of clipboard content and set to clipboard
clip = `xclip -o -selection clipboard`.strip
new_clip = ''
clip.each_char do |char|
	if (rand(2) == 0)
		new_clip += char
	else
		new_clip += char.swapcase
	end
end
`echo -n '#{new_clip}' | xclip -i -selection clipboard`
