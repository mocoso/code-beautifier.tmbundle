#!/usr/bin/ruby -w

=begin
/***************************************************************************
 *   Copyright (C) 2008, Paul Lutus, Joel Chippindale                      *
 *                                                                         *
 *   This program is free software: you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation, either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 *                                                                         *
 ***************************************************************************/
=end

require File.dirname(__FILE__) + '/rbeautify/block.rb'
require File.dirname(__FILE__) + '/rbeautify/block_matcher.rb'
require File.dirname(__FILE__) + '/rbeautify/line.rb'

module RBeautify

  def RBeautify.beautify_string(source)
    dest = ""
    stack = []

    source.split("\n").each do |line_content|
      line = RBeautify::Line.new(line_content, stack)
      dest += line.format + "\n"
      stack = line.stack
    end

    # TODO: Decide how to inform users of indentation error
    # if(!stack.empty?)
    #   raise "#{path}: Indentation error"
    # end

    return dest
  end

  def RBeautify.beautify_file(path, backup = false)
    if(path == '-') # stdin source
      source = STDIN.read
      print beautify_string(source,"stdin")
    else # named file source
      source = File.read(path)
      dest = beautify_string(source)
      if(source != dest)
        if backup
          # make a backup copy
          File.open(path + "~","w") { |f| f.write(source) }
        end
        # overwrite the original
        File.open(path,"w") { |f| f.write(dest) }
      end
      return source != dest
    end
  end # beautify_file

  def RBeautify.main
    if(!ARGV[0])
      STDERR.puts "usage: Ruby filenames or \"-\" for stdin."
        exit 0
    end
    ARGV.each do |path|
      RBeautify.beautify_file(path)
    end
  end # main


end # module RBeautify

# if launched as a standalone program, not loaded as a module
if __FILE__ == $0
  RBeautify.main
end
