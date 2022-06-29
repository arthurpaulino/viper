# viper

`viper` is a Python environment management tool built in Lean 4.

It not only does environment management but also unifies the calls for `python` and `pip` binaries.

It's inspired on Julian Berman's [venvs](https://pypi.org/project/venvs/), which eliminates the need for environment activation/deactivation.
Instead, directories are linked to environments in a list persisted on a text file (`$HOME/.viper/links`).
Calling `viper` to run as a frontend for `python` or `pip` will trigger a lookup on that file.
That's how `viper` knows which environment to use.

**Important**: It's only been tested on Ubuntu!

## Installation

You'll need [Lean 4's tooling](https://github.com/leanprover/elan) to build viper.

Run `lake script run setup`, which will build `viper` and ask you where to place its binary.
You can place it in a directory that's already in your path, for example.

## Usage

Again, you can use `viper` to manage environments or as an interface for `python` and `pip`:

* Create a new environment with `viper new my-env`
* Link the current directory to an environment with `viper link my-env`
* Create and link in a single command with `viper new! my-env`
* Install packages with `viper install pkg1 pkg2`
* Run Python with `viper my_file.py`

Use `viper help` to see the full documentation:

```text
notation:
  * '$x' means an arbitrary input, to be referenced as `x`
  * '$[⋯ xs]' means an arbitrary sequence of inputs, to be referenced as `xs`

usage: `viper $COMMAND`, where `COMMAND` is:

  #### info
  help                 prints this menu being read
  links                shows the current links
  envs                 displays the list of environments
  env?                 shows the environment linked to this directory

  #### environment management
  new $env             creates a new environment named `env`
  new! $env            runs `new env` and links `env` to the current directory
  rename $env $env'    renames `env` to `env'`, keeping links consistent
  clone $env $env'     clones `env` to a new environment `env'`
  del $env             deletes the environment `env` and its links

  #### linking
  link $env            links the current directory to `env`
  unlink               removes any link for the current directory
  unlink dir $d        removes any link for the directory `d`
  unlink env $e        removes any links to the environment `e`

  #### maintenance
  fix                  if the current links file is corrupted, creates a new
                       (empty) one, backing up the old one
  health               searches for:
                        - inexistent linked directories
                        - inexistent linked environments
                        - unlinked environments
  prune                removes links for inexistent directories and environments
  prune!               runs `prune` but also deletes unlinked environments

  #### pip
  install $[⋯ args]    runs `pip install` with arguments `args`
  uninstall $[⋯ args]  runs `pip uninstall` with arguments `args`

  #### python
  $f $[⋯ args]         runs Python interpreter on file `f` with arguments `args`
  -m $mod $[⋯ args]    runs module `mod` with arguments `args`
  <nil>                runs Python's REPL
```
