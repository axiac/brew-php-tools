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
CURRENT=''              # formula name (e.g. 'php56') of the current active PHP version
CURR_TXT=''             # friendly-formatted number of the current active PHP version (e.g. '5.6')
VERSIONS=()             # formula names of all installed PHP versions (e.g. (php56 php70 php71)
VERS_TXT=''             # friendly-formatted numbers of all installed PHP versions, (e.g. '5.6, 7.0, 7.1')
INSTALLED=()            # formula names of all installed PHP versions and extensions
FORMULAE=()             # formula names from the command line, with the "php" prefix added if it's missing
PHP=()                  # formula names of the PHP versions associated with the names in $FORMULA[*]
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
        show_installed_versions
        exit 1
    fi
}

#
# Analyze the arguments provided in the command line and extract the affected PHP versions.
# Validate the extracted PHP versions against the list of available PHP versions (stored in $VERSIONS).
# Remove duplicates
# Terminate the script with exit(2) when an invalid version is encountered.
# @param $@ the arguments provided in the command line
parse_and_validate_arguments() {
    FORMULAE=()
    PHP=()
    for i in $@; do
        # Normalize formula name (accept arguments that miss the "php" prefix)
        local f=php${i#php}                     # formulae name, with "php" prefix; e.g. "php54" or "php54-xdebug"
        # Verify that the formula is installed
        if { echo "${INSTALLED[*]}" | grep -q "\b$f\b"; }; then
            FORMULAE[${#FORMULAE[*]}+1]=$f
        else
            echo "Invalid argument \"$i\": unknown/uninstalled PHP version or extension." >&2
            echo "The valid (installed) PHP versions and extensions are:"
            echo "     ${INSTALLED[*]}" >&2
            exit 2
        fi
        # Remember the PHP version (will process all extensions of one PHP version in a single batch)
        local p=${f::5}                         # name of the PHP version formula (e.g. "php54")
        if { echo "${VERSIONS[*]}" | grep -q "\b$p\b"; }; then
            FORMULAE[${#FORMULAE[*]}+1]=$f
            PHP[${#PHP[*]}+1]=$p
        else
            echo "Invalid argument \"$i\": the formula \"$p\" is not installed." >&2
            echo "The valid (installed) PHP versions and extensions are: ${INSTALLED[*]}" >&2
            exit 2
        fi
    done
    # Sort versions and formulae, remove duplicates
    PHP=($(printf "%s\n" ${PHP[*]} | sort -u))
    FORMULAE=($(printf "%s\n" ${FORMULAE[*]} | sort -u))

    readonly PHP
    readonly FORMULAE
}

#
# Detect the currently installed PHP version (extract the information from the output of 'php -v')
# Store its number in $CURRENT and its pretty-formatted value in $CURR_TXT
find_current_version() {
    readonly CURRENT=$(php -v | head -n 1 | sed -e 's/PHP *\([0-9]*\)\.\([0-9]*\).*$/php\1\2/')
    readonly CURR_TXT=${CURRENT:3:1}.${CURRENT:4:2}
}

#
# Detect all PHP versions and PHP extensions installed using brew
# Store:
#  * the Homebrew formula names of the PHP versions in the $VERSIONS array (e.g. (php53 php55))
#  * the pretty-formatted version numbers in $VERS_TXT, separated by comma (e.g. "5.3, 5.6")
#  * the Homebrew formula names of the PHP extensions in the $INSTALLED array
get_installed_versions() {
    local RE='s/^\(php\)*\([0-9]\)\([0-9]\)/\2.\3,/'
    local ALL=$(brew list -1 | grep '^php\d\d')
    local VERS=$(echo "$ALL" | grep "^php\d\d$")
    VERSIONS=($VERS)
    INSTALLED=($ALL)
    local TEXT=$(echo "$VERS" | sed $RE)
    readonly VERS_TXT=${TEXT%,}
    readonly VERSIONS
    readonly INSTALLED
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
# @param $1 the Homebrew formula name of a PHP version (e.g. "php56")
get_int_ext() {
    local p=$1

    INT=""
    EXT=()
    for f in ${FORMULAE[*]}; do
        if [ "$f" = "$p" ]; then
            INT=${p}
        else
            if [ "${f:0:5}" = "$p" ]; then
                EXT[${#EXT[*]}+1]=${f}
            fi
        fi
    done
}


#
# Link one PHP version
# @param $1 the Homebrew formula name of the PHP version to link (e.g. php56)
link() {
    echo "* brew link --overwrite $1"
    brew link --overwrite $1
}

#
# Unlink one PHP version
# @param $1 the Homebrew formula name of the PHP version to unlink (e.g. php56)
unlink() {
    echo "* brew unlink $1"
    brew unlink $1
}

#
# Unlink all installed PHP versions (they are listed in $VERSIONS[])
unlink_all() {
    for f in ${VERSIONS[*]}; do
        echo "* brew unlink $f"
        brew unlink $f
    done
}

#
# Upgrade one PHP version
# @param $1 the Homebrew formula name of the PHP to upgrade (e.g. php56)
upgrade() {
    echo "* brew upgrade $1"
    brew upgrade $1
}



main() {
    find_current_version
    get_installed_versions

    without_args_show_help $#
    parse_and_validate_arguments "$@"

    echo "============ Unlink all versions ============"
    unlink_all

    # Process only the involved PHP versions
    for p in ${PHP[*]}; do
        echo "============== Process PHP ${p:3:1}.${p:4:1} =============="
        get_int_ext $p

        # If the interpreter is not in the list of formulae to upgrade
        # then link it to be able to upgrade its extensions
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
