#!/bin/zsh
# The above line is only for editors:
# This file is meant to be sourced from interactive zsh
# (e.g. as /etc/zshrc or ~/.zshrc)
#
# When sourcing this file, you should have set PATH and also
#   interactive=/path/to/bashrc_file_for_interactive_mode
#   DEFAULTS=(/paths/to/dirs-with-local-configuration-files)
#   GITS=(/paths/to/dirs-with-local-git-packages)
#   EPREFIX=(/root-directories)
#   (the arrays can be also single strings)
# if you want to make use of the corresponding features;
# See the README file in this folder for more details.

export SHELL=/bin/zsh

# source $interactive in bash compatibility mode:
[[ -n ${interactive:++} ]] && [[ -f $interactive ]] && () {
	emulate -L sh
	setopt ksh_glob no_sh_glob brace_expand no_nomatch
	. "$interactive"
}

# Some pipe aliases which cannot be defined for bash:

alias -g 'CAT'='|& cat -A'
alias -g 'TAIL'='|& tail -n $(( $LINES - 3 ))'
alias -g 'LESS'='|& less -Rs'
alias -g 'NUL'='>/dev/null'
alias -g 'NULL'='NUL'
alias -g 'NIL'='>&/dev/null'

# Force 256 colors on terminals which typically set an inappropriate TERM:

have_term() {
	local i
	for i in ${TERMINFO-} ${TERMINFO_DIRS-} ${HOME:+"$HOME/.terminfo"} \
		${EPREFIX:+${^EPREFIX%/}/usr/{,share/}{,lib/}terminfo} \
		${EPREFIX:+${^EPREFIX%/}/{etc,lib}/terminfo} \
		/usr/{,share/}{,lib/}terminfo \
		/{etc,lib}/terminfo
	do	! [[ -z $i || ! -d $i ]] && \
		[[ -r $i/${1:0:1}/$1 || -r $i/$1 ]] && return
	done
	return 1
}

