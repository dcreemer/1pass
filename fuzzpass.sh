# -*- shell-script -*-
#
# Use fzf (https://github.com/junegunn/fzf) to rapidly select an account,
# and run 1pass (with optional argument) on the result.
# To use this, source this file in your .bashrc or .profile as appropriate,
# e.g.
#
# source fuzzpass.sh
#

fuzzpass() {
    local arg=$1
    if [ "$arg" == "" ]; then
        arg="password"
    fi
    local item=$(1pass | fzf);
    [[ ! -z "$item" ]] && 1pass $item $arg
}
