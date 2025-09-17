# sedjutsu

A set of cursed scripts emulating standard utilities only usable when you are stucked with GNU `sed`

## Warning

Do not be fooled by the above seductive sentence. Most of the time, even when working in a very restrictive environment, if you can find GNU `sed` on the server you are working on, it is certainly neither the only friend you have nor the best choice for what you are trying to achieve. Among (maybe not so) many other tools already installed on the server you are working on, you can probably find `awk`, `perl`, `python` or a shell. Except for very specific usecases, these are options you should consider before.

## So why ?

The main purpose of this repository is the challenge. Some popular utilities are already covered into the [GNU sed documentation][1] but GNU `sed` can do much more and I am having fun writing useless GNU `sed` scripts without relying on external tools.

## What you can find here

Some features implemented with GNU `sed` originated from these utilities:
- `base64`
- `bc`
- `dc`
- `hd`
- `jq`
- `json_pp`
- `json_xs`
- `od`
- `xxd`
- `yes`
- `yq`

## Important notes

- Each script has its own README written as a header comment. **You can find a (GIF-formatted) WATCHME version for each README into the demos directory**. Except a brief description, it contains useful details to make the script work:
    - A command example.
    - A set of usable environment variables to configure the script.
    - Potential known limitations.
- If you want to make a script work with an other `sed` implementations than the GNU one, you will need to rework it. Depending of the script and the `sed` implementation you are using, the amount of work needed can vary a lot. It may range from just some minor replacements to more technical rewriting due to differences between the implementations' feature set.
- I assume a POSIX-compliant shell (bash, ash, dash, ...) is also installed on your laptop.

## Contributing

If you have other GNU `sed` idea to emulate other utilities:
- you can open a pull request for your script,
- you can open an issue (if I am interested in and have time for, I will go for it. Otherwise I will let it opened if someone else is interested to implement your idea)

## License

This repository is dedicated to the public domain. See the LICENSE file for more details.

[1]:https://www.gnu.org/software/sed/manual/sed.html#Examples