case ${TERM-} in
(tmux*)
	have_term tmux || TERM=screen${TERM#tmux};;
(screen*)
	[[ -z ${TMUX:++} ]] || ! have_term tmux || TERM=tmux${TERM#screen};;
esac
case ${TERM-} in
(xterm|screen|tmux|rxvt)
	TERM=$TERM-256color;;
esac


# These are needed later on
autoload -Uz add-zsh-hook pick-web-browser zsh-mime-setup is-at-least


# Options (man zshoptions):

setopt no_auto_cd auto_pushd no_cdable_vars no_chase_dots no_chase_links
setopt path_dirs auto_name_dirs bash_auto_list prompt_subst no_beep
setopt no_list_ambiguous list_packed
setopt hist_ignore_all_dups hist_reduce_blanks hist_verify no_hist_expand
setopt extended_glob hist_subst_pattern
setopt no_glob_dots no_nomatch no_null_glob numeric_glob_sort no_sh_glob
setopt mail_warning interactive_comments no_clobber
setopt no_bg_nice no_check_jobs no_hup long_list_jobs monitor notify
setopt warn_create_global
#setopt print_exit_value
! is-at-least 5.2 || setopt glob_star_short


NULLCMD=:
READNULLCMD=less


# Show time/memory for commands running longer than this number of seconds:

REPORTTIME=5
TIMEFMT='%J  %M kB %*E (user: %*U, kernel: %*S)'


# Restore tty settings at every prompt:

ttyctl -f


# History

SAVEHIST=${HISTSIZE:-1000}
unset HISTORYFILE

DIRSTACKSIZE=100


# The code in this file needs some modules

zmodload zsh/complist
zmodload zsh/parameter
zmodload zsh/termcap
zmodload zsh/terminfo
zmodload zsh/zutil


# We want zmv and other nice features (man zshcontrib)
autoload -Uz colors zargs zcalc zed zmv
#colors


# Activate the prompt from https://github.com/vaeth/set_prompt/

() {
	local -a path
	path=(
		${DEFAULTS:+${^DEFAULTS%/}{,/zsh}{/set_prompt,}}
		${GITS:+${^GITS%/}{set_prompt{.git,},}} \
		${EPREFIX+:${EPREFIX%/}/usr/bin}
		$path
	)
	if command -v set_prompt NIL
	then	setopt local_options no_warn_create_global
		(($+functions[set_prompt])) || . set_prompt.sh NIL && {
			set_prompt -r
			. git_prompt.zsh NIL
		}
	fi
}


# Activate support for title from https://github.com/vaeth/runtitle/

(($+commands[title])) && {
	# Title are the first 3 words starting with sane chars (paths cutted)
	# We also truncate to at most 30 characters and add dots if args follow
	set_title() {
		local a b
		a=(${=${(@)${=1}:t}})
		a=(${=${a##[-\&\|\(\)\{\}\;]*}})
		[[ $#a > 3 ]] && b=' ...' || b=
		a=${a[1,3]}
		[[ $#a -gt 30 ]] && a=$a[1,22]'...'$a[-5,-1]
		title $a$b
	}
	add-zsh-hook preexec set_title
}


# Initialize the helping system:

for HELPDIR in '' \
	${DEFAULTS:+{^DEFAULTS%/}{/zsh,}/help} \
	${EPREFIX:+${^EPREFIX%/}/usr/share/zsh/$ZSH_VERSION/help} \
	'/usr/share/zsh/site-contrib/help'
do	[[ -d ${HELPDIR:-/usr/share/zsh/$ZSH_VERSION/help} ]] && {
		alias run-help NUL && unalias run-help
		autoload -Uz run-help
		alias help=run-help
		[[ -n ${HELPDIR:++} ]] || unset HELPDIR
		break
	}
done


# Define LS_COLORS if not already done in $interactive
# (this must be done before setting the completion system colors).
# I recommend https://github.com/vaeth/termcolors-mv/
# but a fallback is used if the corresponding script is not in path.

[[ -n ${LS_COLORS:++} ]] || ! (($+commands[dircolors])) || {
	if (($+commands[dircolors-mv]))
	then	() {
		local i e
		for i in \
			${DEFAULTS:+{^DEFAULTS%/}/dir{_,}colors} \
			${GITS:+{^GITS%/}{/termcolors-mv{.git,},}{/etc,}/dir{_,}colors} \
			${EPREFIX:+${^EPREFIX%/}/etc/dir{_,}colors} \
			''
		do	[[ -n $i && -d $i ]] && \
			e=$(unset DEFAULTS
SOLARIZED=${SOLARIZED-} DEFAULTS=${i%/*} dircolors-mv) && \
			[[ -n $e ]] && eval "$e" && break
		done
	}
	else	() {
		local i
		for i in \
			${DEFAULTS:+{^DEFAULTS%/}/DIR_COLORS} \
			${HOME:+"$HOME/.dircolors"} \
			${EPREFIX:+${^EPREFIX%/}/etc/DIR_COLORS} \
			'/etc/DIR_COLORS'
		do	[[ -f $i ]] && eval "$(dircolors -- "$i")" && break
		done
	}
	fi
}


# Completion System (man zshcompsys):

#zstyle ':completion:*' file-list true # if used, list-colors is ignored
#zstyle ':completion:*' show-ambiguity true # if used, list-colors is essentially ignored
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:processes' list-colors '=(#b) #([0-9]#) #([0-9a-z/-]# #[0-9:]# #)*=01;32=01;36=01;33'
zstyle ':completion:*:*:*:*:hosts' list-colors '=*=00;36'
zstyle ':completion:*:*:*:*:users' list-colors '=*=01;35'
zstyle ':completion:*:*:*:*:modules' list-colors '=*=01;35'
zstyle ':completion:*:*:*:*:interfaces' list-colors '=*=01;35'
zstyle ':completion:*:*:*:*:packages' list-colors '=*=01;32'
zstyle ':completion:*:*:*:*:categories' list-colors '=*=00;32'
zstyle ':completion:*:*:*:*:useflags' list-colors '=*=01;35'
zstyle ':completion:*:reserved-words' list-colors '=*=01;32'
zstyle ':completion:*:aliases' list-colors '=*=01;32'
zstyle ':completion:*:parameters' list-colors '=*=01;36'
zstyle ':completion:*' completer _complete _expand _expand_alias
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select=1 # interactive
zstyle ':completion:*' original true
zstyle ':completion:*' remote-access false
zstyle ':completion:*' use-perl true
zstyle ':completion:*' verbose true
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
# Unfortunately, accept-exact would prevent completing b* if b/ is a directory:
#zstyle ':completion:*' accept-exact true
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' path-completion false
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' use-cache false
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' sort false
if is-at-least 4.3.10
then	zstyle ':completion:*' format '%b%F{yellow}(%d)%f'
else	zstyle ':completion:*' format '%B(%d)%b'
fi

# Make all-matches a widget which inserts all previous matches:
zle -C all-matches complete-word _generic
zstyle ':completion:all-matches:*' old-matches only
zstyle ':completion:all-matches:*' completer _all_matches

# Restrict cd selections:
zstyle ':completion:*:cd:*' tag-order local-directories # directory-stack named-directories path-directories

# Initialize the completion system
(($+functions[compinit])) || {
	[[ -n ${DEFAULTS++} ]] && () {
		local -a d
		d=(${^DEFAULTS%/}/{zsh-,zsh/}completion/***/(N/))
		fpath=(${d%/} $fpath)
	}
	autoload -Uz compinit
	compinit -D # -u -C
}

# Results from CDPATH usually produce confusing completions of cd:
_my_cd() CDPATH= _cd "$@"
compdef _my_cd cd

# mtools completion can hang, so we eliminate it:
compdef _files mattrib mcopy mdel mdu mdeltree mdir mformat mlabel mmd mmount mmove mrd mread mren mtoolstest mtype

# Some private shell functions or wrapper scripts behave like other commands:
(($+functions[mcd])) && compdef mcd=cd
whence gpg.wrapper NUL && compdef gpg.wrapper=gpg
whence ssudox NUL && compdef ssudox=sudox
() {
	local i j
	for i in eix{,-diff,-update,-sync,-test-obsolete} useflags
	do	for j in $i.{32,64}
		do	whence $j NUL && compdef $j=$i && alias $j="noglob $j"
		done
		whence $i NUL && alias $i="noglob $i"
	done
	for i in emerge.{wrapper,noprotect}
	do	whence $i NUL && compdef $i=emerge && alias $i="noglob $i"
	done
	for i in emerge squashmount squash_dir
	do	whence $i NUL && alias $i="noglob $i"
	done
	for i in rsync{,p}{,i}{,.bare}.wrapper
	do	whence $i NUL && compdef $i=rsync
	done
}

# Set keyboard transmit mode during zle so that $terminfo is reliable

if (($+terminfo[smkx]))
then	init-transmit-mode() {
	emulate -L zsh
	printf '%s' ${terminfo[smkx]}
}
	exit-transmit-mode() {
	emulate -L zsh
	printf '%s' ${terminfo[rmkx]}
}
	zle -N zle-line-init init-transmit-mode
	zle -N zle-line-exit exit-transmit-mode
fi

typeset -A key
key=(
	BackSpace "${terminfo[kbs]}"
	Home      "${terminfo[khome]}"
	End       "${terminfo[kend]}"
	Insert    "${terminfo[kich1]}"
	Delete    "${terminfo[kdch1]}"
	Up        "${terminfo[kcuu1]}"
	Down      "${terminfo[kcud1]}"
	Left      "${terminfo[kcub1]}"
	Right     "${terminfo[kcuf1]}"
	PageUp    "${terminfo[kpp]}"
	PageDown  "${terminfo[knp]}"
)
() {
local i k=
for i in \
	Return          $'\C-M' \
	Meta-Return     $'\M-\C-M' \
	Escape-Return   $'\e\C-m' \
	Shift-Return    $'\e[[[sR' \
	Ctrl-Return     $'\e[[[cR' \
	AltGr-Return    $'\e[[[gR' \
	Shift-Insert    $'\e[[[[sI' \
	Ctrl-Up         $'\e[1;5A' \
	Ctrl-Down       $'\e[1;5D' \
	Meta-Up         $'\e[1;3A' \
	Meta-Down       $'\e[1;3B' \
	Shift-Up        $'\e[1;2A' \
	Shift-Down      $'\e[1;2B' \
	AltGr-Up        $'\e[[[gu' \
	AltGr-Down      $'\e[[[gd' \
	Meta-PageUp     $'\e[5;3~' \
	Meta-PageDown   $'\e[6;3~' \
	Ctrl-PageUp     $'\e[40~' \
	Ctrl-PageDown   $'\e[41~' \
	Ctrl-Left       $'\eOD' \
	Ctrl-Right      $'\eOC' \
	Ctrl-Delete     $'\e[[[cD' \
	Shift-Home      $'\e[1;2H' \
	AltGr-BackSpace $'\e[[[gb' \
	Ctrl-BackSpace  $'\e[[[cb' \
	Shift-BackSpace $'\e[[[sb' \
	F10             $'\e[21' \
	Shift-F10       $'\e[21;2~' \
	AltGr-F10       $'\e[21~' \
	Meta-Hash       $'\M-#' \
	Escape-Tab      $'\e\C-i' \
	Escape-Star     $'\e*' \
	Meta-Shift-Star $'\M-*' \
	Escape-Plus     $'\e+' \
	Ctrl-Space      $'\C- $' \
	Ctrl-Plus       $'\C-+' \
	Meta-Plus       $'\M-+' \
	Ctrl-Dot        $'\C-.' \
	Meta-Dot        $'\M-.' \
	Escape-Space    $'\e- ' \
	Meta-Space      $'\M- ' \
	Escape-u        $'\eu' \
	Meta-u          $'\M-u' \
	Ctrl-a          $'\C-a' \
	Ctrl-b          $'\C-b' \
	Ctrl-c          $'\C-c' \
	Ctrl-d          $'\C-d' \
	Ctrl-e          $'\C-e' \
	Ctrl-f          $'\C-f' \
	Ctrl-g          $'\C-g' \
	Ctrl-h          $'\C-h' \
	Ctrl-i          $'\C-i' \
	Ctrl-j          $'\C-j' \
	Ctrl-k          $'\C-k' \
	Ctrl-l          $'\C-l' \
	Ctrl-m          $'\C-m' \
	Ctrl-n          $'\C-n' \
	Ctrl-o          $'\C-o' \
	Ctrl-p          $'\C-p' \
	Ctrl-q          $'\C-q' \
	Ctrl-r          $'\C-r' \
	Ctrl-s          $'\C-s' \
	Ctrl-t          $'\C-t' \
	Ctrl-u          $'\C-u' \
	Ctrl-v          $'\C-v' \
	Ctrl-w          $'\C-w' \
	Ctrl-x          $'\C-x' \
	Ctrl-y          $'\C-y' \
	Ctrl-z          $'\C-z' \
	Escape          $'\e'
do	if [[ -z $k ]]
	then	k=$i
	else	[[ -z ${key[(re)$i]:++} ]] && key[$k]=$i || key[$k]=
		k=
	fi
done
}

# Wrapper function for bindkey: multiple keys, $'$...' refers to terminfo;
# - means -M menuselect

Aa() {
	local b c
	local -a a
	if [[ ${1-} == - ]]
	then	a=(-M menuselect)
		shift
	else	a=()
	fi
	b=$1
	shift
	while [[ $# -gt 0 ]]
	do	case $1 in
		(*[^-a-zA-Z0-9_]*)
			[[ -z ${key[(re)$1]:++} ]] && c=$1 || c=;;
		(*)
			c=${key[$1]};;
		esac
		[[ -z $c ]] || bindkey $a $c $b
		shift
	done
}

# Line editing during completion (man zshmodules: zsh/complist)

Aa - accept-and-infer-next-history Return
Aa - accept-and-hold Meta-Return $'\M-\C-m' $'\C-Í' \
	Escape-Return Shift-Return Ctrl-Return AltGr-Return \
	Escape-Space Meta-Space Ctrl-Space \
	Ctrl-Plus
Aa - undo BackSpace $'\C-?' $'\C-H' \
	Ctrl-Dot Meta-Dot
Aa - send-break Escape Ctrl-c
Aa - backward-word PageUp  $'\e[5~'
Aa - forward-word PageDown $'\e[6~'
Aa - history-incremental-search-forward Ctrl-l
Aa - vi-insert Insert $'\e[2~'
Aa - vi-insert Shift-Insert


# Line editing (man zshzle)

autoload -Uz insert-files predict-on
zle -N insert-files
zle -N predict-on
zle -N predict-off
#predict-on 2>/dev/null

# Let Ctrl-d successively remove tail of line, whole line, and exit
kill-line-maybe() {
	if (($#BUFFER > CURSOR))
	then	zle kill-line
	else	zle kill-whole-line
	fi
}
zle -N kill-line-maybe

bindkey -e
Aa history-beginning-search-backward Up $'\e[A'
Aa history-beginning-search-forward Down $'\e[B'
Aa up-line-or-history Ctrl-Up $'\e[[[cu'
Aa down-line-or-history Ctrl-Down $'\e[[[cd'
Aa up-line-or-history Meta-Up $'\C-aap' $'\e[[[au'
Aa down-line-or-history Meta-Down $'\C-aan' $'\e[[[ad'
Aa up-line-or-history Shift-Up $'\e[[[su'
Aa down-line-or-history Shift-Down $'\e[[[sd'
Aa beginning-of-history AltGr-Up
Aa end-of-history AltGr-Down
Aa up-line-or-history PageUp $'\e[5~'
Aa down-line-or-history PageDown $'\e[6~'
Aa beginning-of-history Meta-PageDown $'\M-\e[5~'
Aa end-of-history Meta-PageUp $'\M-\e[6~'
Aa beginning-of-history Ctrl-PageUp $'\e[5;5~'
Aa end-of-history Ctrl-PageDown $'\e[6;5~'
Aa backward-char Left $'\e[D'
Aa forward-char Right $'\e[C'
Aa backward-word Ctrl-Left $'\e[1;5D' $'\e[[[cl'
Aa forward-word Ctrl-Right $'\e[[[cr' $'\e[1;5C'
Aa delete-char Delete $'\e[3~'
Aa kill-line-maybe Ctrl-Delete
Aa overwrite-mode Insert $'\e[2~' \
	Shift-Insert
Aa beginning-of-line Home $'\e[1~' $'\e[H'
Aa end-of-line End $'\e[4~' $'\e[F'
Aa clear-screen Shift-Home $'\e[[[sH'
Aa backward-delete-char BackSpace $'\C-?' $'\C-H'
Aa backward-kill-line AltGr-BackSpace
Aa kill-line-maybe Ctrl-BackSpace Shift-BackSpace
Aa insert-completions Shift-Return Ctrl-Return
Aa call-last-kbd-macro AltGr-Return
Aa pound-insert Meta-Return $'\M-\C-m' $'\C-Í'
Aa push-input Escape-Return
Aa describe-key-briefly F10
Aa describe-key-briefly Shift-F10
Aa describe-key-briefly AltGr-F10
Aa pound-insert Meta-Hash '£'
Aa all-matches Escape-Tab Escape-Star Escape-Plus Meta-Plus Meta-Shift-Star
Aa undo Escape-u Meta-u
Aa insert-files Ctrl-f
Aa predict-off Ctrl-g
Aa predict-on Ctrl-e
Aa kill-whole-line Ctrl-y Ctrl-x
Aa kill-line-maybe Ctrl-d
Aa yank Ctrl-v
Aa quoted-insert Ctrl-t


# Make files with certain extensions "executable" (man zshbuiltins#alias)
# Actually, we use zsh-mime-setup to this purpose.

# First store typical programs in variables (can be changed later)
# A leading - sign means that also ..._flags=needsterminal is set

Aa() {
	[[ -z ${(P)1-} ]] || {
		eval "typeset -g ${1}_flags=\${${1}_flags-}"
		return
	}
	local i j=$1 r
	shift
	r=$1
	for i
	do	whence ${i#-} NUL && r=$i && break
	done
	typeset -g $j=${r#-}
	[[ $r == -* ]] && typeset -g ${j}_flags=needsterminal || \
		typeset -g ${j}_flags=
}
Aa XFIG xfig
Aa BROWSER pick-web-browser
Aa SOUNDPLAYER -mplayer -mpv -mplayer2
Aa MOVIEPLAYER -mplayer -mpv -mplayer2 smplayer smplayer2 xine-ui kaffeine vlc false
Aa EDITOR -e emacs -vim -vi
Aa DVIVIEWER xdvi kdvi okular evince
Aa PDFVIEWER qpdfview mupdf okular evince zathura apvlv acroread
Aa DJVREADER djview djview4 okular evince
Aa EPUBREADER fbreader calibre firefox
Aa MOBIREADER fbreader calibre
Aa LITREADER calibre
Aa VIEWER {p,}qiv feh kquickshow gwenview eog xv {gimage,gq,qpic}view viewnior
Aa PSVIEWER {,g}gv
Aa OFFICE {libre,o,s}office

# Now we associate extensions to the above programs

Aa() {
	local i j=\$$1 k=${1}_flags
	shift
	for i
	do	zstyle ":mime:.$i:*" handler $j %s
		zstyle ":mime:.${(U)i}:*" handler $j %s
		zstyle ":mime:.$i:*" flags ${(P)k}
		zstyle ":mime:.${(U)i}:*" flags ${(P)k}
	done
}
Aa PSVIEWER {,e}ps
Aa DVIVIEWER dvi
Aa XFIG {,x}fig
Aa OFFICE doc
Aa BROWSER htm{l,} xhtml
Aa PDFVIEWER pdf
Aa DJVREADER djv{u,}
Aa EPUBREADER epub
Aa MOBIREADER mobi prc
Aa LITREADER lit
Aa EDITOR txt text {read,}me 1st now {i,}nfo diz \
	tex bib sty cls {d,l}tx ins clo fd{d,} \
	{b,i}st el mf \
	c{,c,pp,++} h{,pp,++} s{,rc} asm pas pyt for y \
	diff patch
Aa SOUNDPLAYER au mp3 ogg flac aac mpc mid{i,} cmf cms xmi voc wav mod \
	stm rol snd wrk mff smp al{g,2} nst med wow 669 s3m oct okt far mtm
Aa VIEWER gif pcx bmp {p,m}ng xcf xwd cpi tga tif{f,} img pi{1,2,3,c} \
	p{n,g,c}m {b,x}bm xpm jp{g,e,eg} iff art wpg rle
Aa MOVIEPLAYER mp{g,eg} m2v avi flv mkv ogm mp4{,v} m4v mov qt wmv asf \
	rm{,vb} flc fli gl dl swf 3gp vob web webm
unset -f Aa

# For other extensions, we use the defaults of zsh-mime-setup

zstyle ":mime:*" current-shell true
zsh-mime-setup


# Activate syntax highlighting from
# https://github.com/zsh-users/zsh-syntax-highlighting/
#
# Set colors according to a 256 color scheme if supported.
# (We assume always a black background since anything else causes headache.)
# This is tested with xterm and the following xresources:
#
# XTerm*cursorColor: green
# XTerm*background:  black
# XTerm*foreground:  white


if ! (($+ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES)) && is-at-least 4.3.9 && \
	. "$(for i in \
		${DEFAULTS:+${^DEFAULTS%/}{,/zsh}{/zsh-syntax-highlighting,}} \
		${GITS:+${^GITS%/}{zsh-syntax-highlighting{.git,},}} \
		${EXPREFIX:+${^EPREFIX%/}/usr/share/zsh/site-contrib{/zsh-syntax-highlighting,}} \
		/usr/share/zsh/site-contrib{/zsh-syntax-highlighting,} \
		$path
	do	j=$i/zsh-syntax-highlighting.zsh && [[ -f $j ]] && echo -nE $j && exit
	done)" NIL
then	typeset -gUa ZSH_HIGHLIGHT_HIGHLIGHTERS
	ZSH_HIGHLIGHT_HIGHLIGHTERS=(
		main		# color syntax while typing (active by default)
#		patterns	# color according to ZSH_HIGHLIGHT_PATTERNS
		brackets	# color matching () {} [] pairs
#		cursor		# color cursor; useless with cursorColor
#		root		# color if you are root; broken in some versions
	)
	typeset -gUa ZSH_ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
	ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS=(sudo fakeroot fakeroot-ng)
	typeset -ga ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES
	typeset -gA ZSH_HIGHLIGHT_STYLES
	if [[ $(echotc Co) -ge 256 ]]
	then	ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES=(
			fg=98,bold
			fg=135,bold
			fg=141,bold
			fg=147,bold
			fg=153,bold
		)
		ZSH_HIGHLIGHT_STYLES=(
			'default'                       fg=252
			'unknown-token'                 fg=64,bold
			'reserved-word'                 fg=84,bold
			'alias'                         fg=118,bold
			'builtin'                       fg=47,bold
			'function'                      fg=76,bold
			'command'                       fg=40,bold
			'precommand'                    fg=40,bold
			'hashed-command'                fg=40,bold
			'path'                          fg=214,bold
			'path_prefix'                   fg=214,bold
			'path_approx'                   none
			'globbing'                      fg=190,bold
			'history-expansion'             fg=166,bold
			'single-hyphen-option'          fg=33,bold
			'double-hyphen-option'          fg=45,bold
			'back-quoted-argument'          fg=202
			'single-quoted-argument'        fg=181,bold
			'double-quoted-argument'        fg=181,bold
			'dollar-double-quoted-argument' fg=196
			'back-double-quoted-argument'   fg=202
			'assign'                        fg=159,bold
			'bracket-error'                 fg=196,bold
		)
		case ${SOLARIZED:-n} in
		([nNfF0-]*|[oO][fF]*)
			false;;
		esac && ZSH_HIGHLIGHT_STYLES+=(
			'default'                       none
			'unknown-token'                 fg=red,bold
			'reserved-word'                 fg=white
			'alias'                         fg=cyan,bold
			'builtin'                       fg=yellow,bold
			'function'                      fg=blue,bold
			'command'                       fg=green
			'precommand'                    fg=green
			'hashed-command'                fg=green
			'path'                          fg=yellow
			'path_prefix'                   fg=yellow
			'path_approx'                   none
			'globbing'                      fg=magenta
			'single-hyphen-option'          fg=green,bold
			'double-hyphen-option'          fg=magenta,bold
			'assign'                        fg=cyan
			'bracket-error'                 fg=red
		)
	else	ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES=(
			fg=cyan
			fg=magenta
			fg=blue,bold
			fg=red
			fg=green
		)
		ZSH_HIGHLIGHT_STYLES=(
			'default'                       none
			'unknown-token'                 fg=red,bold
			'reserved-word'                 fg=green,bold
			'alias'                         fg=green,bold
			'builtin'                       fg=green,bold
			'function'                      fg=green,bold
			'command'                       fg=yellow,bold
			'precommand'                    fg=yellow,bold
			'hashed-command'                fg=yellow,bold
			'path'                          fg=white,bold
			'path_prefix'                   fg=white,bold
			'path_approx'                   none
			'globbing'                      fg=magenta,bold
			'history-expansion'             fg=yellow,bold,bg=red
			'single-hyphen-option'          fg=cyan,bold
			'double-hyphen-option'          fg=cyan,bold
			'back-quoted-argument'          fg=yellow,bg=blue
			'single-quoted-argument'        fg=yellow
			'double-quoted-argument'        fg=yellow
			'dollar-double-quoted-argument' fg=yellow,bg=blue
			'back-double-quoted-argument'   fg=yellow,bg=blue
			'assign'                        fg=yellow,bold,bg=blue
			'bracket-error'                 fg=red,bold
		)
	fi
	() {
		local i
		for i in {1..5}
		do	ZSH_HIGHLIGHT_STYLES[bracket-level-$i]=${ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES[$i]}
		done
	}
fi


# Activate incremental completion, see https://github.com/hchbaw/auto-fu.zsh/
# (Only the most current versions [branch pu] work with syntax-highlighting)

if (($+functions[auto-fu-init])) || {
	: # Status must be 0 before sourcing auto-fu.zsh
	path=(${DEFAULTS:+${^DEFAULTS%/}{,/zsh}{/auto-fu{.zsh,},}} \
		${GITS:+${^GITS%/}{/auto-fu{.zsh,}{.git,},}}
		${EPREFIX:+${^EPREFIX%/}/usr/share/zsh/site-contrib{/auto-fu{.zsh,},}} \
		/usr/share/zsh/site-contrib{/auto-fu{.zsh,},}
		$path) . auto-fu NIL && auto-fu-install
	} || {
	:
	path=(${DEFAULTS:+${^DEFAULTS%/}{,/zsh}{/auto-fu{.zsh,},}} \
		${GITS:+${^GITS%/}{auto-fu{.zsh,}{.git,},}} \
		${EPREFIX+:${EPREFIX%/}/usr/share/zsh/site-contrib{/auto-fu{.zsh,},}} \
		/usr/share/zsh/site-contrib{/auto-fu{.zsh,},}
		$path) . auto-fu.zsh NIL
	}
then	# auto-fu.zsh gives confusing messages with warn_create_global:
	setopt no_warn_create_global
	# Keep Ctrl-d behavior also when auto-fu is active
	afu+orf-ignoreeof-deletechar-list() {
	afu-eof-maybe afu-ignore-eof zle kill-line-maybe
}
	afu+orf-exit-deletechar-list() {
	afu-eof-maybe exit zle kill-line-maybe
}
	zstyle ':auto-fu:highlight' input
	zstyle ':auto-fu:highlight' completion fg=yellow
	zstyle ':auto-fu:highlight' completion/one fg=green
	zstyle ':auto-fu:var' postdisplay # $'\n-azfu-'
	zstyle ':auto-fu:var' track-keymap-skip opp
	zstyle ':auto-fu:var' enable all
	zstyle ':auto-fu:var' disable magic-space
	if (($+functions[init-transmit-mode]))
	then	zle-line-init() {
	init-transmit-mode
	auto-fu-init
}
		zle -N zle-line-init
	else	zle -N zle-line-init auto-fu-init
	fi
	zle -N zle-keymap-select auto-fu-zle-keymap-select
	zstyle ':completion:*' completer _complete

	# Starting a line with a space or tab or quoting the first word
	# or escaping a word should deactivate auto-fu for that line/word.
	# This is useful e.g. if auto-fu is too slow for you in some cases.
	# Unfortunately, for eix auto-fu is always too slow...
	zstyle ':auto-fu:var' autoable-function/skiplines '[[:blank:]\\"'\'']*|(emerge|eix(|.32|.64))[[:blank:]]*'
	zstyle ':auto-fu:var' autoable-function/skipwords '[\\]*'
fi

! (($+functions[after_zshrc])) || after_zshrc "$@"
