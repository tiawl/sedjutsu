# sedjutsu

A collection of cursed scripts only usable when you are stucked with GNU `sed`

## Why ?

Do not be fooled by the above seductive sentence. Most of the time, even when working in a very restrictive environment, GNU `sed` is not the only friend you have and is certainly not the best for what you want to do with. To mention some of them: `awk`, `perl` or `sh` are probably already installed on the server you are working on, and except for efficiency concerns for very specific cases (this is a dubious one, because even in this category, GNU `sed` does not shine), you should consider these options before.

The main purpose of this repository is for challenge: some standard utilities can be emutaled with GNU `sed` and are already covered into the [GNU sed documentation][1]. But some of them are not and I am having some fun writing useless GNU `sed` scripts.

## Important notes

- Each script has its own README with its own instructions to use it.
- You probably already noticed, but the scripts was written and tested with the GNU implementation of `sed`. If you want to make a script work with other `sed` implementations, you will need to rework it. Depending of the script and the `sed` implementation you are using, the amount of work needed can vary a lot. It may range from just some minor replacements to more technical rewriting due to the implementation's limited feature set.

## Status

Currently this repository only contains scripts to deal with JSON. But it is not dedicated to this task. I will fill it with other usecases with time.

## Contributing

If you have other GNU `sed` idea to emulate standard utilities:
- you can open a pull request for your script,
- you can open an issue (if I am interested in and have time for, I will go for it. Otherwise I will let it opened if someone else is interested to implement your idea)

## License

This repository is dedicated to the public domain. See the LICENSE file for more details.

[1]:https://www.gnu.org/software/sed/manual/sed.html#Examples
