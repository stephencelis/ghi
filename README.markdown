# ghi

<https://github.com/stephencelis/ghi>

GitHub Issues on the command line. Use your `$EDITOR`, not your browser.


## Install

Via brew:
``` sh
$ brew install ghi
```

Via curl:
``` sh
$ curl -s https://raw.github.com/stephencelis/ghi/master/ghi > ghi && \
  chmod 755 ghi && \
  mv ghi /usr/local/bin
```

Via gem:
``` sh
$ gem install ghi
```


## Usage

```
usage: ghi [--version] [-p|--paginate|--no-pager] [--help] <command> [<args>]
           [ -- [<user>/]<repo>]

The most commonly used ghi commands are:
   list        List your issues (or a repository's)
   show        Show an issue's details
   open        Open (or reopen) an issue
   close       Close an issue
   edit        Modify an existing issue
   comment     Leave a comment on an issue
   label       Create, list, modify, or delete labels
   assign      Assign an issue to yourself (or someone else)
   milestone   Manage project milestones
   find        Search for issues by keywords

See 'ghi help <command>' for more information on a specific command.
```


## Configuration

By default, ghi looks for GitHub issues by resolving the current working
directory's repository: first it looks for an `upstream` remote, then it
looks at `origin`.

You can override the repository ghi uses by setting the local `ghi.repo`
git configuration variable:

``` sh
$ git config ghi.repo username/reponame
$ ghi list
# username/reponame open issues
...
```

## Additional help

### Enable 256 colours in Ubuntu bash terminal.

* run `tput colors` this should output `8`
* run `sudo apt-get install ncurses-term`
* open `nano ~/.bashrc` and add `export TERM=xterm-256color` at the bottom
* reload bash config `source ~/.bashrc`
* run `tput colors` this should output `256`

Close and reopen any other open terminals.

### Syntax highlighting of embedded code blocks

In case you use a 256 color terminal, ghi is able to syntax highlight
[fenced code blocks](https://help.github.com/articles/github-flavored-markdown#syntax-highlighting).

To enable this feature you just need to install the ruby wrapper for
[pygments](http://pygments.org/):

``` sh
gem install pygments.rb
```

Additionally you can specify the used colorset through your `gitconfig` file(s).

``` sh
git config --global --add ghi.highlight.style colorful
```

Fire up an `irb/pry` session with the following to see a list of available
colorsets:

``` ruby
require 'pygments'
Pygments.styles
```

## Screenshot

![Example](images/example.png)


## LICENSE

(The MIT License)

© 2009–2013 Stephen Celis (<stephen@stephencelis.com>).
json-pure © Genki Takiuchi.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
