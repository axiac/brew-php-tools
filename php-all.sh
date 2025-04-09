#!/bin/bash
#
# Run a command line using all the PHP versions installed using Homebrew.
#
# Multiple PHP versions can be installed side-by-side on the same macOS or Linux system.
# This script runs all of them using the arguments provided in the command line.
#
# @link http://brew.sh Homebrew for macOS
# @link http://linuxbrew.sh Homebrew for Linux
#


main() {
    # Find all PHP versions installed using Homebrew
    # Old versions, not updated any more
    local OLD_VERS=($(brew list -1 | grep "^php\d\d$"))
    # Run the command line using all the configured PHP version
    for p in ${OLD_VERS[*]}; do
        echo "=================== PHP ${p:3:1}.${p:4:1} ==================="
        $(brew --prefix $p)/bin/php "$@"
    done

    # Using the new format for previous versions
    local VERSIONS=($(brew list -1 | grep -E "^php@\d\.\d$"))

    # Run the command line using all the configured PHP version
    for p in ${VERSIONS[*]}; do
        echo "=================== PHP ${p:4:3} ==================="
        $(brew --prefix $p)/bin/php "$@"
    done

    # The current version
    echo "=================== PHP  ==================="
    $(brew --prefix php)/bin/php "$@"
}


# Let's go!
main "$@"

# That's all, folks!
