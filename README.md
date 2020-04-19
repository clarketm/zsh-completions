zsh-completions ![GitHub release](https://img.shields.io/github/release/clarketm/zsh-completions.svg)
==================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================

**Additional completion definitions for [Zsh](http://www.zsh.org).**

This project aggregates zsh completions from:
1. [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions)
2. [zchee/zsh-completions](https://github.com/zchee/zsh-completions)
3. [nilsonholger/osx-zsh-completions](https://github.com/nilsonholger/osx-zsh-completions)
4. and *various* other [custom](/custom) or third-party sources.

*This projects aims at gathering/developing new completion scripts that are not available in Zsh yet. The scripts may be contributed to the Zsh project when stable enough.*


## Usage

### Using zsh frameworks

#### [antigen](https://github.com/zsh-users/antigen)

Add `antigen bundle clarketm/zsh-completions` to your `~/.zshrc`.

#### [oh-my-zsh](http://github.com/robbyrussell/oh-my-zsh)

* Clone the repository inside your oh-my-zsh repo:

        git clone https://github.com/clarketm/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

* Enable it in your `.zshrc` by adding it to your plugin list and reloading the completion:

        plugins=(... zsh-completions)
        autoload -U compinit && compinit

### Manual installation

* Clone the repository:

        git clone git://github.com/clarketm/zsh-completions.git

* Include the directory in your `$fpath`, for example by adding in `~/.zshrc`:

        fpath=(path/to/zsh-completions/src $fpath)

* You may have to force rebuild `zcompdump`:

        rm -f ~/.zcompdump; compinit


## License
Completions use the Zsh license, unless explicitly mentioned in the file header.
See [LICENSE](https://github.com/zsh-users/zsh-completions/blob/master/LICENSE) for more information.
