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
	[[ -r $interactive ]] && . $interactive
}

# Some pipe aliases which cannot be defined for bash:

alias -g 'CAT'='|& cat -A'
alias -g 'TAIL'='|& tail -n $(( ${LINES} - 3 ))'
alias -g 'LESS'='|& less -Rs'
alias -g 'NUL'='>/dev/null'
alias -g 'NULL'='NUL'
alias -g 'NIL'='>&/dev/null'


# Force 256 colors on terminals which typically set an inappropriate TERM:

case ${TERM} in
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
		[[ "$i" == *'function' ]] || . set_prompt.sh
	}
} && {
	set_prompt -r
	. git_prompt.zsh
}


# I want zmv and other nice features (man zshcontrib)
autoload -Uz zmv zcalc zargs colors
#colors


# These are needed in the following:
autoload -Uz pick-web-browser is-at-least


# Initialize the helping system:

HELPDIR="/usr/share/zsh/site-contrib/help"
alias run-help NUL && unalias run-help
autoload -Uz run-help
alias help=run-help


# Define LS_COLORS if not already done in $interactive
# (this must be done before setting the completion system colors).
# I recommend https://github.com/vaeth/termcolors-mv/

[[ -n $LS_COLORS ]] || () {
	local -a files
	files=(
		${DEFAULTS:+"${DEFAULTS}/DIR_COLORS"}
		"${HOME}/.dir_colors"
		'/etc/DIR_COLORS'
	)
	[[ $(echotc Co) -ge 256 ]] && files=(${^files[@]}'-256' $files)
	local i
	for i in $files
	do	[[ -r $i ]] && eval "$(dircolors -- $i)" && break
	done
}


# Completion System (man zshcompsys):

#zstyle ':completion:*' file-list true # if used, list-colors is ignored
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) #([0-9a-z/-]# #[0-9:]# #)*=01;32=01;36=01;33'
zstyle ':completion:*' completer _complete _expand _expand_alias
zstyle ':completion:*' menu select=1 # interactive
zstyle ':completion:*' original true
zstyle ':completion:*' remote-access false
zstyle ':completion:*' use-perl true
zstyle ':completion:*' verbose true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' path-completion false
zstyle ':completion:*' squeeze-slashes true
if is-at-least 4.3.10
then	zstyle ':completion:*' format "%B%F{yellow}%K{blue}%d%k%f%b"
else	zstyle ':completion:*' format "%B%d%b"
fi

# Make all-matches a widget which inserts all previous matches:
zle -C all-matches complete-word _generic
zstyle ':completion:all-matches:*' old-matches only
zstyle ':completion:all-matches:*' completer _all_matches

# Restrict cd selections:
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack named-directories path-directories

# Initialize the completion system
whence compinit NUL || {
	[[ -n $DEFAULTS && -d $DEFAULTS/zsh/completion ]] && \
		fpath=("$DEFAULTS"/zsh/completion/***/(/) $fpath)
	autoload -Uz compinit
	compinit -D # -u -C
}

# mtools completion can hang, so we eliminate it:
compdef _files mattrib mcopy mdel mdu mdeltree mdir mformat mlabel mmd mmount mmove mrd mread mren mtoolstest mtype

# Some aliases or wrapper scripts behave like other commands:

compdef mcd=cd
compdef gpg.wrapper=gpg
compdef knock=ssh
compdef knock.ssh=knock
compdef knock.mosh=knock
whence sudox NUL && {
	compdef ssudox=sudox
	compdef su=sudox
}
whence eix NUL && {
	compdef eix.32=eix
	compdef eix.64=eix
	compdef eix-diff.32=eix-diff
	compdef eix-diff.64=eix-diff
	compdef eix-update.32=eix-update
	compdef eix-update.64=eix-update
	compdef eix-sync.32=eix-sync
	compdef eix-sync.64=eix-sync
	compdef eix-test-obsolete.32=eix-test-obsolete
	compdef eix-test-obsolete.64=eix-test-obsolete
}
whence emerge NUL && {
	compdef emerge.wrapper=emerge
	compdef emerge.noprotect=emerge
}
whence useflags NUL && {
	compdef useflags.32=useflags
	compdef useflags.64=useflags
}

# Line editing during completion (man zshmodules: zsh/complist)

