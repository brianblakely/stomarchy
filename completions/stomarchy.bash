_stomarchy()
{
  local cur command
  local -a choices

  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  command=${COMP_WORDS[1]:-}

  if ((COMP_CWORD == 1)); then
    mapfile -t COMPREPLY < <(compgen -W "add link remove sync wipe status help -h --help -v --version" -- "$cur")
    return 0
  fi

  case "$command" in
    add)
      choices=(-n --dry-run --preview -h --help --)
      ;;
    link|remove)
      choices=(-n --dry-run --preview --force -h --help --)
      ;;
    sync|wipe)
      choices=(-n --dry-run --preview --all --force -h --help --)
      ;;
    status)
      choices=(--check --porcelain -h --help --)
      ;;
    help)
      choices=(add link remove sync wipe status)
      ;;
    *)
      return 0
      ;;
  esac

  if [[ $cur == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "${choices[*]}" -- "$cur")
  elif [[ $command == add || $command == link || $command == remove ]]; then
    compopt -o filenames 2>/dev/null || true
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
  fi
}

complete -F _stomarchy stomarchy
