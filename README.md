# 1pass

**1pass** is a caching wrapper for the [1Password
CLI](https://support.1password.com/command-line-getting-started/) ```op```.

## Introduction

The 1Password CLI can be somewhat difficult to use, and unlike the Mac OS X or Windows 1Password
native applications, requires and internet connection to fetch data from your password vaults.
**1pass** solves both of problems.

**1pass** provides two main features:

- a simplified interface for listing and fetching usernames and passwords for individual items.
- an encrypted local cache of 1Password 

## Installation

**WARNING** 1pass stores you 1Password master password in a local GPG-encrypted file. You should
inspect the source code to ensure that you trust it.

Copy the 1pass executable file to a suitable location on your PATH (for example, /usr/local/bin)
and ensure that it is executable. For example:

```sh
curl https://raw.githubusercontent.com/dcreemer/1pass/master/1pass > /usr/local/bin/1pass
chmod a+x /usr/local/bin/1pass
```

## Configuration

In order to run with minimum user input, **1pass** relies on the Gnu Privacy Guard
[gpg](https://gnupg.org/) to encrypt all locally stored data. 1Password needs both a *master
password* and a *secret key* to access your vault. Each of these must be stored in an encrypted file
(in the ~/.1pass) directory for 1pass to work correctly. 1pass encrypts these and all other files
with your own gpg key. This key, as well as your 1Password login email and subdomain must be
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
signing in mysubdomain.1password.com me@example.com
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
$ 1pass Github
sjd$kh23@0dfjs1DDj
```

The password is echoed to the standard output, ready for copy / pasting. You can easily use this in
scripts, for example:

```sh
export PGPASSWORD=$(1pass MyPostgresServer)
```

You can also pass **1pass** an optional field argument -- for example "username" to retrieve that
field from the item:

```sh
$ 1pass MyBankAccount username
me@example.com
```

**1pass** can be nicely combined with [fzf](https://github.com/junegunn/fzf) for fuzzy search and
completion. Install ```fzf```, then paste this function into your shell:

```sh
fuzzpass() {
    local arg=$1
    if [ "$arg" == "" ]; then
        arg="password"
    fi
    local item=$(1pass | fzf);
    [[ ! -z "$item" ]] && 1pass $item
}
```

the type ```fuzzpass```, select the Item, and press enter.


## Caching and Sessions

When using **1pass**, all response data from 1Password is encrypted and then cached to
```~/.1pass/cache```. Sometimes this cache will be out of date -- for example if you have created a
new password entry via the 1Password application. Passing ```-r``` to **1pass** will force a refresh
from the online 1Password vault.

Similarly, 1Password CLI sessions last for 30 minutes from the time of last use. **1pass** will
manage the session for you, and refresh it as needed.

## License

Copyright (c) 2017, David Creemer (twitter: @dcreemer)

GPLv3
