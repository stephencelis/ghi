# ghi

[![Build Status](https://travis-ci.org/shubhamshuklaer/ghi.svg?branch=travis-ci)](https://travis-ci.org/shubhamshuklaer/ghi)

GitHub Issues on the command line. Use your `$EDITOR`, not your browser.

`ghi` was originally created by [Stephen Celis](https://github.com/stephencelis), and is now maintained by [drazisil](https://github.com/drazisil)'s fork [here](https://github.com/drazisil/ghi).

## Install

Via brew ([latest stable release](https://github.com/stephencelis/ghi/releases/latest)):
``` sh
brew install ghi
```

Via gem ([latest stable release](https://github.com/stephencelis/ghi/releases/latest)):
``` sh
gem install ghi
```

Via curl (latest bleeding-edge versions, may not be stable):
``` sh
curl -sL https://raw.githubusercontent.com/stephencelis/ghi/master/ghi > ghi && \
chmod 755 ghi && \
mv ghi /usr/local/bin
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
   lock        Lock an issue's conversation, limiting it to collaborators
   unlock      Unlock an issue's conversation, opening it to all viewers
   edit        Modify an existing issue
   comment     Leave a comment on an issue
   label       Create, list, modify, or delete labels
   assign      Assign an issue to yourself (or someone else)
   milestone   Manage project milestones
   status      Determine whether or not issues are enabled for this repo
   enable      Enable issues for the current repo
   disable     Disable issues for the current repo

See 'ghi help <command>' for more information on a specific command.
```

## Source Tree
You may get a strange error if you use SourceTree, similar to [#275](https://github.com/stephencelis/ghi/issues/275) and [#189](https://github.com/stephencelis/ghi/issues/189). You can follow the steps [here](https://github.com/stephencelis/ghi/issues/275#issuecomment-182895962) to resolve this.

## Contributing

If you're looking for a place to start, there are [issues we need help with](https://github.com/stephencelis/ghi/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22)!

Once you have an idea of what you want to do, there is a section in the [wiki](https://github.com/stephencelis/ghi/wiki/Contributing) to provide more detailed information but the basic steps are as follows.

1. Fork this repo
2. Do your work:
  1. Make your changes
  2. Run `rake build`
  3. Make sure your changes work
3. Open a pull request!

## FAQ

FAQs can be found in the [wiki](https://github.com/stephencelis/ghi/wiki/FAQ)

## Screenshot

![Example](images/example.png)

## Testing Guidlines
* You are encouraged to add tests if you are adding new feature or solving some
problem which do not have a test.
* A test file should be named as `something_test.rb` and should be kept in the
`test` folder. A test class should be named `Test_something` and a test 
function `test_something`. Helper functions must not start with `test`.
* Before running tests `GITHUB_USER` and `GITHUB_PASSWORD` environment
variables must be exported. It is best to use a fake account as a bug can mess
up your original account. You can either export these 2 environment variables 
through `~/.bashrc`(As ghi only uses these while generating its token, so after
you generate the token for your original account(for regular use), fake account
details can be exported) or you can pass it on command line, eg. `rake
test:one_by_one GITHUB_USER='abc' GITHUB_PASSWORD='xyz'`.
* Run `rake test:one_by_one` to run all the tests
* Check [Single Test](https://github.com/grosser/single_test) for better
control over which test to run. Eg. `rake test:assign:un_assign` will run a
test function matching `/un_assign/` in file `assign_test.rb`. One more eg.
`rake test:edit test:assign` will run tests `edit_test.rb` and
`assign_test.rb`. Or you can also use `ruby -I"lib:test" test/file_name.rb -n
method_name`
* By default, the repo and token created while testing will be deleted. But if
you want to see the state of repo and tokens after the test has run, then add
`NO_DELETE_REPO=1` and `NO_DELETE_TOKEN=1` to the command. For eg. `rake
test:assign NO_DELETE_REPO=1 NO_DELETE_TOKEN=1`.
* If you don't wanna run the tests locally use travis-ci. See section below.

## Enable Travis CI in fork

* Open a Travis CI account and activate travis-ci for the fork
* Create a fake github account for testing. The username, password and token
will be available to the tests and if by mistake the test prints it, it will be
available in public log. So its best to create a fake account and use a
password you are not using for anything else. Apart from security reasons,
bugs in tests or software can also mess up your original account, so to be
on safe side use a fake account.
* At Travis-CI, on the settings page for the fork, add environment variables
`GITHUB_USER` and `GITHUB_PASSWORD`. Ensure that the "Display value in build
log" is set to false. It is possible to add these in ".travis.yml", but don't
as all forks as well as original repo will be using different accounts(We cannot 
provide the details of a common account for testing because of security reasons) for
testing, so it will cause problems during merge.
* Note that the build status badge in the README points to the travis-ci page
for this repo, not the fork.
