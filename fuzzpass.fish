function fuzzpass
  set arg $argv[1]
  if test -z "$arg"
    set arg "password"
  end 
  set item (1pass | fzf)

  [ -n $item ] & 1pass $item $arg
end
