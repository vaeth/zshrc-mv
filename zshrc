#!/bin/zsh
# The above line is only for editors:
# This file is meant to be sourced from interactive zsh
# (e.g. as /etc/zshrc or ~/.zshrc)
#
# When sourcing this file, you should have set PATH and also
#   interactive=/path/to/bashrc_file_for_interactive_mode
#   DEFAULTS=/path/to/local/configuration/files
# if you want to make use of the corresponding features.
# See the README file in this folder for more details.

export SHELL=/bin/zsh

# source $interactive in bash compatibility mode:
() {
	emulate -L sh
	setopt kshglob noshglob braceexpand nonomatch
	[[ -f $interactive ]] && . "$interactive"
}

# Some pipe aliases which cannot be defined for bash:

alias -g 'CAT'='|& cat -A'
alias -g 'TAIL'='|& tail -n $(( $LINES - 3 ))'
alias -g 'LESS'='|& less -Rs'
alias -g 'NUL'='>/dev/null'
alias -g 'NULL'='NUL'
alias -g 'NIL'='>&/dev/null'

# Force 256 colors on terminals which typically set an inappropriate TERM:

case $TERM in
(xterm|screen|tmux|rxvt)
	TERM="${TERM}-256color";;
esac


# Options (man zshoptions):

setopt noautocd autopushd cdablevars nochasedots nochaselinks
setopt pathdirs autonamedirs bashautolist promptsubst nobeep nolistambiguous
setopt listpacked
setopt histignorealldups histreduceblanks histverify nohistexpand
setopt extendedglob histsubstpattern
setopt nodotglob nonomatch nonullglob numericglobsort noshglob
setopt mailwarning interactivecomments noclobber
setopt nobgnice nocheckjobs nohup longlistjobs monitor notify
#setopt printexitvalue

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

# Activate the prompt from https://github.com/vaeth/set_prompt/

() {
	local i
	i=$(whence -w set_prompt) && {
		[[ "$i" == *'function' ]] || \
			path=(${DEFAULTS:+${^DEFAULTS%/}{/zsh,}{/set_prompt,}} \
				$path) . set_prompt.sh
	}
} && {
	set_prompt -r
	path=(${DEFAULTS:+${^DEFAULTS%/}{/zsh,}} $path) . git_prompt.zsh
}


# I want zmv and other nice features (man zshcontrib)
autoload -Uz zmv zcalc zargs colors
#colors


# These are needed in the following:
autoload -Uz pick-web-browser zsh-mime-setup is-at-least


# Initialize the helping system:

for HELPDIR in '' \
	${DEFAULTS:+{^DEFAULTS%/}{/zsh,}/help} \
	${EPREFIX:+${EPREFIX%/}/usr/share/zsh/$ZSH_VERSION/help} \
	'/usr/share/zsh/site-contrib/help'
do	[[ -d ${HELPDIR:-/usr/share/zsh/$ZSH_VERSION/help} ]] && {
		alias run-help NUL && unalias run-help
		autoload -Uz run-help
		alias help=run-help
		[[ -n ${HELPDIR} ]] || unset HELPDIR
		break
	}
done


# Define LS_COLORS if not already done in $interactive
# (this must be done before setting the completion system colors).
# I recommend https://github.com/vaeth/termcolors-mv/
# but a fallback is used if the corresponding script is not in path.

[[ -n $LS_COLORS ]] || {
	if whence dircolors-mv NUL
	then	eval "$(SOLARIZED=$SOLARIZED dircolors-mv)"
	elif whence dircolor NUL
	then	() {
		local i
		for i in \
			${DEFAULTS:+{^DEFAULTS%/}/DIR_COLORS} \
			"${HOME}/.dircolors" \
			'/etc/DIR_COLORS'
		do	[[ -f $i ]] && eval "$(dircolors -- "${i}")" && break
		done
	}
	fi
}


# Completion System (man zshcompsys):

