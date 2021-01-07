#compdef helm

__helm_bash_source() {
	alias shopt=':'
	alias _expand=_bash_expand
	alias _complete=_bash_comp
	emulate -L sh
	setopt kshglob noshglob braceexpand
	source "$@"
}
__helm_type() {
	# -t is not supported by zsh
	if [ "$1" == "-t" ]; then
		shift
		# fake Bash 4 to disable "complete -o nospace". Instead
		# "compopt +-o nospace" is used in the code to toggle trailing
		# spaces. We don't support that, but leave trailing spaces on
		# all the time
		if [ "$1" = "__helm_compopt" ]; then
			echo builtin
			return 0
		fi
	fi
	type "$@"
}
__helm_compgen() {
	local completions w
	completions=( $(compgen "$@") ) || return $?
	# filter by given word as prefix
	while [[ "$1" = -* && "$1" != -- ]]; do
		shift
		shift
	done
	if [[ "$1" == -- ]]; then
		shift
	fi
	for w in "${completions[@]}"; do
		if [[ "${w}" = "$1"* ]]; then
			# Use printf instead of echo because it is possible that
			# the value to print is -n, which would be interpreted
			# as a flag to echo
			printf "%s\n" "${w}"
		fi
	done
}
__helm_compopt() {
	true # don't do anything. Not supported by bashcompinit in zsh
}
__helm_ltrim_colon_completions()
{
	if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
		# Remove colon-word prefix from COMPREPLY items
		local colon_word=${1%${1##*:}}
		local i=${#COMPREPLY[*]}
		while [[ $((--i)) -ge 0 ]]; do
			COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"}
		done
	fi
}
__helm_get_comp_words_by_ref() {
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[${COMP_CWORD}-1]}"
	words=("${COMP_WORDS[@]}")
	cword=("${COMP_CWORD[@]}")
}
__helm_filedir() {
	local RET OLD_IFS w qw
	__debug "_filedir $@ cur=$cur"
	if [[ "$1" = \~* ]]; then
		# somehow does not work. Maybe, zsh does not call this at all
		eval echo "$1"
		return 0
	fi
	OLD_IFS="$IFS"
	IFS=$'\n'
	if [ "$1" = "-d" ]; then
		shift
		RET=( $(compgen -d) )
	else
		RET=( $(compgen -f) )
	fi
	IFS="$OLD_IFS"
	IFS="," __debug "RET=${RET[@]} len=${#RET[@]}"
	for w in ${RET[@]}; do
		if [[ ! "${w}" = "${cur}"* ]]; then
			continue
		fi
		if eval "[[ \"\${w}\" = *.$1 || -d \"\${w}\" ]]"; then
			qw="$(__helm_quote "${w}")"
			if [ -d "${w}" ]; then
				COMPREPLY+=("${qw}/")
			else
				COMPREPLY+=("${qw}")
			fi
		fi
	done
}
__helm_quote() {
	if [[ $1 == \'* || $1 == \"* ]]; then
		# Leave out first character
		printf %q "${1:1}"
	else
		printf %q "$1"
	fi
}
autoload -U +X bashcompinit && bashcompinit
# use word boundary patterns for BSD or GNU sed
LWORD='[[:<:]]'
RWORD='[[:>:]]'
if sed --help 2>&1 | grep -q 'GNU\|BusyBox'; then
	LWORD='\<'
	RWORD='\>'
fi
__helm_convert_bash_to_zsh() {
	sed \
	-e 's/declare -F/whence -w/' \
	-e 's/_get_comp_words_by_ref "\$@"/_get_comp_words_by_ref "\$*"/' \
	-e 's/local \([a-zA-Z0-9_]*\)=/local \1; \1=/' \
	-e 's/flags+=("\(--.*\)=")/flags+=("\1"); two_word_flags+=("\1")/' \
	-e 's/must_have_one_flag+=("\(--.*\)=")/must_have_one_flag+=("\1")/' \
	-e "s/${LWORD}_filedir${RWORD}/__helm_filedir/g" \
	-e "s/${LWORD}_get_comp_words_by_ref${RWORD}/__helm_get_comp_words_by_ref/g" \
	-e "s/${LWORD}__ltrim_colon_completions${RWORD}/__helm_ltrim_colon_completions/g" \
	-e "s/${LWORD}compgen${RWORD}/__helm_compgen/g" \
	-e "s/${LWORD}compopt${RWORD}/__helm_compopt/g" \
	-e "s/${LWORD}declare${RWORD}/builtin declare/g" \
	-e "s/\\\$(type${RWORD}/\$(__helm_type/g" \
	-e 's/aliashash\["\(.\{1,\}\)"\]/aliashash[\1]/g' \
	-e 's/FUNCNAME/funcstack/g' \
	<<'BASH_COMPLETION_EOF'
# bash completion for helm                                 -*- shell-script -*-

__helm_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__helm_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__helm_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__helm_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__helm_handle_go_custom_completion()
{
    __helm_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly helm allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __helm_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __helm_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __helm_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __helm_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __helm_debug "${FUNCNAME[0]}: the completions are: ${out[*]}"

    if [ $((directive & 1)) -ne 0 ]; then
        # Error code.  No completion.
        __helm_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & 2)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __helm_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & 4)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __helm_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi

        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out[*]}" -- "$cur")
    fi
}

__helm_handle_reply()
{
    __helm_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __helm_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __helm_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        completions=()
        __helm_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __helm_custom_func >/dev/null; then
			# try command name qualified custom func
			__helm_custom_func
		else
			# otherwise fall back to unqualified for compatibility
			declare -F __custom_func >/dev/null && __custom_func
		fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__helm_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__helm_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__helm_handle_flag()
{
    __helm_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __helm_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __helm_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __helm_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __helm_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __helm_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__helm_handle_noun()
{
    __helm_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __helm_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __helm_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__helm_handle_command()
{
    __helm_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_helm_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __helm_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__helm_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __helm_handle_reply
        return
    fi
    __helm_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __helm_handle_flag
    elif __helm_contains_word "${words[c]}" "${commands[@]}"; then
        __helm_handle_command
    elif [[ $c -eq 0 ]]; then
        __helm_handle_command
    elif __helm_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __helm_handle_command
        else
            __helm_handle_noun
        fi
    else
        __helm_handle_noun
    fi
    __helm_handle_word
}

_helm_completion_bash()
{
    last_command="helm_completion_bash"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_completion_fish()
{
    last_command="helm_completion_fish"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-descriptions")
    local_nonpersistent_flags+=("--no-descriptions")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_completion_zsh()
{
    last_command="helm_completion_zsh"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_completion()
{
    last_command="helm_completion"

    command_aliases=()

    commands=()
    commands+=("bash")
    commands+=("fish")
    commands+=("zsh")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_create()
{
    last_command="helm_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--starter=")
    two_word_flags+=("--starter")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--starter=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_dependency_build()
{
    last_command="helm_dependency_build"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--skip-refresh")
    local_nonpersistent_flags+=("--skip-refresh")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_dependency_list()
{
    last_command="helm_dependency_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_dependency_update()
{
    last_command="helm_dependency_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--skip-refresh")
    local_nonpersistent_flags+=("--skip-refresh")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_dependency()
{
    last_command="helm_dependency"

    command_aliases=()

    commands=()
    commands+=("build")
    commands+=("list")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("update")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("up")
        aliashash["up"]="update"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_env()
{
    last_command="helm_env"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_get_all()
{
    last_command="helm_get_all"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags_with_completion+=("--revision")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--revision=")
    flags+=("--template=")
    two_word_flags+=("--template")
    local_nonpersistent_flags+=("--template=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_get_hooks()
{
    last_command="helm_get_hooks"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags_with_completion+=("--revision")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--revision=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_get_manifest()
{
    last_command="helm_get_manifest"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags_with_completion+=("--revision")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--revision=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_get_notes()
{
    last_command="helm_get_notes"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags_with_completion+=("--revision")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--revision=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_get_values()
{
    last_command="helm_get_values"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags_with_completion+=("--revision")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--revision=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_get()
{
    last_command="helm_get"

    command_aliases=()

    commands=()
    commands+=("all")
    commands+=("hooks")
    commands+=("manifest")
    commands+=("notes")
    commands+=("values")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_history()
{
    last_command="helm_history"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--max=")
    two_word_flags+=("--max")
    local_nonpersistent_flags+=("--max=")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_install()
{
    last_command="helm_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--atomic")
    local_nonpersistent_flags+=("--atomic")
    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--create-namespace")
    local_nonpersistent_flags+=("--create-namespace")
    flags+=("--dependency-update")
    local_nonpersistent_flags+=("--dependency-update")
    flags+=("--description=")
    two_word_flags+=("--description")
    local_nonpersistent_flags+=("--description=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--disable-openapi-validation")
    local_nonpersistent_flags+=("--disable-openapi-validation")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--generate-name")
    flags+=("-g")
    local_nonpersistent_flags+=("--generate-name")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--name-template=")
    two_word_flags+=("--name-template")
    local_nonpersistent_flags+=("--name-template=")
    flags+=("--no-hooks")
    local_nonpersistent_flags+=("--no-hooks")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--post-renderer=")
    two_word_flags+=("--post-renderer")
    local_nonpersistent_flags+=("--post-renderer=")
    flags+=("--render-subchart-notes")
    local_nonpersistent_flags+=("--render-subchart-notes")
    flags+=("--replace")
    local_nonpersistent_flags+=("--replace")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--set=")
    two_word_flags+=("--set")
    local_nonpersistent_flags+=("--set=")
    flags+=("--set-file=")
    two_word_flags+=("--set-file")
    local_nonpersistent_flags+=("--set-file=")
    flags+=("--set-string=")
    two_word_flags+=("--set-string")
    local_nonpersistent_flags+=("--set-string=")
    flags+=("--skip-crds")
    local_nonpersistent_flags+=("--skip-crds")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--values=")
    two_word_flags+=("--values")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--values=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_lint()
{
    last_command="helm_lint"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--set=")
    two_word_flags+=("--set")
    local_nonpersistent_flags+=("--set=")
    flags+=("--set-file=")
    two_word_flags+=("--set-file")
    local_nonpersistent_flags+=("--set-file=")
    flags+=("--set-string=")
    two_word_flags+=("--set-string")
    local_nonpersistent_flags+=("--set-string=")
    flags+=("--strict")
    local_nonpersistent_flags+=("--strict")
    flags+=("--values=")
    two_word_flags+=("--values")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--values=")
    flags+=("--with-subcharts")
    local_nonpersistent_flags+=("--with-subcharts")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_list()
{
    last_command="helm_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--all-namespaces")
    flags+=("-A")
    local_nonpersistent_flags+=("--all-namespaces")
    flags+=("--date")
    flags+=("-d")
    local_nonpersistent_flags+=("--date")
    flags+=("--deployed")
    local_nonpersistent_flags+=("--deployed")
    flags+=("--failed")
    local_nonpersistent_flags+=("--failed")
    flags+=("--filter=")
    two_word_flags+=("--filter")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--max=")
    two_word_flags+=("--max")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--max=")
    flags+=("--offset=")
    two_word_flags+=("--offset")
    local_nonpersistent_flags+=("--offset=")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--pending")
    local_nonpersistent_flags+=("--pending")
    flags+=("--reverse")
    flags+=("-r")
    local_nonpersistent_flags+=("--reverse")
    flags+=("--selector=")
    two_word_flags+=("--selector")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--selector=")
    flags+=("--short")
    flags+=("-q")
    local_nonpersistent_flags+=("--short")
    flags+=("--superseded")
    local_nonpersistent_flags+=("--superseded")
    flags+=("--time-format=")
    two_word_flags+=("--time-format")
    local_nonpersistent_flags+=("--time-format=")
    flags+=("--uninstalled")
    local_nonpersistent_flags+=("--uninstalled")
    flags+=("--uninstalling")
    local_nonpersistent_flags+=("--uninstalling")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_package()
{
    last_command="helm_package"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-version=")
    two_word_flags+=("--app-version")
    local_nonpersistent_flags+=("--app-version=")
    flags+=("--dependency-update")
    flags+=("-u")
    local_nonpersistent_flags+=("--dependency-update")
    flags+=("--destination=")
    two_word_flags+=("--destination")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--destination=")
    flags+=("--key=")
    two_word_flags+=("--key")
    local_nonpersistent_flags+=("--key=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--passphrase-file=")
    two_word_flags+=("--passphrase-file")
    local_nonpersistent_flags+=("--passphrase-file=")
    flags+=("--sign")
    local_nonpersistent_flags+=("--sign")
    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_plugin_install()
{
    last_command="helm_plugin_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_plugin_list()
{
    last_command="helm_plugin_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_plugin_uninstall()
{
    last_command="helm_plugin_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_plugin_update()
{
    last_command="helm_plugin_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_plugin()
{
    last_command="helm_plugin"

    command_aliases=()

    commands=()
    commands+=("install")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("add")
        aliashash["add"]="install"
    fi
    commands+=("list")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("uninstall")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("remove")
        aliashash["remove"]="uninstall"
        command_aliases+=("rm")
        aliashash["rm"]="uninstall"
    fi
    commands+=("update")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("up")
        aliashash["up"]="update"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_pull()
{
    last_command="helm_pull"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--destination=")
    two_word_flags+=("--destination")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--destination=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--prov")
    local_nonpersistent_flags+=("--prov")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--untar")
    local_nonpersistent_flags+=("--untar")
    flags+=("--untardir=")
    two_word_flags+=("--untardir")
    local_nonpersistent_flags+=("--untardir=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_repo_add()
{
    last_command="helm_repo_add"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--allow-deprecated-repos")
    local_nonpersistent_flags+=("--allow-deprecated-repos")
    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--force-update")
    local_nonpersistent_flags+=("--force-update")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--no-update")
    local_nonpersistent_flags+=("--no-update")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_repo_index()
{
    last_command="helm_repo_index"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--merge=")
    two_word_flags+=("--merge")
    local_nonpersistent_flags+=("--merge=")
    flags+=("--url=")
    two_word_flags+=("--url")
    local_nonpersistent_flags+=("--url=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_repo_list()
{
    last_command="helm_repo_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_repo_remove()
{
    last_command="helm_repo_remove"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_repo_update()
{
    last_command="helm_repo_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_repo()
{
    last_command="helm_repo"

    command_aliases=()

    commands=()
    commands+=("add")
    commands+=("index")
    commands+=("list")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("remove")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("rm")
        aliashash["rm"]="remove"
    fi
    commands+=("update")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("up")
        aliashash["up"]="update"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_rollback()
{
    last_command="helm_rollback"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--cleanup-on-fail")
    local_nonpersistent_flags+=("--cleanup-on-fail")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--force")
    local_nonpersistent_flags+=("--force")
    flags+=("--history-max=")
    two_word_flags+=("--history-max")
    local_nonpersistent_flags+=("--history-max=")
    flags+=("--no-hooks")
    local_nonpersistent_flags+=("--no-hooks")
    flags+=("--recreate-pods")
    local_nonpersistent_flags+=("--recreate-pods")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_search_hub()
{
    last_command="helm_search_hub"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint=")
    flags+=("--max-col-width=")
    two_word_flags+=("--max-col-width")
    local_nonpersistent_flags+=("--max-col-width=")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_search_repo()
{
    last_command="helm_search_repo"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--max-col-width=")
    two_word_flags+=("--max-col-width")
    local_nonpersistent_flags+=("--max-col-width=")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--regexp")
    flags+=("-r")
    local_nonpersistent_flags+=("--regexp")
    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--versions")
    flags+=("-l")
    local_nonpersistent_flags+=("--versions")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_helm_search()
{
    last_command="helm_search"

    command_aliases=()

    commands=()
    commands+=("hub")
    commands+=("repo")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_show_all()
{
    last_command="helm_show_all"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_show_chart()
{
    last_command="helm_show_chart"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_show_readme()
{
    last_command="helm_show_readme"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_show_values()
{
    last_command="helm_show_values"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--jsonpath=")
    two_word_flags+=("--jsonpath")
    local_nonpersistent_flags+=("--jsonpath=")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_show()
{
    last_command="helm_show"

    command_aliases=()

    commands=()
    commands+=("all")
    commands+=("chart")
    commands+=("readme")
    commands+=("values")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_status()
{
    last_command="helm_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags_with_completion+=("--revision")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--revision=")
    flags+=("--show-desc")
    local_nonpersistent_flags+=("--show-desc")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_template()
{
    last_command="helm_template"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-versions=")
    two_word_flags+=("--api-versions")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--api-versions=")
    flags+=("--atomic")
    local_nonpersistent_flags+=("--atomic")
    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--create-namespace")
    local_nonpersistent_flags+=("--create-namespace")
    flags+=("--dependency-update")
    local_nonpersistent_flags+=("--dependency-update")
    flags+=("--description=")
    two_word_flags+=("--description")
    local_nonpersistent_flags+=("--description=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--disable-openapi-validation")
    local_nonpersistent_flags+=("--disable-openapi-validation")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--generate-name")
    flags+=("-g")
    local_nonpersistent_flags+=("--generate-name")
    flags+=("--include-crds")
    local_nonpersistent_flags+=("--include-crds")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--is-upgrade")
    local_nonpersistent_flags+=("--is-upgrade")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--name-template=")
    two_word_flags+=("--name-template")
    local_nonpersistent_flags+=("--name-template=")
    flags+=("--no-hooks")
    local_nonpersistent_flags+=("--no-hooks")
    flags+=("--output-dir=")
    two_word_flags+=("--output-dir")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--post-renderer=")
    two_word_flags+=("--post-renderer")
    local_nonpersistent_flags+=("--post-renderer=")
    flags+=("--release-name")
    local_nonpersistent_flags+=("--release-name")
    flags+=("--render-subchart-notes")
    local_nonpersistent_flags+=("--render-subchart-notes")
    flags+=("--replace")
    local_nonpersistent_flags+=("--replace")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--set=")
    two_word_flags+=("--set")
    local_nonpersistent_flags+=("--set=")
    flags+=("--set-file=")
    two_word_flags+=("--set-file")
    local_nonpersistent_flags+=("--set-file=")
    flags+=("--set-string=")
    two_word_flags+=("--set-string")
    local_nonpersistent_flags+=("--set-string=")
    flags+=("--show-only=")
    two_word_flags+=("--show-only")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--show-only=")
    flags+=("--skip-crds")
    local_nonpersistent_flags+=("--skip-crds")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--validate")
    local_nonpersistent_flags+=("--validate")
    flags+=("--values=")
    two_word_flags+=("--values")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--values=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_test()
{
    last_command="helm_test"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--logs")
    local_nonpersistent_flags+=("--logs")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_uninstall()
{
    last_command="helm_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--description=")
    two_word_flags+=("--description")
    local_nonpersistent_flags+=("--description=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--keep-history")
    local_nonpersistent_flags+=("--keep-history")
    flags+=("--no-hooks")
    local_nonpersistent_flags+=("--no-hooks")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_upgrade()
{
    last_command="helm_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--atomic")
    local_nonpersistent_flags+=("--atomic")
    flags+=("--ca-file=")
    two_word_flags+=("--ca-file")
    local_nonpersistent_flags+=("--ca-file=")
    flags+=("--cert-file=")
    two_word_flags+=("--cert-file")
    local_nonpersistent_flags+=("--cert-file=")
    flags+=("--cleanup-on-fail")
    local_nonpersistent_flags+=("--cleanup-on-fail")
    flags+=("--create-namespace")
    local_nonpersistent_flags+=("--create-namespace")
    flags+=("--description=")
    two_word_flags+=("--description")
    local_nonpersistent_flags+=("--description=")
    flags+=("--devel")
    local_nonpersistent_flags+=("--devel")
    flags+=("--disable-openapi-validation")
    local_nonpersistent_flags+=("--disable-openapi-validation")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--force")
    local_nonpersistent_flags+=("--force")
    flags+=("--history-max=")
    two_word_flags+=("--history-max")
    local_nonpersistent_flags+=("--history-max=")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--install")
    flags+=("-i")
    local_nonpersistent_flags+=("--install")
    flags+=("--key-file=")
    two_word_flags+=("--key-file")
    local_nonpersistent_flags+=("--key-file=")
    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--no-hooks")
    local_nonpersistent_flags+=("--no-hooks")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--output=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--post-renderer=")
    two_word_flags+=("--post-renderer")
    local_nonpersistent_flags+=("--post-renderer=")
    flags+=("--render-subchart-notes")
    local_nonpersistent_flags+=("--render-subchart-notes")
    flags+=("--repo=")
    two_word_flags+=("--repo")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--reset-values")
    local_nonpersistent_flags+=("--reset-values")
    flags+=("--reuse-values")
    local_nonpersistent_flags+=("--reuse-values")
    flags+=("--set=")
    two_word_flags+=("--set")
    local_nonpersistent_flags+=("--set=")
    flags+=("--set-file=")
    two_word_flags+=("--set-file")
    local_nonpersistent_flags+=("--set-file=")
    flags+=("--set-string=")
    two_word_flags+=("--set-string")
    local_nonpersistent_flags+=("--set-string=")
    flags+=("--skip-crds")
    local_nonpersistent_flags+=("--skip-crds")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--values=")
    two_word_flags+=("--values")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--values=")
    flags+=("--verify")
    local_nonpersistent_flags+=("--verify")
    flags+=("--version=")
    two_word_flags+=("--version")
    flags_with_completion+=("--version")
    flags_completion+=("__helm_handle_go_custom_completion")
    local_nonpersistent_flags+=("--version=")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_verify()
{
    last_command="helm_verify"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--keyring=")
    two_word_flags+=("--keyring")
    local_nonpersistent_flags+=("--keyring=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_version()
{
    last_command="helm_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--short")
    local_nonpersistent_flags+=("--short")
    flags+=("--template=")
    two_word_flags+=("--template")
    local_nonpersistent_flags+=("--template=")
    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_helm_root_command()
{
    last_command="helm"

    command_aliases=()

    commands=()
    commands+=("completion")
    commands+=("create")
    commands+=("dependency")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("dep")
        aliashash["dep"]="dependency"
        command_aliases+=("dependencies")
        aliashash["dependencies"]="dependency"
    fi
    commands+=("env")
    commands+=("get")
    commands+=("history")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("hist")
        aliashash["hist"]="history"
    fi
    commands+=("install")
    commands+=("lint")
    commands+=("list")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("package")
    commands+=("plugin")
    commands+=("pull")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("fetch")
        aliashash["fetch"]="pull"
    fi
    commands+=("repo")
    commands+=("rollback")
    commands+=("search")
    commands+=("show")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("inspect")
        aliashash["inspect"]="show"
    fi
    commands+=("status")
    commands+=("template")
    commands+=("test")
    commands+=("uninstall")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("del")
        aliashash["del"]="uninstall"
        command_aliases+=("delete")
        aliashash["delete"]="uninstall"
        command_aliases+=("un")
        aliashash["un"]="uninstall"
    fi
    commands+=("upgrade")
    commands+=("verify")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    flags+=("--kube-apiserver=")
    two_word_flags+=("--kube-apiserver")
    flags+=("--kube-as-group=")
    two_word_flags+=("--kube-as-group")
    flags+=("--kube-as-user=")
    two_word_flags+=("--kube-as-user")
    flags+=("--kube-context=")
    two_word_flags+=("--kube-context")
    flags_with_completion+=("--kube-context")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--kube-token=")
    two_word_flags+=("--kube-token")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    flags_with_completion+=("--namespace")
    flags_completion+=("__helm_handle_go_custom_completion")
    two_word_flags+=("-n")
    flags_with_completion+=("-n")
    flags_completion+=("__helm_handle_go_custom_completion")
    flags+=("--registry-config=")
    two_word_flags+=("--registry-config")
    flags+=("--repository-cache=")
    two_word_flags+=("--repository-cache")
    flags+=("--repository-config=")
    two_word_flags+=("--repository-config")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_helm()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __helm_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("helm")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function
    local last_command
    local nouns=()

    __helm_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_helm helm
else
    complete -o default -o nospace -F __start_helm helm
fi

# ex: ts=4 sw=4 et filetype=sh

BASH_COMPLETION_EOF
}
__helm_bash_source <(__helm_convert_bash_to_zsh)