zmodload zsh/complist
bindkey -M menuselect "\C-M" accept-and-infer-next-history # Return
bindkey -M menuselect "\M-\C-m" accept-and-hold            # Alt-Return
bindkey -M menuselect "\C-Í" accept-and-hold               # Alt-Return
bindkey -M menuselect "\e[[[sR" accept-and-hold            # Shift-Return
bindkey -M menuselect "\e\C-m" accept-and-hold             # Esc-Return
bindkey -M menuselect "\e- " accept-and-hold               # Esc Space
bindkey -M menuselect "\M- " accept-and-hold               # Alt Space
bindkey -M menuselect "\C- " accept-and-hold               # Ctrl-Space
bindkey -M menuselect "\C-+" accept-and-hold               # Ctrl-+
bindkey -M menuselect "\C-?" undo                          # Backspace
bindkey -M menuselect "\C-." undo                          # Ctrl-.
bindkey -M menuselect "\M-." undo                          # Alt-.
bindkey -M menuselect "\e" send-break                      # Esc
bindkey -M menuselect "\C-c" send-break                    # Ctrl-C
bindkey -M menuselect "\e[5~" backward-word                # PgUp
bindkey -M menuselect "\e[6~" forward-word                 # PgDn
bindkey -M menuselect "\C-l" history-incremental-search-forward # Ctrl-L
bindkey -M menuselect "\e[2~" vi-insert                    # insert
bindkey -M menuselect "\e[[[[sI" vi-insert                 # shift-insert


# Line editing (man zshzle)

