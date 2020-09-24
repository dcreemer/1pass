#! /usr/bin/env bash
# add fuzzyfind (fzf) completion for 1pass objects

function _fzf_complete_1pass() {
  local doFzf=false
  local cword="${COMP_WORDS[$COMP_CWORD]}"
  if _should_1p_fzf_complete; then
    doFzf=true
    local trigger=${FZF_COMPLETION_TRIGGER-'**'}
    if [[ -z "$cword" ]]; then
      COMP_WORDS[$COMP_CWORD]=$trigger
    elif [[ "$cword" != *"$trigger" ]]; then
      COMP_WORDS[$COMP_CWORD]="$cword$trigger"
    fi
  fi

  local item
  local words=("${COMP_WORDS[@]::${#COMP_WORDS[@]}-1}")
  for i in "${!words[@]}"; do
    local curr=${words[$i]}
    if [[ $i -ne 0 ]] && [[ ${curr} != "-"* ]]; then
      item=${curr}
      break
    fi
  done
  # Avoid any aliases that might be set
  local opcmd="command 1pass"
  local rcmd=""
  if [[ -z "$item" ]]; then
    rcmd="${opcmd}"
  else
    rcmd="${opcmd} -l \"$item\""
  fi
  if ${doFzf}; then
      _fzf_complete --reverse --prompt="1pass> " -- "${@}" < <(eval "$rcmd")
  else
    COMPREPLY=()
    local search
    # The rest adapted from https://stackoverflow.com/a/1146716/190100
    search=$(eval echo "$cword" 2>/dev/null || eval echo "$cword'" 2>/dev/null || eval echo "$cword\"" 2>/dev/null || "" )
    local IFS=$'\n'
    while read -r line; do COMPREPLY+=("$line"); done < <(compgen -W "$(_1p_entries "${rcmd}")" -- "$search")
    local escaped_single_qoute="'\''"
    local i=0
    for entry in ${COMPREPLY[*]}
    do
        if [[ "${cword:0:1}" == "'" ]]
        then
            # started with single quote, escaping only other single quotes
            # [']bla'bla"bla\bla bla --> [']bla'\''bla"bla\bla bla
            COMPREPLY[$i]="${entry//\'/${escaped_single_qoute}}"
        elif [[ "${cword:0:1}" == "\"" ]]
        then
            # started with double quote, escaping all double quotes and all backslashes
            # ["]bla'bla"bla\bla bla --> ["]bla'bla\"bla\\bla bla
            entry="${entry//\\/\\\\}"
            COMPREPLY[$i]="${entry//\"/\\\"}"
        else
            # no quotes in front, escaping _everything_
            # [ ]bla'bla"bla\bla bla --> [ ]bla\'bla\"bla\\bla\ bla
            entry="${entry//\\/\\\\}"
            entry="${entry//\'/\'}"
            entry="${entry//\"/\\\"}"
            COMPREPLY[$i]="${entry// /\\ }"
        fi
        (( i++ ))
    done
  fi
}
complete -F _fzf_complete_1pass -o default -o bashdefault 1pass

function _should_1p_fzf_complete() {
  ${ONEPASS_FZF_COMPLETE:-true} && declare -f _fzf_complete > /dev/null 2>&1
}

function _1p_entries() {
  eval "${@}" | sed -e "{" -e 's#\\#\\\\#g' -e "s#'#\\\'#g" -e 's#"#\\\"#g' -e "}"
}
