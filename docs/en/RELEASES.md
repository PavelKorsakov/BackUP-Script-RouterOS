# Releases

[Contents](../../README.md)

## Version 2.3.1

**A maintenance and hotfix release following the published version 2.3.0.**

The single-file architecture and the GNU Bash 4.4 minimum remain unchanged. `UseIncremental` is now a canonical boolean setting: `false` skips the post-backup comparison and incremental-retention step and keeps every newly created and successfully validated artifact. It has no dedicated CLI switch.

Monthly archiving has corrected calendar ordering and hardened metadata handling for qualified network storage, while strict local-filesystem metadata checks remain in effect. The Configuration Editor and BackUP Master now use an accepted viewport on shorter terminals instead of requiring every form row to fit at once.

Russian and English remain built in. Version 2.3.1 ships external runtime translations for German, Spanish, Latvian, Polish, and Ukrainian (`de`, `es`, `lv`, `pl`, `uk`), plus `en.lang` as the complete canonical 245-key translation template. User documentation is available in 11 languages.

Notifications are still not implemented and remain outside the scope of this release.

<br />

See [INSTALL.md](INSTALL.md) for instructions on obtaining the files, verifying checksums, and preparing the script for use.
