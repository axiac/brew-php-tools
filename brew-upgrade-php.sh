#!/bin/bash
#
# Upgrade one or more PHP versions installed using Homebrew.
#
# Multiple PHP versions can be installed side-by-side on the same macOS or Linux system.
# After a Homebrew formula is installed or updated, Homebrew runs `brew link` to
# symlink the formula's installed files into the Homebrew prefix.
# Because different versions of the same software usually provide the same files to be linked,
# they are marked as conflicting each other and Homebrew doesn't allow the installation
# or update of a version when a different version is already linked.
#
# This script upgrades the PHP versions and their extensions specified as command line arguments.
#
# @link http://brew.sh Homebrew for macOS
# @link http://linuxbrew.sh Homebrew for Linux
#


#
# Work variables
CURRENT=''              # version number (e.g. '56') of the current active PHP version
CURR_TXT=''             # friendly-formatted number of the current active PHP version (e.g. '5.6')
VERSIONS=()             # version numbers of all installed PHP versions (e.g. (56 70 71)
VERS_TXT=''             # friendly-formatted numbers of all installed PHP versions, (e.g. '5.6, 7.0, 7.1')
FORMULAE=()             # formula names from the command line, without the "php" prefix
PHP=()                  # version numbers of the PHP versions associated with the names in $FORMULA[*]
INT=''
EXT=()


###########################################################################
# Functions
#

#
# Check the number of arguments provided in the command line
# Display the help then exit(1) when no arguments are provided.
# @param int $1 the number of arguments provided in the command line
without_args_show_help() {
    if [ $1 -eq 0 ]; then
        echo Usage: $(basename $0) '<PHP versions> <PHP extensions>'
        echo '    <PHP versions>, <PHP extensions> - Homebrew formula names (e.g. "php56", "php56-xdebug")'
        echo
        echo "The installed PHP versions are: "${VERS_TXT}
        exit 1
    fi
}

#
# Analyze the arguments provided in the command line and extract the affected PHP versions.
# Validate the extracted PHP versions against the list of available PHP versions (stored in $VERSIONS).
# Exit(2) when an invalid version is encountered
# @param $@ the arguments provided in the command line
parse_and_validate_arguments() {
    FORMULAE=()
    PHP=()
    for i in $@; do
        local f=${i#php}                      # formulae name, without the "php" prefix; e.g. "54" or "54-xdebug"
        local p=${f::2}                       # PHP version, without the dot; e.g. "54"
        if { echo "${VERSIONS[*]}" | grep -q "\b$p\b"; }; then
            FORMULAE[${#FORMULAE[*]}+1]=$f
            PHP[${#PHP[*]}+1]=$p
        else
            echo "Invalid argument \"$i\" (unknown/uninstalled PHP version)." >&2
            echo "The valid (installed) versions are: ${VERSIONS[*]}"
            exit 2
        fi
    done
    # Sort PHP versions, remove duplicates
    readonly PHP=($(printf "%s\n" ${PHP[*]} | sort -u))
    readonly FORMULAE
}

#
# Detect the currently installed PHP version (extract the information from the output of 'php -v')
# Store its number in $CURRENT and its pretty-formatted value in $CURR_TXT
find_current_version() {
    readonly CURRENT=$(php -v | head -n 1 | sed -e 's/PHP *\([0-9]*\)\.\([0-9]*\).*$/\1\2/')
    readonly CURR_TXT=${CURRENT:0:1}.${CURRENT:1:2}
}

#
# Detect all PHP versions installed using brew
# Put their version numbers in the $VERSIONS array (e.g. (53 55)
# Put their pretty-formatted versions in $VERS_TXT (separated by comma)
get_installed_versions() {
    local RE='s/^\(php\)*\([0-9]\)\([0-9]\)/\2.\3,/'
    VERSIONS=($(brew list -1 | grep "^php\d\d$" | sed s/^php//))
    local TEXT=$(brew list -1 | grep "^php\d\d$" | sed $RE)
    readonly VERS_TXT=${TEXT%,}
}

#
# Display
show_installed_versions() {
    echo "Installed versions:" ${VERS_TXT}
    echo "Active version:" ${CURR_TXT}
}


#
# Extract from $FORMULAE:
#  * the interpreter into $INT: the value of $1 if it is present in $FORMULAE
#  * the extensions  into $EXT: the PHP extensions for php$INT to upgrade
# @param $1 a PHP version (53 54 55 56 70 71)
get_int_ext() {
    local p=$1

    INT=""
    EXT=()
    for f in ${FORMULAE[*]}; do
        if [ "$f" = "$p" ]; then
            INT=${p}
        else
            if [ "${f:0:2}" = "$p" ]; then
                EXT[${#EXT[*]}+1]=${f}
            fi
        fi
    done
}


#
# Link one PHP version
# @param $1 the PHP version number to link (e.g. 56)
link() {
    echo "* brew link --overwrite php$1"
    brew link --overwrite php$1
}

#
# Unlink one PHP version
# @param $1 the PHP version number to unlink (e.g. 56)
unlink() {
    echo "* brew unlink php$1"
    brew unlink php$1
}

#
# Unlink all installed PHP versions (they are listed in $VERSIONS[])
unlink_all() {
    for f in ${VERSIONS[*]}; do
        echo "* brew unlink php$f"
        brew unlink php$f
    done
}

#
# Upgrade one PHP version
# @param $1 the version number of PHP to upgrade (e.g. 56)
upgrade() {
    echo "* brew upgrade php$1"
    brew upgrade php$1
}



main () {
    find_current_version
    get_installed_versions

    without_args_show_help $#
    parse_and_validate_arguments "$@"

    echo "============ Unlink all versions ============"
    unlink_all

    # Process only the involved PHP versions
    for p in ${PHP[*]}; do
        echo "============== Process PHP ${p:0:1}.${p:1:2} =============="
        get_int_ext $p

        if [ "$INT" = "$p" ]; then
            upgrade ${p}
        else
            link ${p}
        fi

        for f in ${EXT[*]}; do
            upgrade ${f}
        done

        unlink ${p}
    done

    echo "======= Re-link current version ($CURR_TXT) ======="
    link ${CURRENT}

    echo "================ That's all! ================"
}


# Let's go!
main "$@"

# That's all, folks!
