# zshrc-mv

(C) Martin Väth (martin at mvath.de)

You can copy the `zshrc` file completely or partly, as you need.
Comments are welcome.

zshrc is a __zsh__ initialization file (e.g. to be used as `/etc/zshrc` or
`~/.zshrc`) which activates a lot of zsh interactive features.
In particular, all of

- command-completion
- zsh-internal help system
- One or both of https://github.com/zsh-users/zsh-autosuggestions/
  or https://github.com/hchbaw/auto-fu.zsh/
- One of https://github.com/zdharma/fast-syntax-highlighting/
  or https://github.com/zsh-users/zsh-syntax-highlighting/
- https://github.com/vaeth/runtitle/
- https://github.com/vaeth/set_prompt/  (must be v3.0.0 or newer)
- https://github.com/vaeth/termcolors-mv/

are initialized if available.
(For __auto-fu.zsh__ use at least version 0.0.1.13 [only in git, branch `pu`].)

For gentoo, ebuilds for this and all above packages can be found
in the mv overlay (available via layman).

Concerning the colors which `zshrc` sets, only the following cases are tested
(and probably things will look ugly in other cases):
1. You use a terminal with a black background (and the 256 colors are mainly
   tested with xterm - with other terminals e.g. the highlighted colors
   may look differently and maybe bad).
   My testing xresources for xterm contain:
   ```
	XTerm*cursorColor: green
	XTerm*background:  black
	XTerm*foreground:  white
   ```
2. The terminal is specially configured to use
   Ethan Schoonover's solarized colorscheme, see e.g.
   http://ethanschoonover.com/solarized

   Both, light and dark schemes of solarized are tested.
   You have to tell zshrc that you want solarized by setting
   `SOLARIZED=true` (or `light` or `dark`).

Note that the provided `zshrc` file cares only about __zsh__ specific features,
not about "standard" variables, aliases, or functions which you would
normally set in `.profile`, `.bash_profile`, or `.bashrc`:

In particular, `$PATH` etc. are expected to be complete when `zshrc` is
sourced.

Optionally, `zshrc` can source a separate file in which you can set things
like `$PATH`, `$CDPATH`, aliases, or functions for interactive usage in
bash syntax. (You might want to source that separate file also from
`.bash_profile` or `.bashrc` in an interactive __bash__.)
If you want to make use of that feature, you must have set
-	`interactive=`_/path/to/bashrc-file-for-interactive-mode_

when sourcing `zshrc` (or set it in the beginning of `zshrc`).

In order to make it easier for you to modify details set in `zshrc`,
you can define a function `after_zshrc`: If this function is defined,
it is called at the very end of `zshrc` (passing the arguments of the shell),
so you can undo/extend any change done in `zshrc` if you wish to.

Also some other paths are configurable if you have set

-	`DEFAULTS=(`_/paths/to/dirs-with-local-configuration-files_`)`
-	`GITS=(`_/paths/to/dirs-with-local-git-packages_`)`
-	`EPREFIX=(`_/root-directories_`)`

(the arrays can also be single strings; note that if you use __Gentoo__,
`EPREFIX` __must__ be a string)

when you source `zshrc`. More precisely, if `DEFAULTS`, `GITS`, or `EPREFIX`
are defined, then the following files are taken from this location if
they exist:

-	`$DEFAULTS/zsh-completion/*`
-	`$DEFAULTS/zsh/completion/*`

	This and all its subdirectories can contain local zsh completion files

-	`$DEFAULTS/zsh-help`
-	`$DEFAULTS/zsh/help`
-	`$EPREFIX/usr/share/zsh/$ZSH_VERSION/help`
-	`$EPREFIX/usr/share/zsh/site-contrib/help`

	This substitutes `/usr/share/zsh/$ZSH_VERSION/help` or
	`/usr/share/size-contrib/help`.
	The content should be generated with the `Util/helpfiles` script
	as described in the __zsh__ manpage.

-	`$DEFAULTS/dir[_]colors/*`
-	`$GITS[/termcolors-mv[.git]][/etc]/dir[_]colors/*`
-	`$DEFAULTS/DIR_COLORS`

	If `dircolors-mv` (from __termcolors-mv.git__, see above or below)
	is in `$path`, then zshrc uses `dircolors-mv`:
	This selects the appropriate color scheme by taking the environment
	variable `$TERM` and `$SOLARIZED` into account (and __zshrc-mv__
	exports an appropriate `DEFAULTS` for `dircolors-mv`, trying first
	`$DEFAULTS/...` and then `$GITS/...`).
	__termcolors-mv.git__ can be downloaded with

	`git clone https://github.com/vaeth/termcolors-mv.git`

	or (as a gentoo user) installed from the mv overlay.

	If `dircolors-mv` is not in `$PATH`, `zshrc` uses as a fallback the
	first existing of
	* `$DEFAULTS/DIR_COLORS`
	* `~/.dircolors`
	* `/etc/DIRCOLORS`

	(ignoring the values of `$SOLARIZED` and `$TERM` in this case).

