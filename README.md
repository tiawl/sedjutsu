# sedjutsu

A collection of cursed scripts only usable when you are stucked with GNU `sed`

## Warning

Do not be fooled by the above seductive sentence. Most of the time, even when working in a very restrictive environment, GNU `sed` is not the only friend you have and is certainly not the best choice for what you are trying to achieve. Among (maybe not so) many other tools already installed on the server you are working on, you can probably find `awk`, `perl`, `python` or a shell. Except for very specific usecases, these are options you should consider before.

## So why ?

The main purpose of this repository is the challenge. I am having fun writing useless GNU `sed` scripts.

## What you can find here

- Some standard utilities emutaled with GNU `sed` and not already covered into the [GNU sed documentation][1],
- Potentially famous and simple games.

## Important notes

- Each script has its own README written as a header comment. It contains:
    - A set of external dependencies: for most of the scripts, you only need GNU `sed`. But for others it is not enough. In this case a "PREREQUISITES" section, into the README, indicates what is required to make the script run. I try to keep the set of external dependencies as minimal as possible, with these restrictions in mind:
        1) Use GNU `sed` scripting when possible,
        2) If not, use POSIX-compliant shell: (bash, ash, dash, ...) or POSIX-compliant utilities to make it possible,
        3) If not, use other GNU utilities to make it possible (you already need GNU `sed` to run scripts you can find here, so I assume other GNU utilities are also installed).
    - A Linux-only banner. If possible I would like to open Linux-only scripts to other POSIX-compliant operating systems.
    - A command to run the script.
    - A set of usable environment variables to configure the script.
- You probably already noticed, but the scripts was written and tested with the GNU implementation of `sed`. If you want to make a script work with other `sed` implementations, you will need to rework it. Depending of the script and the `sed` implementation you are using, the amount of work needed can vary a lot. It may range from just some minor replacements to more technical rewriting due to differences between the implementations' feature set.

## Contributing

If you have other GNU `sed` idea to emulate standard utilities:
- you can open a pull request for your script,
- you can open an issue (if I am interested in and have time for, I will go for it. Otherwise I will let it opened if someone else is interested to implement your idea)

## License

This repository is dedicated to the public domain. See the LICENSE file for more details.

[1]:https://www.gnu.org/software/sed/manual/sed.html#Examples