autoload -Uz insert-files predict-on
zle -N insert-files
zle -N predict-on
zle -N predict-off
#predict-on 2>/dev/null
zle -N my-kill-line
my-kill-line() {
	if (($#BUFFER > CURSOR))
	then	zle kill-line
	else	zle kill-whole-line
	fi
}

bindkey -e
bindkey "\e[A" history-beginning-search-backward # up
bindkey "\e[B" history-beginning-search-forward  # down
bindkey "\e[[[cu" up-line-or-history    # Ctrl-Up
bindkey "\e[1;5A" up-line-or-history    # Ctrl-Up
bindkey "\e[[[cd" down-line-or-history  # Ctrl-Dn
bindkey "\e[1;5D" down-line-or-history  # Ctrl-Dn
bindkey "\C-aap" up-line-or-history     # Alt-Up
bindkey "\e[1;3A" up-line-or-history    # Alt-Up
bindkey "\e[[[au" up-line-or-history    # Alt-Up
bindkey "\C-aan" down-line-or-history   # Alt-Dn
bindkey "\e[1;3B" down-line-or-history  # Alt-Dn
bindkey "\e[[[ad" down-line-or-history  # Alt-Dn
bindkey "\e[[[su" up-line-or-history    # Shift-Up
bindkey "\e[1;2A" up-line-or-history    # Shift-Up
bindkey "\e[[[sd" down-line-or-history  # Shift-Dn
bindkey "\e[1;2B" down-line-or-history  # Shift-Dn
bindkey "\e[[[gu" beginning-of-history  # AltGr-Up
bindkey "\e[[[gd" end-of-history        # AltGr-Dn
bindkey "\e[5~" up-line-or-history      # PgUp
bindkey "\e[6~" down-line-or-history    # PgDn
bindkey "\e[D" backward-char            # left
bindkey "\e[C" forward-char             # right
bindkey "\e[3~" delete-char             # delete
bindkey "\e[2~" overwrite-mode          # insert
bindkey "\e[[[[sI" overwrite-mode       # shift-insert
bindkey "\e[1~" beginning-of-line       # home
bindkey "\e[H" beginning-of-line        # home in xterm without *VT100.Translate Resource
bindkey "\e[4~" end-of-line             # end
bindkey "\e[F" end-of-line              # end in xterm without *VT100.Translate Resource
bindkey "\e[5;3~" beginning-of-history  # Meta-PgUp
bindkey "\M-\e[5~" beginning-of-history # Meta-PgUp
bindkey "\e[6;3~" end-of-history        # Meta-PgDn
bindkey "\M-\e[6~" end-of-history       # Meta-PgDn
bindkey "\e[40~" beginning-of-history   # Ctrl-PgUp
bindkey "\e[5;5~" beginning-of-history  # Ctrl-PgUp
bindkey "\e[41~" end-of-history         # Ctrl-PgDn
bindkey "\e[6;5~" end-of-history        # Ctrl-PgDn
bindkey "\e[[[gb" backward-kill-line    # AltGr-Backspace
bindkey "\e[[[cb" my-kill-line          # Ctrl-Backspace
bindkey "\e[[[sb" my-kill-line          # Shift-Backspace
bindkey "\e[[[cD" my-kill-line          # Ctrl-Del
bindkey "\eu" undo
bindkey "\M-u" undo
bindkey "\C-f" insert-files
bindkey "\C-g" predict-off
bindkey "\C-e" predict-on
bindkey "\C-y" kill-whole-line
bindkey "\C-x" kill-whole-line
bindkey "\C-d" my-kill-line
bindkey "\C-v" yank
bindkey "\C-t" quoted-insert
bindkey "\e[[[cl" backward-word         # Ctrl-Left
bindkey "\eOD" backward-word            # Ctrl-Left
bindkey "\e[1;5D" backward-word         # Ctrl-Left
bindkey "\e[[[cr" forward-word          # Ctrl-Right
bindkey "\e[1;5C" forward-word          # Ctrl-Right
bindkey "\eOC" forward-word             # Ctrl-Right
bindkey "\e[[[sH" clear-screen          # Shift-Home
bindkey "\e[1;2H" forward-word          # Shift-Home
bindkey "\e[[[sR" insert-completions    # Shift-Return
bindkey "\e[[[cR" insert-completions    # Ctrl-Return
bindkey "\e[[[gR" call-last-kbd-macro   # AltGr-Return
bindkey "\C-?" backward-delete-char
bindkey "\C-H" backward-delete-char
bindkey "\e[21" describe-key-briefly    # F10
bindkey "\e[21;2~" describe-key-briefly # Shift-F10
bindkey "\e[21~" describe-key-briefly   # AltGr-F10
bindkey "\M-#" pound-insert             # Alt-#
bindkey "£" pound-insert                # Alt-#
bindkey "\M\C-m" pound-insert           # Alt-Return
bindkey "\C-Í" pound-insert             # Alt-Return
bindkey "\e\C-m" push-input             # Esc Return
bindkey "\e\C-i" all-matches            # Esc Tab
bindkey "\e*"  all-matches              # Esc *
bindkey "\e+"  all-matches              # Esc +
bindkey "\M-+" all-matches              # Alt-+
bindkey "\M-*" all-matches              # Alt-Shift-*


# Make files with certain extensions "executable" (man zshbuiltins#alias):

: ${SOUNDPLAYER:=mplayer}
: ${MOVIEPLAYER:=mplayer}
: ${EDITOR:=e}
: ${DVIVIEWER:=xdvi}
: ${XFIG:=xfig}
: ${BROWSER:=pick-web-browser}
() {
	local i
	[[ -n $PDFVIEWER ]] || for i in \
		zathura mupdf qpdfview apvlv evince okular acroread
	do	command -v $i NIL && PDFVIEWER=$i && break
	done
	[[ -n $VIEWER ]] || for i in \
		qiv eog
	do	command -v $i NIL && VIEWER=$i && break
	done
	[[ -n $PSVIEWER ]] || for i in \
		gv ggv
	do	command -v $i NIL && PSVIEWER=$i && break
	done
	[[ -n $OFFICE ]] || for i in \
		soffice libreoffice ooffice
	do	command -v $i NIL && OFFICE=$i && break
	done
}

alias -s ps='$PSVIEWER'
alias -s PS='$PSVIEWER'
alias -s eps='$PSVIEWER'
alias -s EPS='$PSVIEWER'
alias -s dvi='$DVIVIEWER'
alias -s DVI='$DVIVIEWER'
alias -s fig='$XFIG'
alias -s FIG='$XFIG'
alias -s doc='$OFFICE'
alias -s DOC='$OFFICE'

alias -s htm='$BROWSER'
alias -s html='$BROWSER'
alias -s HTM='$BROWSER'
alias -s HTML='$BROWSER'

alias -s pdf='$PDFVIEWER'
alias -s PDF='$PDFVIEWER'

alias -s txt='$EDITOR'
alias -s me='$EDITOR'
alias -s 1st='$EDITOR'
alias -s now='$EDITOR'
alias -s nfo='$EDITOR'
alias -s diz='$EDITOR'
alias -s TXT='$EDITOR'
alias -s ME='$EDITOR'
alias -s 1ST='$EDITOR'
alias -s NOW='$EDITOR'
alias -s NFO='$EDITOR'
alias -s DIZ='$EDITOR'

alias -s tex='$EDITOR'
alias -s bib='$EDITOR'
alias -s sty='$EDITOR'
alias -s cls='$EDITOR'
alias -s dtx='$EDITOR'
alias -s ltx='$EDITOR'
alias -s ins='$EDITOR'
alias -s clo='$EDITOR'
alias -s fdd='$EDITOR'
alias -s fd='$EDITOR'
alias -s TEX='$EDITOR'
alias -s BIB='$EDITOR'
alias -s STY='$EDITOR'
alias -s CLS='$EDITOR'
alias -s DTX='$EDITOR'
alias -s LTX='$EDITOR'
alias -s INS='$EDITOR'
alias -s CLO='$EDITOR'
alias -s FDD='$EDITOR'
alias -s FD='$EDITOR'

alias -s c='$EDITOR'
alias -s cc='$EDITOR'
alias -s cpp='$EDITOR'
alias -s h='$EDITOR'
alias -s hpp='$EDITOR'
alias -s s='$EDITOR'
alias -s src='$EDITOR'
alias -s asm='$EDITOR'
alias -s pas='$EDITOR'
alias -s for='$EDITOR'
alias -s y='$EDITOR'
alias -s el='$EDITOR'
alias -s bst='$EDITOR'
alias -s ist='$EDITOR'
alias -s mf='$EDITOR'
alias -s PY='$EDITOR'
alias -s PYT='$EDITOR'
alias -s C='$EDITOR'
alias -s CC='$EDITOR'
alias -s CPP='$EDITOR'
alias -s H='$EDITOR'
alias -s HPP='$EDITOR'
alias -s S='$EDITOR'
alias -s SRC='$EDITOR'
alias -s ASM='$EDITOR'
alias -s PAS='$EDITOR'
alias -s FOR='$EDITOR'
alias -s Y='$EDITOR'
alias -s EL='$EDITOR'
alias -s BST='$EDITOR'
alias -s IST='$EDITOR'
alias -s MF='$EDITOR'

alias -s au='$SOUNDPLAYER'
alias -s mp3='$SOUNDPLAYER'
alias -s ogg='$SOUNDPLAYER'
alias -s flac='$SOUNDPLAYER'
alias -s aac='$SOUNDPLAYER'
alias -s mpc='$SOUNDPLAYER'
alias -s mid='$SOUNDPLAYER'
alias -s midi='$SOUNDPLAYER'
alias -s cmf='$SOUNDPLAYER'
alias -s cms='$SOUNDPLAYER'
alias -s xmi='$SOUNDPLAYER'
alias -s voc='$SOUNDPLAYER'
alias -s wav='$SOUNDPLAYER'
alias -s mod='$SOUNDPLAYER'
alias -s stm='$SOUNDPLAYER'
alias -s rol='$SOUNDPLAYER'
alias -s snd='$SOUNDPLAYER'
alias -s wrk='$SOUNDPLAYER'
alias -s mff='$SOUNDPLAYER'
alias -s smp='$SOUNDPLAYER'
alias -s alg='$SOUNDPLAYER'
alias -s al2='$SOUNDPLAYER'
alias -s nst='$SOUNDPLAYER'
alias -s med='$SOUNDPLAYER'
alias -s wow='$SOUNDPLAYER'
alias -s 669='$SOUNDPLAYER'
alias -s s3m='$SOUNDPLAYER'
alias -s oct='$SOUNDPLAYER'
alias -s okt='$SOUNDPLAYER'
alias -s far='$SOUNDPLAYER'
alias -s mtm='$SOUNDPLAYER'
alias -s AU='$SOUNDPLAYER'
alias -s MP3='$SOUNDPLAYER'
alias -s OGG='$SOUNDPLAYER'
alias -s FLAC='$SOUNDPLAYER'
alias -s AAC='$SOUNDPLAYER'
alias -s MPC='$SOUNDPLAYER'
alias -s MID='$SOUNDPLAYER'
alias -s MIDI='$SOUNDPLAYER'
alias -s CMF='$SOUNDPLAYER'
alias -s CMS='$SOUNDPLAYER'
alias -s XMI='$SOUNDPLAYER'
alias -s VOC='$SOUNDPLAYER'
alias -s WAV='$SOUNDPLAYER'
alias -s MOD='$SOUNDPLAYER'
alias -s STM='$SOUNDPLAYER'
alias -s ROL='$SOUNDPLAYER'
alias -s SND='$SOUNDPLAYER'
alias -s WRK='$SOUNDPLAYER'
alias -s MFF='$SOUNDPLAYER'
alias -s SMP='$SOUNDPLAYER'
alias -s ALG='$SOUNDPLAYER'
alias -s AL2='$SOUNDPLAYER'
alias -s NST='$SOUNDPLAYER'
alias -s MED='$SOUNDPLAYER'
alias -s WOW='$SOUNDPLAYER'
alias -s 669='$SOUNDPLAYER'
alias -s S3M='$SOUNDPLAYER'
alias -s OCT='$SOUNDPLAYER'
alias -s OKT='$SOUNDPLAYER'
alias -s FAR='$SOUNDPLAYER'
alias -s MTM='$SOUNDPLAYER'

alias -s gif='$VIEWER'
alias -s pcx='$VIEWER'
alias -s bmp='$VIEWER'
alias -s png='$VIEWER'
alias -s mng='$VIEWER'
alias -s xcf='$VIEWER'
alias -s xwd='$VIEWER'
alias -s cpi='$VIEWER'
alias -s tga='$VIEWER'
alias -s tif='$VIEWER'
alias -s tiff='$VIEWER'
alias -s img='$VIEWER'
alias -s pi1='$VIEWER'
alias -s pi2='$VIEWER'
alias -s pi3='$VIEWER'
alias -s pic='$VIEWER'
alias -s pnm='$VIEWER'
alias -s pbm='$VIEWER'
alias -s ppm='$VIEWER'
alias -s pgm='$VIEWER'
alias -s pcm='$VIEWER'
alias -s pcc='$VIEWER'
alias -s jpg='$VIEWER'
alias -s jpe='$VIEWER'
alias -s jpeg='$VIEWER'
alias -s iff='$VIEWER'
alias -s art='$VIEWER'
alias -s wpg='$VIEWER'
alias -s rle='$VIEWER'
alias -s xbm='$VIEWER'
alias -s xpm='$VIEWER'
alias -s GIF='$VIEWER'
alias -s PCX='$VIEWER'
alias -s BMP='$VIEWER'
alias -s PNG='$VIEWER'
alias -s MNG='$VIEWER'
alias -s XCF='$VIEWER'
alias -s XWD='$VIEWER'
alias -s CPI='$VIEWER'
alias -s TGA='$VIEWER'
alias -s TIF='$VIEWER'
alias -s TIFF='$VIEWER'
alias -s IMG='$VIEWER'
alias -s PI1='$VIEWER'
alias -s PI2='$VIEWER'
alias -s PI3='$VIEWER'
alias -s PIC='$VIEWER'
alias -s PNM='$VIEWER'
alias -s PBM='$VIEWER'
alias -s PPM='$VIEWER'
alias -s PGM='$VIEWER'
alias -s PCM='$VIEWER'
alias -s PCC='$VIEWER'
alias -s JPG='$VIEWER'
alias -s JPE='$VIEWER'
alias -s JPEG='$VIEWER'
alias -s IFF='$VIEWER'
alias -s ART='$VIEWER'
alias -s WPG='$VIEWER'
alias -s RLE='$VIEWER'
alias -s XBM='$VIEWER'
alias -s XPM='$VIEWER'

alias -s mpg='$MOVIEPLAYER'
alias -s mpeg='$MOVIEPLAYER'
alias -s m2v='$MOVIEPLAYER'
alias -s avi='$MOVIEPLAYER'
alias -s flv='$MOVIEPLAYER'
alias -s mkv='$MOVIEPLAYER'
alias -s ogm='$MOVIEPLAYER'
alias -s mp4='$MOVIEPLAYER'
alias -s m4v='$MOVIEPLAYER'
alias -s mp4v='$MOVIEPLAYER'
alias -s mov='$MOVIEPLAYER'
alias -s qt='$MOVIEPLAYER'
alias -s wmv='$MOVIEPLAYER'
alias -s asf='$MOVIEPLAYER'
alias -s rm='$MOVIEPLAYER'
alias -s rmvb='$MOVIEPLAYER'
alias -s flc='$MOVIEPLAYER'
alias -s fli='$MOVIEPLAYER'
alias -s gl='$MOVIEPLAYER'
alias -s dl='$MOVIEPLAYER'
alias -s swf='$MOVIEPLAYER'
alias -s 3gp='$MOVIEPLAYER'
alias -s vob='$MOVIEPLAYER'
alias -s MPG='$MOVIEPLAYER'
alias -s MPEG='$MOVIEPLAYER'
alias -s M2V='$MOVIEPLAYER'
alias -s AVI='$MOVIEPLAYER'
alias -s FLV='$MOVIEPLAYER'
alias -s MKV='$MOVIEPLAYER'
alias -s OGM='$MOVIEPLAYER'
alias -s MP4='$MOVIEPLAYER'
alias -s M4V='$MOVIEPLAYER'
alias -s MP4V='$MOVIEPLAYER'
alias -s MOV='$MOVIEPLAYER'
alias -s QT='$MOVIEPLAYER'
alias -s WMV='$MOVIEPLAYER'
alias -s ASF='$MOVIEPLAYER'
alias -s RM='$MOVIEPLAYER'
alias -s RMVB='$MOVIEPLAYER'
alias -s FLC='$MOVIEPLAYER'
alias -s FLI='$MOVIEPLAYER'
alias -s GL='$MOVIEPLAYER'
alias -s DL='$MOVIEPLAYER'
alias -s SWF='$MOVIEPLAYER'
alias -s 3GP='$MOVIEPLAYER'
alias -s VOB='$MOVIEPLAYER'


# auto-fu part 1:
# Incremental completion, see https://github.com/hchbaw/auto-fu.zsh/
# (Only the most current versions [branch pu] work with syntax-highlighting)
#
# If auto-fu is not compiled it must be sourced before syntax-highlighting:
# Activation is done after handling of syntax-highlighting:x-highlighting

whence auto-fu-init NUL || [[ -r /usr/share/zsh/site-contrib/auto-fu/auto-fu ]] || {
	if [[ -r /usr/share/zsh/site-contrib/auto-fu/auto-fu.zsh ]]
	then	. /usr/share/zsh/site-contrib/auto-fu/auto-fu.zsh
	elif [[ -r $DEFAULTS/zsh/auto-fu.zsh ]]
	then	. $DEFAULTS/zsh/auto-fu.zsh
	fi
}


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


if [[ $#ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS -eq 0 ]] && is-at-least 4.3.9
then	if [[ -r /usr/share/zsh/site-contrib/zsh-syntax-highlighting.zsh ]]
	then	. /usr/share/zsh/site-contrib/zsh-syntax-highlighting.zsh
		false
	elif [[ -n $DEFAULTS && -r $DEFAULTS/zsh/zsh-syntax-highlighting.zsh ]]
	then	. $DEFAULTS/zsh/zsh-syntax-highlighting.zsh
		false
	fi
fi || {
	typeset -gUa ZSH_HIGHLIGHT_HIGHLIGHTERS
	ZSH_HIGHLIGHT_HIGHLIGHTERS+=(
		main		# color syntax while typing (active by default)
#		patterns	# color according to ZSH_HIGHLIGHT_PATTERNS
		brackets	# color matching () {} [] pairs
#		cursor		# color cursor; useless with cursorColor
#		root		# color if you are root; seems broken
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
			'hashed-command'		fg=40,bold
			'path'				fg=214,bold
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
			'hashed-command'		fg=yellow,bold
			'path'				fg=white,bold
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
}


# auto-fu part 2:
# If auto-fu is compiled it must be sourced after syntax-highlighting:

whence auto-fu-init NUL || [[ ! -r /usr/share/zsh/site-contrib/auto-fu ]] || {
	. /usr/share/zsh/site-contrib/auto-fu/auto-fu
	auto-fu-install
}


# auto-fu part 3:
# initialize and activate auto-fu:

! whence auto-fu-init NUL || {
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
}
