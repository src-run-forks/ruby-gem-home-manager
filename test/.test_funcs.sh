

#
# Converts the case of the passed string to upper. Accepts passing the string
# as its first and only parameter, or it can read input piped to the function.
#

function to_upper() {
    printf "${1:-$(</dev/stdin)}" | tr '[:lower:]' '[:upper:]'
}


#
# Converts the case of the passed string to lower. Accepts passing the string
# as its first and only parameter, or it can read input piped to the function.
#

function to_lower() {
    printf "${1:-$(</dev/stdin)}" | tr '[:upper:]' '[:lower:]'
}


#
# Provided a value either via its first parameter or via a unix pipe, the value
# will be repeated the number of times specified as the second argument (which
# defaults to a single time).
#

function repeat_character() {
    local s="${1:-$(</dev/stdin)}"
    local i="${2:-1}"

    for j in $(seq 1 ${i}); do
        printf -- "${s}"
    done
}


#
#
#

function extract_one_character() {
    local value="${1:-$(</dev/stdin)}"
    local index=${2:-1}

    [[ ${index} -gt ${#myvar} ]] \
        && return 255 \
        || printf -- "${value:$index:1}"
}

#
# Write out the number of line feeds (as unix-newlines) passed as its first and
# only argument (passing no value defaults to a single line feed).
#

function write_feed() {
    for i in `seq 1 ${1:-1}`; do printf '\n'; done
}


#
# Write out a line of text (using different components to build the final
# resulting output). The first argument is a "style format" that must contain
# a single
#

function write_text() {
    local styles="${1:-%s}"; shift
    local format="%s"
    local output

    if [[ $# -gt 1 ]]; then
        format="${1:-}"; shift
    fi

    output="$(printf "$(printf "${styles}" "${format}")" "${@}")"

    [ -t 1 ] \
        && printf -- "${output}" \
        || printf -- "${output}" | sed -r "s,\x1B\[[0-9;]*[a-zA-Z],,g"
}

function write_unixtime_prefix() {
    write_text \
        '\033[90m(%s)\033[0m ' \
        "$(date +%s.%N | grep -o -E '[0-9]{3}\.[0-9]{5}')"
}

function write_type_name_fragment() {
    local action="$(printf "${1:-info}")"
    local styles="${2:-37}"
    local format="${3}"
    local master='\033[%sm%%s\033[0m'

    [[ -z "${format}" ]] && format='[%s]'

    write_text \
        " $(printf "${master}" "${styles}") " \
        "${format}" \
        "$(printf "${action}" | to_upper)"
}

function write_type_char_fragment() {
    local str="$(extract_one_character "${1:--}" 0)"
    local num=${3:-2}
    local styles="${2:-37}"
    local format="${4}"
    local master='\033[%sm%%s\033[0m'

    [[ -z "${format}" ]] && format=' %s '

    write_text \
        "$(printf "${master}" "${styles}")" \
        "${format}" \
        "$(repeat_character "${str}" ${num})"
}

function write_line() {
    write_text "${@}"
    write_feed
}

function write_head() {
    write_unixtime_prefix
    write_type_char_fragment '=' '1;7;107;95'
    write_type_name_fragment 'head' '35'
    write_line '\033[1;7;107;95m %s \033[0m' "$(to_upper "${1}")"
}

function write_info() {
    write_unixtime_prefix
    write_type_char_fragment '-' '1;37;44'
    write_type_name_fragment 'info' '94'
    write_line '\033[97m%s\033[0m' "${@}"
}

function write_okay() {
    write_unixtime_prefix
    write_type_char_fragment '+' '1;107;42'
    write_type_name_fragment 'okay' '32'
    write_line '\033[1;37m%s\033[0m' "${@}"
}

function write_warn() {
    write_unixtime_prefix
    write_type_char_fragment '#' '1;7;40;33'
    write_type_name_fragment 'warn' '33'
    write_line '\033[1;93m%s\033[0m' "${@}"
}

function write_fail() {
    write_unixtime_prefix
    write_type_char_fragment '!' '1;7;107;91'
    write_type_name_fragment 'crit' '31'
    write_line '\033[1;91m%s\033[0m' "${@}"

    exit 255
}

function skip_unsupported_environments() {
    [ -z "${LINENO:-}" ] \
        && startSkipping
}

function is_successful_pipe_exit() {
    local pipe_i="${1:-0}"
    local expect="${2:-0}"

    [[ -z ${PIPESTATUS} ]] \
        && [[ $((${#PIPESTATUS[@]} + 1)) -gt ${pipe_i} ]] \
        && [[ ${PIPESTATUS[$which]} -ne ${expect} ]] \
        || return 255

    return ${expect}
}

function locate_command() {
    local bin_named="${1}"
    local bin_fixed="${2:-}"
    local bin_found

    [[ -z "${bin_named}" ]] \
        && write

    bin_found="$(command -v "${bin_named}" 2> /dev/null)"

    is_successful_pipe_exit \
        || bin_found="${bin_fixed}"

    local bin_located="$(command -v shunit2 2> /dev/null)"
    local bin_default="/usr/share/shunit2/shunit2"

    [ -z "${bin_located}" ] \
        && bin_located="${bin_default}"

    [[ -r "${bin_located}" ]] \
        && printf "${bin_located}" \
        || return 255
}

function locate_command_shunit() {
    local bin_located="$(command -v shunit2 2> /dev/null)"
    local bin_default="/usr/share/shunit2/shunit2"

    [ -z "${bin_located}" ] \
        && bin_located="${bin_default}"

    [[ -r "${bin_located}" ]] \
        && printf "${bin_located}" \
        || return 255
}

function download() {
    if command -v wget >/dev/null; then
        wget -c -O "$2" "$1"
    elif command -v curl >/dev/null; then
        curl -L -C - -o "$2" "$1"
    else
        error "Could not find wget or curl"
        return 1
    fi
}

function detect_system() {
    # adapted from RVM: https://github.com/wayneeseguin/rvm/blob/master/scripts/functions/utility_system#L3
    system_type="unknown"
    system_name="unknown"
    system_version="unknown"
    system_arch="$(uname -m)"

    case "$(uname)" in
        (Linux|GNU*)
            system_type="linux"

            if [[ -f /etc/lsb-release ]] && [[ "$(< /etc/lsb-release)" == *"DISTRIB_ID=Ubuntu"* ]]; then
                system_name="ubuntu"
                system_version="$(awk -F'=' '$1=="DISTRIB_RELEASE"{print $2}' /etc/lsb-release)"
                system_arch="$(dpkg --print-architecture)"
            elif [[ -f /etc/lsb-release ]] && [[ "$(< /etc/lsb-release)" == *"DISTRIB_ID=LinuxMint"* ]]; then
                system_name="mint"
                system_version="$(awk -F'=' '$1=="DISTRIB_RELEASE"{print $2}' /etc/lsb-release)"
                system_arch="$( dpkg --print-architecture )"
            elif [[ -f /etc/lsb-release ]] && [[ "$(< /etc/lsb-release)" == *"DISTRIB_ID=ManjaroLinux"* ]]; then
                system_name="manjaro"
                system_version="$(awk -F'=' '$1=="DISTRIB_RELEASE"{print $2}' /etc/lsb-release)"
            elif [[ -f /etc/os-release ]] && [[ "$(< /etc/os-release)" == *"ID=opensuse"* ]]; then
                system_name="opensuse"
                system_version="$(awk -F'=' '$1=="VERSION_ID"{gsub(/"/,"");print $2}' /etc/os-release)" #'
            elif [[ -f /etc/SuSE-release ]]; then
                system_name="suse"
                system_version="$(
                awk -F'=' '{gsub(/ /,"")} $1~/VERSION/ {version=$2} $1~/PATCHLEVEL/ {patch=$2} END {print version"."patch}' < /etc/SuSE-release
                )"
            elif [[ -f /etc/debian_version ]]; then
                system_name="debian"
                system_version="$(awk -F. '{print $1"."$2}' /etc/debian_version)"
                system_arch="$( dpkg --print-architecture )"
            elif [[ -f /etc/os-release ]] && [[ "$(< /etc/os-release)" == *"ID=debian"* ]]; then
                system_name="debian"
                system_version="$(awk -F'=' '$1=="VERSION_ID"{gsub(/"/,"");print $2}' /etc/os-release | awk -F. '{print $1"."$2}')" #'
                system_arch="$( dpkg --print-architecture )"
            elif [[ -f /etc/fedora-release ]]; then
                system_name="fedora"
                system_version="$(grep -Eo '[[:digit:]]+' /etc/fedora-release)"
            elif [[ -f /etc/centos-release ]]; then
                system_name="centos"
                system_version="$(grep -Eo '[[:digit:]\.]+' /etc/centos-release | awk -F. '{print $1"."$2}')"
            elif [[ -f /etc/redhat-release ]]; then
                if [[ "$(< /etc/redhat-release)" == *"CentOS"* ]]; then
                    system_name="centos"
                else
                    system_name="redhat"
                fi

                system_version="$(grep -Eo '[[:digit:]\.]+' /etc/redhat-release | awk -F. '{print $1"."$2}')"
            elif [[ -f /etc/system-release ]] && [[ "$(< /etc/system-release)" == *"Amazon Linux AMI"* ]]; then
                system_name="amazon"
                system_version="$(grep -Eo '[[:digit:]\.]+' /etc/system-release | awk -F. '{print $1"."$2}')"
            elif [[ -f /etc/gentoo-release ]]; then
                system_name="gentoo"
                system_version="base-$(< /etc/gentoo-release | awk 'NR==1 {print $NF}' | awk -F. '{print $1"."$2}')"
            elif [[ -f /etc/arch-release ]]; then
                system_name="arch"
                system_version="libc-$(ldd --version | awk 'NR==1 {print $NF}' | awk -F. '{print $1"."$2}')"
            else
                system_version="libc-$(ldd --version | awk 'NR==1 {print $NF}' | awk -F. '{print $1"."$2}')"
            fi
            ;;

        (SunOS)
            system_type="sunos"
            system_name="solaris"
            system_version="$(uname -v)"

            if [[ "${system_version}" == joyent* ]]; then
                system_name="smartos"
                system_version="${system_version#* }"
            elif [[ "${system_version}" == oi* ]]; then
                system_name="openindiana"
                system_version="${system_version#* }"
            fi
            ;;

        (OpenBSD)
            system_type="bsd"
            system_name="openbsd"
            system_version="$(uname -r)"
            ;;

        (Darwin)
            system_type="darwin"
            system_name="osx"
            system_version="$(sw_vers -productVersion)"
            system_version="${system_version%.*}" # only major.minor - teeny is ignored
            ;;

        (FreeBSD)
            system_type="bsd"
            system_name="freebsd"
            system_version="$(uname -r)"
            system_version="${system_version%%-*}"
            ;;

        (*)
            return 1
            ;;
    esac

    system_type="${system_type//[ \/]/_}"
    system_name="${system_name//[ \/]/_}"
    system_version="${system_version//[ \/]/_}"
    system_arch="${system_arch//[ \/]/_}"
    system_arch="${system_arch/amd64/x86_64}"
    system_arch="${system_arch/i[123456789]86/i386}"
}
