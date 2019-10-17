#!/usr/bin/env bash

_vagrant_completion() {
    # Disable default Readline completion. We can enable it only when needed.
    # Like when we want filename completion.
    compopt +o default
    COMPREPLY=()
    local cur="$2"
    local prev="$3"
    local program="$1"

    case $prev in
        -h) return;;
        *) local COMMANDS=$($program -h | sed -n '/^Common commands:/,/^For help/s/[[:space:]]*\([-a-z]*\).*/\1/p');
            if echo $COMMANDS | grep -qw $prev; then
                return
            fi;;
    esac

    case $cur in
        *) local COMMANDS=$($program -h | sed -n '/^Common commands:/,/^For help/s/[[:space:]]*\([-a-z]*\).*/\1/p');
           COMPREPLY=($(compgen -W "$COMMANDS" -- "$cur"))
    esac
}

_vagrant_completion_fast() {
    # Disable default Readline completion. We can enable it only when needed.
    # Like when we want filename completion.
    compopt +o default
    COMPREPLY=()
    local cur="$2"
    local prev="$3"
    local program="$(which $1)"

    case $prev in
        -h) return;;
        *) local COMMANDS=$(sed -n '/^Common commands:/,/^For help/s/[[:space:]]*\([-a-z]*\).*/\1/p' $program);
            if echo $COMMANDS | grep -qw $prev; then
                return
            fi;;
    esac

    case $cur in
        *) local COMMANDS=$(sed -n '/^Common commands:/,/^For help/s/[[:space:]]*\([-a-z]*\).*/\1/p' $program);
           COMPREPLY=($(compgen -W "$COMMANDS" -- "$cur"))
    esac
}

complete -F _vagrant_completion_fast vagrant