-	`$DEFAULTS[/zsh][/zsh-autosuggestions]/zsh-autosuggestions.zsh`
-	`$GITS[/zsh-autosuggestions[.git]]/zsh-autosuggestions.zsh`
-	`$EPREFIX/usr/share/zsh/site-contrib[/zsh-autosuggestions]/zsh-autosuggestions.zsh`

	This substitutes the corresponding file in
	`/usr/share/zsh/site-contrib`. Fallback is to use `$PATH`.
	Download e.g. with

	`git clone https://github.com/zsh-users/zsh-autosuggesitons.git`

	`git checkout features/completion-suggestions`

	Set `ZSHRC_AUTO_ACCEPT` to a nonempty value if the suggestions should be
	automatically accepted with return

	or (as a gentoo user) install from the mv overlay.

-	`$DEFAULTS[/zsh][auto-fu[.zsh]]/auto-fu[.zsh]`
-	`$GITS[/auto-fu[.zsh][.git]]/auto-fu[.zsh]`
-	`$EPREFIX/usr/share/zsh/site-contrib[/auto-fu[.zsh]]/auto-fu[.zsh]`

	This substitutes the corresponding file in
	`/usr/share/zsh/site-contrib`. Fallback is to use `$PATH`.
	Download e.g. with

	`git clone https://github.com/hchbaw/auto-fu.zsh.git`

	`git checkout pu`

	or (as a gentoo user) install from the mv overlay.

    If zsh-autosuggestions and auto-fu.zsh are both installed, only the former
    is used by default. If you want to use the latter instead, set
	`ZSHRC_PREFER_AUTO_FU` to a nonempty value. If you want to use both, set
	instead `ZSHRC_USE_AUTO_FU` to a nonempty value.
	To skip both, set `ZSH_SKIP_AUTO` to a nonempty value.

-	`$DEFAULTS[/zsh][/fast-syntax-highlighting]/fast-syntax-highlighting.plugin.zsh`
-	`$GITS[/fast-syntax-highlighting[.git]]/fast-syntax-highlighting.plugin.zsh`
-	`$EPREFIX/usr/share/zsh/site-contrib[/fast-syntax-highlighting]/fast-syntax-highlighting.plugin.zsh`

	This substitutes the corresponding file in
	`/usr/share/zsh/site-contrib` if available.
	Fallback is to use `$PATH`. Download e.g. with

	`git clone https://github.com/zdharma/fast-syntax-highlighting.git`

	or (as a gentoo user) install from the mv overlay.

-	`$DEFAULTS[/zsh][/zsh-syntax-highlighting]/zsh-syntax-highlighting.zsh`
-	`$GITS[/zsh-syntax-highlighting[.git]]/zsh-syntax-highlighting.zsh`
-	`$EPREFIX/usr/share/zsh/site-contrib[/zsh-syntax-highlighting]/zsh-syntax-highlighting.zsh`

	This substitutes the corresponding file in
	`/usr/share/zsh/site-contrib` if available.
	Fallback is to use `$PATH`. Download e.g. with

	`git clone https://github.com/zsh-users/zsh-syntax-highlighting.git`

	or (as a gentoo user) install from the mv overlay.

	If zsh-syntax-highlighting and fast-syntax-highlighting are both installed,
	the former is used, by default. If you want to use the latter instead, set
	`ZSHRC_PREFER_ZSH_SYNTAX_HIGHLIGHTING` to a nonempty value.
	To skip both, set `ZSH_SKIP_SYNTAX_HIGHLIGHTING` to a nonempty value.

The variables `$DEFAULTS`, `$GIT`, and `$EPREFIX` are not honoured for support
for __runtitle__ and __set_prompt__ (earlier versions of __zshrc-mv__ had some
mixture here). To get support for these packages (which is recommended)
download them with

-	`git clone https://github.com/vaeth/runtitle.git`
-	`git clone https://github.com/vaeth/set_prompt.git`

or (as a gentoo user) install them from the mv overlay
and make sure to have the corresponding directories in your `$PATH`.
