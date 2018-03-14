#!/bin/env ruby

## Reverse clipboard content and set to clipboard

clip = `xclip -o -selection clipboard`.strip
`echo -n "#{clip.reverse}" | xclip -i -selection clipboard`

