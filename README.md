# 1pass

**1pass** is a caching wrapper for the [1Password
CLI](https://support.1password.com/command-line-getting-started/) `op`.

## Introduction

**1pass** is designed to make using your 1Password usernames and passwords quick and easy. It is
intended for use within an interactive shell as well as from scripts. Once installed and configured
as described below, you can obtain an account password in a shell simply by typing:

```sh
$ 1pass Github
```

and your Gitbub password will be copied to the clipboard.

The official 1Password CLI application (```op```) can be difficult to use interactively, and unlike
the Mac OS X or Windows 1Password native applications, requires an internet connection to fetch data
from your password vaults. **1pass** solves both of these problems. ```Op``` needs session tokens to
be revalidated manually after 30 minutes of inactivity and produces rich output in JSON format. The
JSON output is easy for a program to use, but is not trivially consumed by humans without help.
**1pass** provides that help, with two main features:

- a simplified interface for listing and fetching usernames, passwords, and other fields for
  individual items.
- an encrypted local cache of 1Password CLI results.

Together these features enable easy use of 1Password-stored credentials.

[![asciicast](https://asciinema.org/a/eiE9JmHW0um7Ee0FVj488GYo6.png)](https://asciinema.org/a/eiE9JmHW0um7Ee0FVj488GYo6)


## Installation

First make sure that the `op` [1Password
CLI](https://support.1password.com/command-line-getting-started/) and the `jq` [JQ](https://stedolan.github.io/jq) are installed. If you use homebrew cask on Mac OS X, this works well:

```sh
$ brew cask install 1password-cli
$ brew install jq
```

Copy the 1pass executable file to a suitable location on your PATH (for example, /usr/local/bin)
and ensure that it is executable. For example:

```sh
curl https://raw.githubusercontent.com/dcreemer/1pass/master/1pass > /usr/local/bin/1pass
chmod a+x /usr/local/bin/1pass
```

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
configured in the ~/.1pass/config file.

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

**1pass** can lookup other fields besides username or password. They field name is the "label" for
the field in the 1Password GUI.

```sh
$ 1pass -p MyBankAccount pin
1234
```

**1pass** has special support for TOTP fields -- these are fetched directly via `op`
rather than a local cache. (Thanks to (@ev0rtex)[https://github.com/ev0rtex]).

```sh
$ 1pass -p MyBankAccount totp
9865432
```

**1pass** can be nicely combined with [fzf](https://github.com/junegunn/fzf) for fuzzy search and
completion. See [fuzzpass.sh](fuzzpass.sh) or
[fuzzpass.fish](fuzzpass.fish) for sample integration functions.

## Emacs

For the brave, a trivial Emacs wrapper library is included. E.g.

```elisp
(setq freenode-nick-username (1pass--item-username "Freenode/nick1"))
(setq freenode-nick-password (1pass--item-password "Freenode/nick1"))
(setq freenode-nick-password (1pass--item-field "Freenode" "server"))
```

## Caching and Sessions

When using **1pass**, all response data from 1Password is encrypted and then cached to
```~/.1pass/cache```. Sometimes this cache will be out of date -- for example if you have created a
new password entry via the 1Password application. Passing ```-r``` to **1pass** will force a refresh
from the online 1Password vault.

Similarly, 1Password CLI sessions last for 30 minutes from the time of last use. **1pass** will
manage the session for you, and refresh it as needed.

## License

Copyright (c) 2017, David Creemer (twitter: [@dcreemer](https://twitter.com/dcreemer)) with some
components from other GPL 2+ software.

[GPL3](https://raw.githubusercontent.com/dcreemer/1pass/master/LICENSE)

## Credits

Some ideas, and a tiny bit of code are taken from [pass](https://www.passwordstore.org) by Jason
A. Donenfeld. 