#zstyle ':completion:*' file-list true # if used, list-colors is ignored
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
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' path-completion false
zstyle ':completion:*' squeeze-slashes true
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
whence compinit NUL || {
	[[ -n $DEFAULTS ]] && () {
		setopt localoptions nullglob
		local -a d
		d=(${^DEFAULTS%/}{/zsh,}/completion/***/(/))
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
compdef mcd=cd
whence gpg NUL && compdef gpg.wrapper=gpg
whence sudox NUL && compdef ssudox=sudox
() {
	local i j
	for i in eix{,-diff,-update,-sync,-test-obsolete} useflags
	do	for j in ${i}.{32,64}
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
}

# Line editing during completion (man zshmodules: zsh/complist)

zmodload zsh/complist
bindkey -M menuselect '\C-M' accept-and-infer-next-history # Return
bindkey -M menuselect '\M-\C-m' accept-and-hold            # Alt-Return
bindkey -M menuselect '\C-Í' accept-and-hold               # Alt-Return
bindkey -M menuselect '\e[[[sR' accept-and-hold            # Shift-Return
bindkey -M menuselect '\e\C-m' accept-and-hold             # Esc-Return
bindkey -M menuselect '\e- ' accept-and-hold               # Esc Space
bindkey -M menuselect '\M- ' accept-and-hold               # Alt Space
bindkey -M menuselect '\C- ' accept-and-hold               # Ctrl-Space
bindkey -M menuselect '\C-+' accept-and-hold               # Ctrl-+
bindkey -M menuselect '\C-?' undo                          # Backspace
bindkey -M menuselect '\C-.' undo                          # Ctrl-.
bindkey -M menuselect '\M-.' undo                          # Alt-.
bindkey -M menuselect '\e' send-break                      # Esc
bindkey -M menuselect '\C-c' send-break                    # Ctrl-C
bindkey -M menuselect '\e[5~' backward-word                # PgUp
bindkey -M menuselect '\e[6~' forward-word                 # PgDn
bindkey -M menuselect '\C-l' history-incremental-search-forward # Ctrl-L
bindkey -M menuselect '\e[2~' vi-insert                    # insert
bindkey -M menuselect '\e[[[[sI' vi-insert                 # shift-insert


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
bindkey '\e[A' history-beginning-search-backward # up
bindkey '\e[B' history-beginning-search-forward  # down
bindkey '\e[[[cu' up-line-or-history    # Ctrl-Up
bindkey '\e[1;5A' up-line-or-history    # Ctrl-Up
bindkey '\e[[[cd' down-line-or-history  # Ctrl-Dn
bindkey '\e[1;5D' down-line-or-history  # Ctrl-Dn
bindkey '\C-aap' up-line-or-history     # Alt-Up
bindkey '\e[1;3A' up-line-or-history    # Alt-Up
bindkey '\e[[[au' up-line-or-history    # Alt-Up
bindkey '\C-aan' down-line-or-history   # Alt-Dn
bindkey '\e[1;3B' down-line-or-history  # Alt-Dn
bindkey '\e[[[ad' down-line-or-history  # Alt-Dn
bindkey '\e[[[su' up-line-or-history    # Shift-Up
bindkey '\e[1;2A' up-line-or-history    # Shift-Up
bindkey '\e[[[sd' down-line-or-history  # Shift-Dn
bindkey '\e[1;2B' down-line-or-history  # Shift-Dn
bindkey '\e[[[gu' beginning-of-history  # AltGr-Up
bindkey '\e[[[gd' end-of-history        # AltGr-Dn
bindkey '\e[5~' up-line-or-history      # PgUp
bindkey '\e[6~' down-line-or-history    # PgDn
bindkey '\e[D' backward-char            # left
bindkey '\e[C' forward-char             # right
bindkey '\e[3~' delete-char             # delete
bindkey '\e[2~' overwrite-mode          # insert
bindkey '\e[[[[sI' overwrite-mode       # shift-insert
bindkey '\e[1~' beginning-of-line       # home
bindkey '\e[H' beginning-of-line        # home in xterm without *VT100.Translate Resource
bindkey '\e[4~' end-of-line             # end
bindkey '\e[F' end-of-line              # end in xterm without *VT100.Translate Resource
bindkey '\e[5;3~' beginning-of-history  # Meta-PgUp
bindkey '\M-\e[5~' beginning-of-history # Meta-PgUp
bindkey '\e[6;3~' end-of-history        # Meta-PgDn
bindkey '\M-\e[6~' end-of-history       # Meta-PgDn
bindkey '\e[40~' beginning-of-history   # Ctrl-PgUp
bindkey '\e[5;5~' beginning-of-history  # Ctrl-PgUp
bindkey '\e[41~' end-of-history         # Ctrl-PgDn
bindkey '\e[6;5~' end-of-history        # Ctrl-PgDn
bindkey '\e[[[gb' backward-kill-line    # AltGr-Backspace
bindkey '\e[[[cb' kill-line-maybe       # Ctrl-Backspace
bindkey '\e[[[sb' kill-line-maybe       # Shift-Backspace
bindkey '\e[[[cD' kill-line-maybe       # Ctrl-Del
bindkey '\eu' undo
bindkey '\M-u' undo
bindkey '\C-f' insert-files
bindkey '\C-g' predict-off
bindkey '\C-e' predict-on
bindkey '\C-y' kill-whole-line
bindkey '\C-x' kill-whole-line
bindkey '\C-d' kill-line-maybe
bindkey '\C-v' yank
bindkey '\C-t' quoted-insert
bindkey '\e[[[cl' backward-word         # Ctrl-Left
bindkey '\eOD' backward-word            # Ctrl-Left
bindkey '\e[1;5D' backward-word         # Ctrl-Left
bindkey '\e[[[cr' forward-word          # Ctrl-Right
bindkey '\e[1;5C' forward-word          # Ctrl-Right
bindkey '\eOC' forward-word             # Ctrl-Right
bindkey '\e[[[sH' clear-screen          # Shift-Home
bindkey '\e[1;2H' forward-word          # Shift-Home
bindkey '\e[[[sR' insert-completions    # Shift-Return
bindkey '\e[[[cR' insert-completions    # Ctrl-Return
bindkey '\e[[[gR' call-last-kbd-macro   # AltGr-Return
bindkey '\C-?' backward-delete-char
bindkey '\C-H' backward-delete-char
bindkey '\e[21' describe-key-briefly    # F10
bindkey '\e[21;2~' describe-key-briefly # Shift-F10
bindkey '\e[21~' describe-key-briefly   # AltGr-F10
bindkey '\M-#' pound-insert             # Alt-#
bindkey '£' pound-insert                # Alt-#
bindkey '\M\C-m' pound-insert           # Alt-Return
bindkey '\C-Í' pound-insert             # Alt-Return
bindkey '\e\C-m' push-input             # Esc Return
bindkey '\e\C-i' all-matches            # Esc Tab
bindkey '\e*'  all-matches              # Esc *
bindkey '\e+'  all-matches              # Esc +
bindkey '\M-+' all-matches              # Alt-+
bindkey '\M-*' all-matches              # Alt-Shift-*

# Make files with certain extensions "executable" (man zshbuiltins#alias)
# Actually, we use zsh-mime-setup to this purpose.

# First store typical programs in variables (can be changed later)
# A leading - sign means that also ..._flags=needsterminal is set

Aa() {
	[[ -n ${(P)1} ]] && return
	local i j=$1 r
	shift
	r=$1
	for i
	do	whence ${i#-} NIL && r=$i && break
	done
	eval $j=\${r#-}
	[[ $r == -* ]] && eval ${j}_flags=needsterminal || unset ${j}_flags
}
Aa XFIG xfig
Aa BROWSER pick-web-browser
Aa SOUNDPLAYER -mplayer2 -mplayer
Aa MOVIEPLAYER -mplayer2 -mplayer smplayer xine-ui kaffeine vlc false
Aa EDITOR -e emacs -vim -vi
Aa DVIVIEWER xdvi kdvi okular evince
Aa PDFVIEWER zathura mupdf qpdfview apvlv okular evince acroread
Aa VIEWER {p,}qiv feh kquickshow gwenview eog xv {gimage,gq,qpic}view viewnior
Aa PSVIEWER {,g}gv
Aa OFFICE {s,libre,o}office

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
Aa EDITOR txt text {read,}me 1st now {i,}nfo diz \
	tex bib sty cls {d,l}tx ins clo fd{d,} \
	{b,i}st el mf \
	c{,c,pp,++} h{,pp,++} s{,rc} asm pas pyt for y \
	diff patch \
	py sh pl
Aa SOUNDPLAYER au mp3 ogg flac aac mpc mid{i,} cmf cms xmi voc wav mod \
	stm rol snd wrk mff smp al{g,2} nst med wow 669 s3m oct okt far mtm
Aa VIEWER gif pcx bmp {p,m}ng xcf xwd cpi tga tif{f,} img pi{1,2,3,c} \
	p{n,g,c}m {b,x}bm xpm jp{g,e,eg} iff art wpg rle
Aa MOVIEPLAYER mp{g,eg} m2v avi flv mkv ogm mp4{,v} m4v mov qt wmv asf \
	rm{,vb} flc fli gl dl swf 3gp vob
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


if [[ $#ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES -eq 0 ]] && is-at-least 4.3.9 &&
	. "$(for i in ${DEFAULTS:+${^DEFAULTS%/}/zsh{/zsh-syntax-highlighting,}} \
		/usr/share/zsh/site-contrib{/zsh-syntax-highlighting,} \
		$path
	do	j=$i/zsh-syntax-highlighting.zsh && [[ -f $j ]] && echo -nE $j && exit
	done)" NIL
then	typeset -gUa ZSH_HIGHLIGHT_HIGHLIGHTERS
	ZSH_HIGHLIGHT_HIGHLIGHTERS+=(
		main		# color syntax while typing (active by default)
#		patterns	# color according to ZSH_HIGHLIGHT_PATTERNS
		brackets	# color matching () {} [] pairs
#		cursor		# color cursor; useless with cursorColor
#		root		# color if you are root; broken in some versions
	)
	typeset -gUa ZSH_ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
	ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS+=(sudo fakeroot fakeroot-ng)
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
		ZSH_HIGHLIGHT_STYLES+=(
			'default'			fg=252
			'unknown-token'			fg=64,bold
			'reserved-word'			fg=84,bold
			'alias'				fg=118,bold
			'builtin'			fg=47,bold
			'function'			fg=76,bold
			'command'			fg=40,bold
			'precommand'			fg=40,bold
			'hashed-command'		fg=40,bold
			'path'				fg=214,bold
			'path_prefix'			fg=214,bold
			'path_approx'			none
			'globbing'			fg=190,bold
			'history-expansion'		fg=166,bold
			'single-hyphen-option'		fg=33,bold
			'double-hyphen-option'		fg=45,bold
			'back-quoted-argument'		fg=202
			'single-quoted-argument'	fg=181,bold
			'double-quoted-argument'	fg=181,bold
			'dollar-double-quoted-argument'	fg=196
			'back-double-quoted-argument'	fg=202
			'assign'			fg=159,bold
			'bracket-error'			fg=196,bold
		)
		if [[ ${SOLARIZED:-n} != [nNfF0]* ]]
		then	ZSH_HIGHLIGHT_STYLES+=(
			'default'			none
			'unknown-token'			fg=red,bold
			'reserved-word'			fg=white
			'alias'				fg=cyan,bold
			'builtin'			fg=yellow,bold
			'function'			fg=blue,bold
			'command'			fg=green
			'precommand'			fg=green
			'hashed-command'		fg=green
			'path'				fg=yellow
			'path_prefix'			fg=yellow
			'path_approx'			none
			'globbing'			fg=magenta
			'single-hyphen-option'		fg=green,bold
			'double-hyphen-option'		fg=magenta,bold
			'assign'			fg=cyan
			'bracket-error'			fg=red
		)
		fi
	else	ZSH_HIGHLIGHT_MATCHING_BRACKETS_STYLES=(
			fg=cyan
			fg=magenta
			fg=blue,bold
			fg=red
			fg=green
		)
		ZSH_HIGHLIGHT_STYLES+=(
			'default'			none
			'unknown-token'			fg=red,bold
			'reserved-word'			fg=green,bold
			'alias'				fg=green,bold
			'builtin'			fg=green,bold
			'function'			fg=green,bold
			'command'			fg=yellow,bold
			'precommand'			fg=yellow,bold
			'hashed-command'		fg=yellow,bold
			'path'				fg=white,bold
			'path_prefix'			fg=white,bold
			'path_approx'			none
			'globbing'			fg=magenta,bold
			'history-expansion'		fg=yellow,bold,bg=red
			'single-hyphen-option'		fg=cyan,bold
			'double-hyphen-option'		fg=cyan,bold
			'back-quoted-argument'		fg=yellow,bg=blue
			'single-quoted-argument'	fg=yellow
			'double-quoted-argument'	fg=yellow
			'dollar-double-quoted-argument'	fg=yellow,bg=blue
			'back-double-quoted-argument'	fg=yellow,bg=blue
			'assign'			fg=yellow,bold,bg=blue
			'bracket-error'			fg=red,bold
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

if whence auto-fu-init NUL || {
	: # Status must be 0 before sourcing auto-fu.zsh
	path=(${DEFAULTS:+${^DEFAULTS%/}/zsh{/auto-fu{.zsh,},}} \
		/usr/share/zsh/site-contrib{/auto-fu{.zsh,},}) \
		. auto-fu NIL && auto-fu-install
	} || {
	:
	path=(${DEFAULTS:+${^DEFAULTS%/}/zsh{/auto-fu{.zsh,},}} \
		/usr/share/zsh/site-contrib{/auto-fu{.zsh,},}) \
		. auto-fu.zsh NIL
	}
then	# Keep Ctrl-d behavior also when auto-fu is active
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
	zle-line-init() auto-fu-init
	zle -N zle-line-init
	zle -N zle-keymap-select auto-fu-zle-keymap-select
	zstyle ':completion:*' completer _complete

	# Starting a line with a space or tab or quoting the first word
	# or escaping a word should deactivate auto-fu for that line/word.
	# This is useful e.g. if auto-fu is too slow for you in some cases.
	# Unfortunately, for eix auto-fu is always too slow...
	zstyle ':auto-fu:var' autoable-function/skiplines '[[:blank:]\\"'\'']*|eix(|32|64)[[:blank:]]*'
	zstyle ':auto-fu:var' autoable-function/skipwords '[\\]*'
fi
