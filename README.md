## The tools

### `brew-upgrade-php.sh`

Multiple PHP versions can be installed side-by-side on the same macOS or Linux system.
After a Homebrew formula is installed or updated, Homebrew runs `brew link` to
symlink the formula's installed files into the Homebrew prefix.

Because different versions of the same software usually provide the same files to be linked,
they are marked as conflicting each other and Homebrew doesn't allow the installation
or update of a version when a different version is already linked.

`brew-upgrade-php.sh` upgrades one or many installed PHP versions and their extensions
using a single command. It takes care of the `brew link` issue and it leaves the currently
active PHP version still active after it completes.

Usage:

    # Update Homebrew and its taps
    $ brew update
    # Spot the outdated packages
    $ brew outdated
    # Upgrade all upgradable PHP versions and extensions with a single command line
    $ brew-upgrade-php.sh php56 71 56-xdebug php70-gd

It accepts as arguments a list of package names of PHP and its extensions. For convenience,
the `php` prefix can be omitted. `71` and `56-xdebug` from the above example are equivalent
to `php71` and `php56-xdebug`.

The order of arguments in the command line is not important. The script groups the names
by the version of PHP and upgrades all the extensions together with the PHP version they
belong to.

Only the installed PHP versions and extensions are allowed. Not installed (or invalid) 
PHP versions or extensions are identified and reported.


### `php-all.sh`

This command can be used to quickly run a PHP script (or an inline piece of PHP code) using
all the PHP versions installed on the computer (using Homebrew).

It has the same command line as `php`. All it does is to find the installed PHP versions
(using `brew list`) then to run each of them with the command line arguments it was invoked.

Usage:

    php-all.sh --version


## More about Homebrew

* [Homebrew for macOS][homebrew] (the original Homebrew)
* [Homebrew for Linux][linuxbrew] (Linuxbrew, a fork for Linux)


[homebrew]: http://brew.sh "Homebrew - The missing package manager for macOS"
[linuxbrew]: http://linuxbrew.sh "Linuxbrew - The Homebrew package manager for Linux"
