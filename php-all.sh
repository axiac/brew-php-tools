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
    local VERSIONS=($(brew list -1 | grep "^php\d\d$" | sed s/^php//))

    # Run the command line using all the configured PHP version
    for i in ${VERSIONS[*]}; do
        echo "=================== PHP $(echo ${i} | sed 's/^./&./') ==================="
        $(brew --prefix php${i})/bin/php "$@"
    done
}


# Let's go!
main "$@"

# That's all, folks!
