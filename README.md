# 1pass

**1pass** is a caching wrapper for the [1Password
CLI](https://support.1password.com/command-line-getting-started/) `op`.

![Shellcheck](https://github.com/dcreemer/1pass/workflows/shellcheck/badge.svg)

## UPGRADE NOTE

Upgrading to version 1.1 requires installation of the
[expect](https://core.tcl.tk/expect/index) tool. `1pass` will check for this (and
other) dependencies and remind you to install them.

## Introduction

**1pass** is designed to make using your 1Password usernames and passwords quick and easy. It is
intended for use within an interactive shell as well as from scripts. Once installed and configured
as described below, you can obtain an account password in a shell simply by typing:

```sh
$ 1pass Github
```

and your Github password will be copied to the clipboard.

The official 1Password CLI application (```op```) can be difficult to use interactively, and unlike
the macOS or Windows 1Password native applications, requires an internet connection to fetch data
from your password vaults. **1pass** solves both of these problems. ```Op``` needs session tokens to
be revalidated manually after 30 minutes of inactivity and produces rich output in JSON format. The
JSON output is easy for a program to use, but is not trivially consumed by humans without help.
**1pass** provides that help, with two main features:

- a simplified interface for listing and fetching usernames, passwords, and other fields for
  individual items.
- an encrypted local cache of 1Password CLI results.

Together these features enable easy use of 1Password-stored credentials.

## Installation

First make sure that the `op` [1Password
CLI](https://support.1password.com/command-line-getting-started/) and the `jq`
[JQ](https://stedolan.github.io/jq) and
[expect](https://core.tcl.tk/expect/index) requirements are installed. If you use
homebrew cask on macOS, this works well:

```sh
$ brew install 1password-cli
$ brew install jq expect
```

If you want to automate 2FA (TOTP) logging into 1password.com, then also install the oathtool, and
see further instructions below.

```sh
$ brew install oath-toolkit
```

Copy the 1pass executable file to a suitable location on your PATH (for example, /usr/local/bin)
and ensure that it is executable. For example:

```sh
curl https://raw.githubusercontent.com/dcreemer/1pass/master/1pass > /usr/local/bin/1pass
chmod a+x /usr/local/bin/1pass
```

### Bash Completion

If you would like to install bash-completion for 1pass, place the `bash-completion.sh` script in
and accessible location and then source it from your `.bash_profile`.  For example:

```sh
mkdir -p /usr/local/etc/1pass
curl https://raw.githubusercontent.com/dcreemer/1pass/master/bash_completion.sh > /usr/local/etc/1pass/bash_completion.sh
echo "source /usr/local/etc/1pass/bash_completion.sh" >> ~/.bash_profile
```

By default the completion script will look for `fzf` completion support in your environment. If present, 
it will use fzf completion ([see here](https://github.com/junegunn/fzf#fuzzy-completion-for-bash-and-zsh)). 

_Note: If you have installed `fzf` using homebrew on macOS, make sure you have enabled completion by
running `$(brew --prefix)/opt/fzf/install --completion` and follow the prompts._

If you do not have fzf or if you turn this feature off it will revert to standard bash completion 
behavior. If you would like to explicitly disable FZF completion for 1pass, you can do so as follows:

```sh
export ONEPASS_FZF_COMPLETE=false
```
This line should be added to your `.bash_profile`

## Security and Warning

**1pass** requires you to store your 1Password master password in a local GPG-encrypted file. You
should inspect the source code to ensure that you trust the software, as well as read this
documentation to understand the security tradeoffs.

Like the 1Password application itself, **1pass** relies on *one password*. However that password is
**not** your 1Password "master password" -- it is your Gnu Privacy Guard ([gpg](https://gnupg.org/))
private key. GPG, when configured to use the GPG-agent, will cache your private key password for a
configurable length of time (a few hours to a day is perhaps reasonable). **1pass** uses your GPG
key to store an encrypted copies of your 1Password master password and your 1Password account secret
key.

When data is needed from your online 1Password data store, the master password and secret key are
temporarily decrypted and exchanged for a session token, which is also then encrypted and stored.
The session token will be refreshed as needed. These actions happen automatically once your GPG key
is available in the GPG-agent.

The data that is fetched from the 1Password service is cached in local files -- once again also
encrypted using your GPG private key.

You can "lock" your **1pass** session by running the "forget" command:

```sh
$ 1pass -f
cleared local session
```

which removes the local session token (if any), and calls ```gpgconf --kill gpg-agent``` to purge
any running gpg-agent of your GPG secret keys.

## Configuration

In order to run with minimum user input, **1pass** relies on the Gnu Privacy Guard
[gpg](https://gnupg.org/) to encrypt all locally stored data. 1Password needs both a *master
password* and a *secret key* to access your vault. Each of these must be stored in an encrypted file
(in ~/.1pass or `$XDG_CONFIG_HOME/1pass`) for 1pass to work correctly. 1pass encrypts these and all other files
with your own gpg key. This key, as well as your 1Password login email and domain must be
configured in the ~/.1pass/config file. The domain is the full domain name that
you use to sign-in when you use the 1Password website, for example
`example.1password.com` or `subdomain.1password.ca`.

GPG can be configured to use the ```gpg-agent```, which can prompt for your *gpg* password, and
cache it in a local agent for a fixed amount of time. If you configure GPG this way, you will only
need to enter you GPG password (e.g.) once a day, and then seldom need to enter your 1Password
master password.

Running ```1pass -rv``` repeatedly will output instructions on how to configure this file and safely
store your master password and secret key.

```sh
$ ./1pass -rv
please config 1pass by editing /home/me/.1pass/config
$ vi ~/.1pass/config 
$ ./1pass -rv
please put your master password into /home/me/.1pass/_master.gpg
ex: echo "master-password" | gpg -er me@example.com > /home/me/.1pass/_master.gpg
$ echo "sEcre77" | gpg -er me@example.com > /home/me/.1pass/_master.gpg
$ ./1pass -rv
please put your mysubdomain.1password.com secret key into /home/me/.1pass/_secret.gpg
ex: echo "A3-XXXXXX-XXXXXX-XXXXX-XXXXX-XXXXX-XXXXX" | gpg -er me@example.com > /home/me/.1pass/_secret.gpg
$ echo "A3-XXXXXX-XXXXXX-XXXXX-XXXXX-XXXXX-XXXXX" | gpg -er me@example.com > /home/me/.1pass/_secret.gpg
$ ./1pass -rv
signing in to mysubdomain.1password.com me@example.com
...
```

## Usage

Once you are configured and signed in, you are ready to use **1pass**. The simplest command is
**1pass** with no arguments to list all items in your vault:

```sh
$ 1pass
Github
MyBankAccount
gmail.com
...
```

The list consists of the *titles* of each item. You can then retrieve the password of an item:

```sh
$ 1pass -p Github
sjd$kh23@0dfjs1DDj
```

The password is echoed to the standard output (when the '-p' option is used). You can easily use
this in scripts, for example:

```sh
export PGPASSWORD=$(1pass -p MyPostgresServer)
```

Without the '-p' option, 1pass copies the password to the clipboard:

```sh
$ 1pass Github
```

The contents of the clipboard will be automatically cleared after 30 seconds. You can also pass
**1pass** an optional field argument -- for example "username" to retrieve that field from the item:

```sh
$ 1pass -p MyBankAccount username
me@example.com
```

Sometimes it's easier to pass the title to search for via stdin, rather than as a command line
argument. Use the `-` character to force 1pass to read from stdin for the value.

```sh
$ echo "MyBankAccount" | 1pass -p - username
me@example.com
```

**1pass** can lookup other fields besides username or password. They field name is the "label" for
the field in the 1Password GUI.

```sh
$ 1pass -p MyBankAccount pin
1234
```

**1pass** has special support for TOTP fields -- these are fetched directly via `op`
rather than a local cache. (Thanks to (@ev0rtex)[https://github.com/ev0rtex]).
Note that this **is different** from using TOTP 2FA to log into your 1Password
account (that is supported too -- see below)

```sh
$ 1pass -p MyBankAccount totp
9865432
```

## FZF Integration

**1pass** can be nicely combined with [fzf](https://github.com/junegunn/fzf) for fuzzy search and
completion.

Starting with 1pass v1.5:

`1pass | fzf | 1pass -p -`

In older versions: See [fuzzpass.sh](fuzzpass.sh) or
[fuzzpass.fish](fuzzpass.fish) for sample integration functions.

## Emacs

For the brave, a trivial Emacs wrapper library is included. E.g.

```elisp
(setq freenode-nick-username (1pass--item-username "Freenode/nick1"))
(setq freenode-nick-password (1pass--item-password "Freenode/nick1"))
(setq freenode-nick-password (1pass--item-field "Freenode" "server"))
```

## Iterm2 integration

This integration lets you select and insert passwords into programs running in iTerm2(shell).  If you are tired of typing in your sudo password, this is for you.

This is effectively a clone of [sudolikeaboss](https://github.com/ravenac95/sudolikeaboss) functionality. with the caveat that all of your passwords are available, not just ones tagged x-sudolikeaboss

Using [choose](https://github.com/chipsenkbeil/choose) (a GUI fzf clone)

in iTerm2, go to preferences, then keys, add a new key `open-apple+/` to run coprocess and then copy paste in the command to run box:

`export PATH="/usr/local/bin:/usr/bin"; 1pass | choose | 1pass -p -`

Then start a program asking for input like `sudo -s` and then at the password prompt push the key you assigned earlier(`open-apple+/` above) and select the password title by typing or arrowing down/up and then hit enter.  It might take a second, as 1pass has to go fetch your password from 1pass, but it then should type in your password and hit enter for you.

If you run into trouble, iTerm2 should attach a little yellow bar at the top, select 'view errors' and it should then open a new window showing the output of the commands above, you will need to work through whatever issue comes up.

If you get a `Command not found error` You installed choose, 1pass or op other than `/usr/local/bin/`, you will need to edit the PATH part of the line above.

FZF will not work in place of choose, as coprocesses if they want to ask for user input need to happen in their own window.


## Caching and Sessions

When using **1pass**, all response data from 1Password is encrypted and then cached to
```~/.1pass/cache```. Sometimes this cache will be out of date -- for example if you have created a
new password entry via the 1Password application. Passing ```-r``` to **1pass** will force a refresh
from the online 1Password vault.

Similarly, 1Password CLI sessions last for 30 minutes from the time of last use. **1pass** will
manage the session for you, and refresh it as needed.

## 2FA for 1Password

If you have turned on two-factor authentication (2FA) support for your 1Password account, then
1pass will prompt for you to enter a TOTP code when creating a session. You can either re-enter
this code after every session expiration (30 minutes of inactivity), or automate entry of the code
using the oath-toolkit `oathtool` command. If you wish to automate the 2FA process, add
`use_totp="1"` to your config file, and follow the instructions to store the TOTP secret:

```sh
$ ./1pass -rv
please put your ${domain} totp secret into /home/me/.1pass/_totp.gpg
ex: echo \"XXXXXXXXXXXXXXXX\" | $GPG -er $email > /home/me/.1pass/_totp.gpg
```

## License

Copyright (c) 2017-2019, David Creemer (twitter:
[@dcreemer](https://twitter.com/dcreemer)) with some components from other GPL 2+
software.

[GPL3](https://raw.githubusercontent.com/dcreemer/1pass/master/LICENSE)

## Credits

Some ideas, and a tiny bit of code are taken from [pass](https://www.passwordstore.org) by Jason
A. Donenfeld. Please see the git commit log for contributions from others.
