# Code Beautifier Textmate Bundle

Textmate's indent functionality does a reasonable job of formatting your code BUT there is a great deal of room for improvement.

Code Beautifier only supports Ruby at present but does improve upon Textmate's indent functionality, in particular it is better at indenting multiline statements and cleans up white space.

## Installation

Run this:

    cd ~/Library/Application\ Support/TextMate/Bundles
    git clone git://github.com/mocoso/code-beautifier.tmbundle.git Code\ Beautifier.tmbundle

Then select 'Bundles > Bundle Editor > Reload Bundles' from Textmate's menus

## Dependencies

The 'Beautify all changed' command relies on

 - Your project using Git for source control
 - The Grit gem being installed

        sudo gem sources -a http://gems.github.com/
        sudo gem install mojombo-grit)

## TODO

 - Make multiline string handling work with delimiters other than double quote
 - Add support for blocks with an implicit end e.g. private
 - Parse lines for code blocks that begin and end on the same line
 - Add support for multiple code blocks ending on the same line

## Credits

This was based on the [ruby beautifier script][rbs] by Paul Lutus and [Beautiful Ruby in Textmate][brit] by Tim Burks

  [rbs]:http://www.arachnoid.com/ruby/rubyBeautifier.html
  [brit]:http://blog.neontology.com/posts/2006/05/10/beautiful-ruby-in-textmate
