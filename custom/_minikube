#compdef minikube

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

__minikube_bash_source() {
	alias shopt=':'
	alias _expand=_bash_expand
	alias _complete=_bash_comp
	emulate -L sh
	setopt kshglob noshglob braceexpand
	source "$@"
}
__minikube_type() {
	# -t is not supported by zsh
	if [ "$1" == "-t" ]; then
		shift
		# fake Bash 4 to disable "complete -o nospace". Instead
		# "compopt +-o nospace" is used in the code to toggle trailing
		# spaces. We don't support that, but leave trailing spaces on
		# all the time
		if [ "$1" = "__minikube_compopt" ]; then
			echo builtin
			return 0
		fi
	fi
	type "$@"
}
__minikube_compgen() {
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
			echo "${w}"
		fi
	done
}
__minikube_compopt() {
	true # don't do anything. Not supported by bashcompinit in zsh
}
__minikube_declare() {
	if [ "$1" == "-F" ]; then
		whence -w "$@"
	else
		builtin declare "$@"
	fi
}
__minikube_ltrim_colon_completions()
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
__minikube_get_comp_words_by_ref() {
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[${COMP_CWORD}-1]}"
	words=("${COMP_WORDS[@]}")
	cword=("${COMP_CWORD[@]}")
}
__minikube_filedir() {
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
			qw="$(__minikube_quote "${w}")"
			if [ -d "${w}" ]; then
				COMPREPLY+=("${qw}/")
			else
				COMPREPLY+=("${qw}")
			fi
		fi
	done
}
__minikube_quote() {
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
if sed --help 2>&1 | grep -q GNU; then
	LWORD='\<'
	RWORD='\>'
fi
__minikube_convert_bash_to_zsh() {
	sed \
	-e 's/declare -F/whence -w/' \
	-e 's/_get_comp_words_by_ref "\$@"/_get_comp_words_by_ref "\$*"/' \
	-e 's/local \([a-zA-Z0-9_]*\)=/local \1; \1=/' \
	-e 's/flags+=("\(--.*\)=")/flags+=("\1"); two_word_flags+=("\1")/' \
	-e 's/must_have_one_flag+=("\(--.*\)=")/must_have_one_flag+=("\1")/' \
	-e "s/${LWORD}_filedir${RWORD}/__minikube_filedir/g" \
	-e "s/${LWORD}_get_comp_words_by_ref${RWORD}/__minikube_get_comp_words_by_ref/g" \
	-e "s/${LWORD}__ltrim_colon_completions${RWORD}/__minikube_ltrim_colon_completions/g" \
	-e "s/${LWORD}compgen${RWORD}/__minikube_compgen/g" \
	-e "s/${LWORD}compopt${RWORD}/__minikube_compopt/g" \
	-e "s/${LWORD}declare${RWORD}/__minikube_declare/g" \
	-e "s/\\\$(type${RWORD}/\$(__minikube_type/g" \
	<<'BASH_COMPLETION_EOF'
# bash completion for minikube                             -*- shell-script -*-

__minikube_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__minikube_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__minikube_index_of_word()
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

__minikube_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__minikube_handle_reply()
{
    __minikube_debug "${FUNCNAME[0]}"
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
            COMPREPLY=( $(compgen -W "${allflags[*]}" -- "$cur") )
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
                __minikube_index_of_word "${flag}" "${flags_with_completion[@]}"
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
    __minikube_index_of_word "${prev}" "${flags_with_completion[@]}"
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
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        COMPREPLY=( $(compgen -W "${noun_aliases[*]}" -- "$cur") )
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __minikube_custom_func >/dev/null; then
			# try command name qualified custom func
			__minikube_custom_func
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
__minikube_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__minikube_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1
}

__minikube_handle_flag()
{
    __minikube_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __minikube_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __minikube_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __minikube_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
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
    if [[ ${words[c]} != *"="* ]] && __minikube_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __minikube_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__minikube_handle_noun()
{
    __minikube_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __minikube_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __minikube_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__minikube_handle_command()
{
    __minikube_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_minikube_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __minikube_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__minikube_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __minikube_handle_reply
        return
    fi
    __minikube_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __minikube_handle_flag
    elif __minikube_contains_word "${words[c]}" "${commands[@]}"; then
        __minikube_handle_command
    elif [[ $c -eq 0 ]]; then
        __minikube_handle_command
    elif __minikube_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __minikube_handle_command
        else
            __minikube_handle_noun
        fi
    else
        __minikube_handle_noun
    fi
    __minikube_handle_word
}

_minikube_addons_configure()
{
    last_command="minikube_addons_configure"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_addons_disable()
{
    last_command="minikube_addons_disable"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_addons_enable()
{
    last_command="minikube_addons_enable"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_addons_list()
{
    last_command="minikube_addons_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_addons_open()
{
    last_command="minikube_addons_open"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--https")
    local_nonpersistent_flags+=("--https")
    flags+=("--interval=")
    two_word_flags+=("--interval")
    local_nonpersistent_flags+=("--interval=")
    flags+=("--url")
    local_nonpersistent_flags+=("--url")
    flags+=("--wait=")
    two_word_flags+=("--wait")
    local_nonpersistent_flags+=("--wait=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_addons()
{
    last_command="minikube_addons"

    command_aliases=()

    commands=()
    commands+=("configure")
    commands+=("disable")
    commands+=("enable")
    commands+=("list")
    commands+=("open")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_cache_add()
{
    last_command="minikube_cache_add"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_cache_delete()
{
    last_command="minikube_cache_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_cache_list()
{
    last_command="minikube_cache_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    two_word_flags+=("--format")
    local_nonpersistent_flags+=("--format=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_cache_reload()
{
    last_command="minikube_cache_reload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_cache()
{
    last_command="minikube_cache"

    command_aliases=()

    commands=()
    commands+=("add")
    commands+=("delete")
    commands+=("list")
    commands+=("reload")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_completion()
{
    last_command="minikube_completion"

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
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_config_get()
{
    last_command="minikube_config_get"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_config_set()
{
    last_command="minikube_config_set"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_config_unset()
{
    last_command="minikube_config_unset"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_config_view()
{
    last_command="minikube_config_view"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    two_word_flags+=("--format")
    local_nonpersistent_flags+=("--format=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_config()
{
    last_command="minikube_config"

    command_aliases=()

    commands=()
    commands+=("get")
    commands+=("set")
    commands+=("unset")
    commands+=("view")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_dashboard()
{
    last_command="minikube_dashboard"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--url")
    local_nonpersistent_flags+=("--url")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_delete()
{
    last_command="minikube_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    local_nonpersistent_flags+=("--all")
    flags+=("--purge")
    local_nonpersistent_flags+=("--purge")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_delete()
{
    last_command="minikube_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    local_nonpersistent_flags+=("--all")
    flags+=("--purge")
    local_nonpersistent_flags+=("--purge")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_docker-env()
{
    last_command="minikube_docker-env"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-proxy")
    local_nonpersistent_flags+=("--no-proxy")
    flags+=("--shell=")
    two_word_flags+=("--shell")
    local_nonpersistent_flags+=("--shell=")
    flags+=("--unset")
    flags+=("-u")
    local_nonpersistent_flags+=("--unset")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_ip()
{
    last_command="minikube_ip"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_kubectl()
{
    last_command="minikube_kubectl"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_logs()
{
    last_command="minikube_logs"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--follow")
    flags+=("-f")
    local_nonpersistent_flags+=("--follow")
    flags+=("--length=")
    two_word_flags+=("--length")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--length=")
    flags+=("--problems")
    local_nonpersistent_flags+=("--problems")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_mount()
{
    last_command="minikube_mount"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--9p-version=")
    two_word_flags+=("--9p-version")
    local_nonpersistent_flags+=("--9p-version=")
    flags+=("--gid=")
    two_word_flags+=("--gid")
    local_nonpersistent_flags+=("--gid=")
    flags+=("--ip=")
    two_word_flags+=("--ip")
    local_nonpersistent_flags+=("--ip=")
    flags+=("--kill")
    local_nonpersistent_flags+=("--kill")
    flags+=("--mode=")
    two_word_flags+=("--mode")
    local_nonpersistent_flags+=("--mode=")
    flags+=("--msize=")
    two_word_flags+=("--msize")
    local_nonpersistent_flags+=("--msize=")
    flags+=("--options=")
    two_word_flags+=("--options")
    local_nonpersistent_flags+=("--options=")
    flags+=("--type=")
    two_word_flags+=("--type")
    local_nonpersistent_flags+=("--type=")
    flags+=("--uid=")
    two_word_flags+=("--uid")
    local_nonpersistent_flags+=("--uid=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_options()
{
    last_command="minikube_options"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_pause()
{
    last_command="minikube_pause"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("----namespaces=")
    two_word_flags+=("----namespaces")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("----namespaces=")
    flags+=("--all-namespaces")
    flags+=("-A")
    local_nonpersistent_flags+=("--all-namespaces")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_profile_list()
{
    last_command="minikube_profile_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_profile()
{
    last_command="minikube_profile"

    command_aliases=()

    commands=()
    commands+=("list")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_service_list()
{
    last_command="minikube_service_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_service()
{
    last_command="minikube_service"

    command_aliases=()

    commands=()
    commands+=("list")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--https")
    local_nonpersistent_flags+=("--https")
    flags+=("--interval=")
    two_word_flags+=("--interval")
    local_nonpersistent_flags+=("--interval=")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--url")
    local_nonpersistent_flags+=("--url")
    flags+=("--wait=")
    two_word_flags+=("--wait")
    local_nonpersistent_flags+=("--wait=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_ssh()
{
    last_command="minikube_ssh"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--native-ssh")
    local_nonpersistent_flags+=("--native-ssh")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_ssh-key()
{
    last_command="minikube_ssh-key"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_start()
{
    last_command="minikube_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--addons=")
    two_word_flags+=("--addons")
    local_nonpersistent_flags+=("--addons=")
    flags+=("--apiserver-ips=")
    two_word_flags+=("--apiserver-ips")
    local_nonpersistent_flags+=("--apiserver-ips=")
    flags+=("--apiserver-name=")
    two_word_flags+=("--apiserver-name")
    local_nonpersistent_flags+=("--apiserver-name=")
    flags+=("--apiserver-names=")
    two_word_flags+=("--apiserver-names")
    local_nonpersistent_flags+=("--apiserver-names=")
    flags+=("--apiserver-port=")
    two_word_flags+=("--apiserver-port")
    local_nonpersistent_flags+=("--apiserver-port=")
    flags+=("--auto-update-drivers")
    local_nonpersistent_flags+=("--auto-update-drivers")
    flags+=("--cache-images")
    local_nonpersistent_flags+=("--cache-images")
    flags+=("--container-runtime=")
    two_word_flags+=("--container-runtime")
    local_nonpersistent_flags+=("--container-runtime=")
    flags+=("--cpus=")
    two_word_flags+=("--cpus")
    local_nonpersistent_flags+=("--cpus=")
    flags+=("--cri-socket=")
    two_word_flags+=("--cri-socket")
    local_nonpersistent_flags+=("--cri-socket=")
    flags+=("--disable-driver-mounts")
    local_nonpersistent_flags+=("--disable-driver-mounts")
    flags+=("--disk-size=")
    two_word_flags+=("--disk-size")
    local_nonpersistent_flags+=("--disk-size=")
    flags+=("--dns-domain=")
    two_word_flags+=("--dns-domain")
    local_nonpersistent_flags+=("--dns-domain=")
    flags+=("--dns-proxy")
    local_nonpersistent_flags+=("--dns-proxy")
    flags+=("--docker-env=")
    two_word_flags+=("--docker-env")
    local_nonpersistent_flags+=("--docker-env=")
    flags+=("--docker-opt=")
    two_word_flags+=("--docker-opt")
    local_nonpersistent_flags+=("--docker-opt=")
    flags+=("--download-only")
    local_nonpersistent_flags+=("--download-only")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--embed-certs")
    local_nonpersistent_flags+=("--embed-certs")
    flags+=("--enable-default-cni")
    local_nonpersistent_flags+=("--enable-default-cni")
    flags+=("--extra-config=")
    two_word_flags+=("--extra-config")
    local_nonpersistent_flags+=("--extra-config=")
    flags+=("--feature-gates=")
    two_word_flags+=("--feature-gates")
    local_nonpersistent_flags+=("--feature-gates=")
    flags+=("--force")
    local_nonpersistent_flags+=("--force")
    flags+=("--host-dns-resolver")
    local_nonpersistent_flags+=("--host-dns-resolver")
    flags+=("--host-only-cidr=")
    two_word_flags+=("--host-only-cidr")
    local_nonpersistent_flags+=("--host-only-cidr=")
    flags+=("--host-only-nic-type=")
    two_word_flags+=("--host-only-nic-type")
    local_nonpersistent_flags+=("--host-only-nic-type=")
    flags+=("--hyperkit-vpnkit-sock=")
    two_word_flags+=("--hyperkit-vpnkit-sock")
    local_nonpersistent_flags+=("--hyperkit-vpnkit-sock=")
    flags+=("--hyperkit-vsock-ports=")
    two_word_flags+=("--hyperkit-vsock-ports")
    local_nonpersistent_flags+=("--hyperkit-vsock-ports=")
    flags+=("--hyperv-virtual-switch=")
    two_word_flags+=("--hyperv-virtual-switch")
    local_nonpersistent_flags+=("--hyperv-virtual-switch=")
    flags+=("--image-mirror-country=")
    two_word_flags+=("--image-mirror-country")
    local_nonpersistent_flags+=("--image-mirror-country=")
    flags+=("--image-repository=")
    two_word_flags+=("--image-repository")
    local_nonpersistent_flags+=("--image-repository=")
    flags+=("--insecure-registry=")
    two_word_flags+=("--insecure-registry")
    local_nonpersistent_flags+=("--insecure-registry=")
    flags+=("--install-addons")
    local_nonpersistent_flags+=("--install-addons")
    flags+=("--interactive")
    local_nonpersistent_flags+=("--interactive")
    flags+=("--iso-url=")
    two_word_flags+=("--iso-url")
    local_nonpersistent_flags+=("--iso-url=")
    flags+=("--keep-context")
    local_nonpersistent_flags+=("--keep-context")
    flags+=("--kubernetes-version=")
    two_word_flags+=("--kubernetes-version")
    local_nonpersistent_flags+=("--kubernetes-version=")
    flags+=("--kvm-gpu")
    local_nonpersistent_flags+=("--kvm-gpu")
    flags+=("--kvm-hidden")
    local_nonpersistent_flags+=("--kvm-hidden")
    flags+=("--kvm-network=")
    two_word_flags+=("--kvm-network")
    local_nonpersistent_flags+=("--kvm-network=")
    flags+=("--kvm-qemu-uri=")
    two_word_flags+=("--kvm-qemu-uri")
    local_nonpersistent_flags+=("--kvm-qemu-uri=")
    flags+=("--memory=")
    two_word_flags+=("--memory")
    local_nonpersistent_flags+=("--memory=")
    flags+=("--mount")
    local_nonpersistent_flags+=("--mount")
    flags+=("--mount-string=")
    two_word_flags+=("--mount-string")
    local_nonpersistent_flags+=("--mount-string=")
    flags+=("--nat-nic-type=")
    two_word_flags+=("--nat-nic-type")
    local_nonpersistent_flags+=("--nat-nic-type=")
    flags+=("--native-ssh")
    local_nonpersistent_flags+=("--native-ssh")
    flags+=("--network-plugin=")
    two_word_flags+=("--network-plugin")
    local_nonpersistent_flags+=("--network-plugin=")
    flags+=("--nfs-share=")
    two_word_flags+=("--nfs-share")
    local_nonpersistent_flags+=("--nfs-share=")
    flags+=("--nfs-shares-root=")
    two_word_flags+=("--nfs-shares-root")
    local_nonpersistent_flags+=("--nfs-shares-root=")
    flags+=("--no-vtx-check")
    local_nonpersistent_flags+=("--no-vtx-check")
    flags+=("--registry-mirror=")
    two_word_flags+=("--registry-mirror")
    local_nonpersistent_flags+=("--registry-mirror=")
    flags+=("--service-cluster-ip-range=")
    two_word_flags+=("--service-cluster-ip-range")
    local_nonpersistent_flags+=("--service-cluster-ip-range=")
    flags+=("--uuid=")
    two_word_flags+=("--uuid")
    local_nonpersistent_flags+=("--uuid=")
    flags+=("--vm-driver=")
    two_word_flags+=("--vm-driver")
    local_nonpersistent_flags+=("--vm-driver=")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--wait-timeout=")
    two_word_flags+=("--wait-timeout")
    local_nonpersistent_flags+=("--wait-timeout=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_status()
{
    last_command="minikube_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    two_word_flags+=("--format")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--format=")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_stop()
{
    last_command="minikube_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_tunnel()
{
    last_command="minikube_tunnel"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--cleanup")
    flags+=("-c")
    local_nonpersistent_flags+=("--cleanup")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_unpause()
{
    last_command="minikube_unpause"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("----namespaces=")
    two_word_flags+=("----namespaces")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("----namespaces=")
    flags+=("--all-namespaces")
    flags+=("-A")
    local_nonpersistent_flags+=("--all-namespaces")
    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_update-check()
{
    last_command="minikube_update-check"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_update-context()
{
    last_command="minikube_update-context"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_version()
{
    last_command="minikube_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_minikube_root_command()
{
    last_command="minikube"

    command_aliases=()

    commands=()
    commands+=("addons")
    commands+=("cache")
    commands+=("completion")
    commands+=("config")
    commands+=("dashboard")
    commands+=("delete")
    commands+=("delete")
    commands+=("docker-env")
    commands+=("ip")
    commands+=("kubectl")
    commands+=("logs")
    commands+=("mount")
    commands+=("options")
    commands+=("pause")
    commands+=("profile")
    commands+=("service")
    commands+=("ssh")
    commands+=("ssh-key")
    commands+=("start")
    commands+=("status")
    commands+=("stop")
    commands+=("tunnel")
    commands+=("unpause")
    commands+=("update-check")
    commands+=("update-context")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--alsologtostderr")
    flags+=("--bootstrapper=")
    two_word_flags+=("--bootstrapper")
    two_word_flags+=("-b")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--logtostderr")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_minikube()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __minikube_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("minikube")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __minikube_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_minikube minikube
else
    complete -o default -o nospace -F __start_minikube minikube
fi

# ex: ts=4 sw=4 et filetype=sh

BASH_COMPLETION_EOF
}
__minikube_bash_source <(__minikube_convert_bash_to_zsh)
