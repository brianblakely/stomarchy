_stomarchy()
{
    local cur prev commands global_opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    commands="add link remove sync wipe status help"
    global_opts="--help --version"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands} ${global_opts}" -- "$cur") )
        return 0
    fi

    case "${COMP_WORDS[1]}" in
        add)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--dry-run --preview -n" -- "$cur") )
            else
                COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            ;;
        link|remove)
            COMPREPLY=( $(compgen -f -- "$cur") )
            ;;
        sync)
            COMPREPLY=( $(compgen -W "--dry-run --preview -n" -- "$cur") )
            ;;
    esac
}

complete -F _stomarchy stomarchy
