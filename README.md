SEARCH HIGHLIGHTING   
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

This plugin changes the star command \*, so that it doesn't jump to the next
match. (Unless you supply a [count], so 1\* now restores the old \* behavior.)
If you issue a star command on the same text as before, the search
highlighting is turned off (via :nohlsearch); the search pattern remains
set, so a n / N command will turn highlighting on again. With this, you
can easily toggle highlighting for the current word / visual selection.

With the disabling of the jump to the next match, there is no difference
between \* and # any more, so the # key can now be used for some other mapping.

This plugin also extends the star command to visual mode, where instead of
the current word, the selected text is used as the literal search pattern.

The auto-search functionality instantly highlights the word under the cursor
when typing or moving around. This can be helpful while browsing source code;
whenever you position the cursor on an identifier, all other occurrences are
instantly highlighted. This functionality is toggled on/off via <Leader>\*. You
can also :nohlsearch to temporarily disable the highlighting.

### SEE ALSO

- mark.vim ([vimscript #2666](http://www.vim.org/scripts/script.php?script_id=2666)) can highlight several patterns in different
  colors simultaneously.
- SearchAlternatives.vim ([vimscript #4146](http://www.vim.org/scripts/script.php?script_id=4146)) can add and subtract search
  alternatives via mappings and commands.
- To also show the number of matches when selecting a word (\*, g\* etc.),
  you can append the corresponding command to the <Plug> mapping (see
  SearchHighlighting-remap):
 <!-- -->

    nmap <silent> * <Plug>SearchHighlightingStar:%s///gn<CR>

  The SearchPosition.vim plugin ([vimscript #2634](http://www.vim.org/scripts/script.php?script_id=2634)) provides an extended
  version of that command.

### RELATED WORKS

I came up with this on my own; however, the idea can be traced back to
francoissteinmetz and da.thompson in the comments of vimtip #1 (now at
http://vim.wikia.com/wiki/VimTip1):

    map <silent> <F10> :set invhls<CR>:let @/="<C-r><C-w>"<CR>

- highlight_word_under_cursor.vim ([vimscript #4287](http://www.vim.org/scripts/script.php?script_id=4287)) implements the search
  auto-highlighting of the whole and optionally current word.
- HiCursorWords ([vimscript #4306](http://www.vim.org/scripts/script.php?script_id=4306)) highlights the word under the cursor, with
  optional delay and limited to certain syntax groups.
- Matchmaker (https://github.com/qstrahl/vim-matchmaker) highlights the word
  under the cursor with matchadd(), not the current search pattern.
- star search ([vimscript #4335](http://www.vim.org/scripts/script.php?script_id=4335)) changes the behavior of \* to not jump to the
  next match, and includes the visual search from the next plugin
- https://github.com/bronson/vim-visual-star-search provides searching of the
  visual selection
- visualstar.vim ([vimscript #2944](http://www.vim.org/scripts/script.php?script_id=2944)) provides searching of the visual selection
- select & search ([vimscript #4819](http://www.vim.org/scripts/script.php?script_id=4819)) can use either n/N or \* in the visual
  selection, and (like this plugin) can avoid jumping.
- vim-cursorword ([vimscript #5100](http://www.vim.org/scripts/script.php?script_id=5100)) automatically underlines the current word
  in the current window (like :SearchAutoHighlighting), but uses :match
  instead of search
- vim-asterisk ([vimscript #5059](http://www.vim.org/scripts/script.php?script_id=5059)) is quite similar, providing a z\* mapping that
  also doesn't jump, visual \*, more intuitive smartcase handling, and can keep
  the cursor position when jumping (like ,\*)
- searchant.vim ([vimscript #5404](http://www.vim.org/scripts/script.php?script_id=5404)) hooks into the built-in search commands and
  provides a separate highlighting for the match last jumped to.

USAGE
------------------------------------------------------------------------------

    *                       Toggle search highlighting for the current whole
                            \<word\> on/off.
    g*                      Toggle search highlighting for the current word
                            on/off.

    {Visual}*               Toggle search highlighting for the selection on/off.
                            For a blockwise-visual selection, not just lines
                            that match the block's lines on their own are matched,
                            but all occurrences that contain the block's text,
                            though not just with the same vertical alignment (that
                            isn't possible to assert with Vim's regular
                            expressions), and only the first line's match is
                            highlighted. For example, a match on
                                foo
                                bar
                            will also match all three occurrences in
                                foo    my foo is        tell foo
                                bar    inside bar               bar
                            but not a single
                                foo

    [count]*                Search forward for the [count]'th occurrence of the
    [count]g*               word nearest to the cursor.
    {Visual}[count]*

    <A-8>                   Toggle search highlighting for the current whole
                            \<WORD\> on/off. With [count]: Search forward for the
                            [count]'th occurrence.
    g<A-8>                  Toggle search highlighting for the current WORD
                            on/off. With [count]: Search forward for the
                            [count]'th occurrence.

    [count],*               Search forward for the [count]'th occurrence of the
                            word under the cursor, keeping the cursor at the
                            current position within the word's matches (via
                            search-offset).
                            Observes the new non-jumping behavior of the star
                            commands without a [count].
    [count],g*              Like above: variants of the searches that keep the
    ,<A-8>                  cursor at the current relative match position.
    ,g<A-8>                 Note that if you have set mapleader to ",", some of
                            these would conflict with other plugin mappings; you
                            have to define|SearchHighlighting-configuration|
                            yourself.

    <Leader>*               Toggle auto-search highlighting (using the last
                            {what}; default is "wword").
    {Visual}<Leader>*       Toggle auto-search highlighting; when turning on, a
                            {what} value of "selection" is used (but the preset
                            isn't changed; the original value is used for a later
                            non-visual mode auto-search).

    :SearchAutoHighlighting [{what}]
                            Turn on automatic highlighting of occurrences of
                            {what} in normal mode, and the selected text in visual
                            / select mode. Possible values:
                            wword: whole cword, like star; this is the default
                            wWORD: whole cWORD, delimited by whitespace
                            cword: current word under cursor
                            cWORD: current WORD under cursor
                            line:  current text in line, excluding indent and
                                   trailing whitespace
                            exactline: exact current line
                            selection: only highlight selected text, in normal
                                       mode, nothing is selected
                            *-iw:      allow for variations in whitespace (also
                                       newline characters, i.e. allow a match
                                       distributed over multiple lines), and
                                       ignore any comment prefixes (e.g. /*, #),
                                       too.
                            *-nw:      allow for variations in whitespace and also
                                       direct concatenation of lines (i.e. without
                                       any whitespace in between)

    :NoSearchAutoHighlighting[!]
                            Turn off automatic highlighting. With [!], also turn
                            off all tab page- and window-local ones.

    :SearchAutoHighlightingWinLocal [{what}]
    :SearchAutoHighlightingTabLocal [{what}]
                            Like :SearchAutoHighlighting, but limit the effect
                            to the current window / tab page. Different {what}
                            occurrences can be configured for each instance.

    :NoSearchAutoHighlightingWinLocal[!]
    :NoSearchAutoHighlightingTabLocal[!]
                            Like :NoSearchAutoHighlighting, but only for the
                            current window / tab page. With [!], it explicitly
                            turns off Auto Search (even if a higher scope still
                            has it active), without it, it will still consider the
                            higher scopes.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-SearchHighlighting
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim SearchHighlighting*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.030 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

If you want to use different mappings, map your keys to the
 Plug>SearchHighlighting... mapping targets _before_ sourcing the script (e.g.
in your vimrc):

    nmap <Leader>&   <Plug>SearchHighlightingWORD
    nmap <Leader>&&  <Plug>SearchHighlightingGWORD
    nmap <Leader>*.  <Plug>SearchHighlightingCStar
    nmap <Leader>**. <Plug>SearchHighlightingCGStar
    nmap <Leader>&.  <Plug>SearchHighlightingCWORD
    nmap <Leader>&&. <Plug>SearchHighlightingCGWORD
    nmap <Leader>**  <Plug>SearchHighlightingAutoSearch

If you do not want the new non-jumping behavior of the star commands at all:

    let g:SearchHighlighting_NoJump = 0
    let g:SearchHighlighting_ExtendStandardCommands = 1

If you want the new non-jumping behavior, but map it to different keys:

    let g:SearchHighlighting_ExtendStandardCommands = 1
    nmap <Leader>*  <Plug>SearchHighlightingStar
    nmap <Leader>g* <Plug>SearchHighlightingGStar
    vmap <Leader>*  <Plug>SearchHighlightingStar

If you want a mapping to turn off hlsearch, use this:

    nmap <A-/> <Plug>SearchHighlightingNohlsearch
    vmap <A-/> <Plug>SearchHighlightingNohlsearch

To toggle hlsearch (temporarily, so that a new search or n command will
automatically re-enable it), use:

    nmap <F12> <Plug>SearchHighlightingToggleHlsearch
    vmap <F12> <Plug>SearchHighlightingToggleHlsearch

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-SearchHighlighting/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 2.01    RELEASEME
- ENH: Add ...-iw / ...-nw variants of exactline, line, selection that match
  ignoring whitespace differences / and no whitespace.
  __You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.030!__

##### 2.00    27-Jan-2017
- ENH: Allow tab page- and window-local Auto Search Highlighting via new
  :SearchAutoHighlightingTabLocal, :SearchAutoHighlightingWinLocal commands.
- ENH: Support v:hlsearch (available since Vim 7.4.079) via an alternative set
  of functions that don't use the s:isSearchOn internal flag.
- BUG: Handle "No string under cursor" for ,\* mapping correctly by returing
  the :echoerr call, not 0.
- BUG: Off-by-one in ,\* on second-to-last character.
- ENH: <A-8>, g<A-8> mappings star-like search for [whole] cWORD (instead of
  cword).
- Generalize the ,\* mapping to support all four variants of the \* mapping
  (whole / current, cword, cWORD), too.
- Only define default ,\* etc. mappings when the map leader isn't set to ",",
  which would make it conflict with the <Leader>\* Auto-Search mapping. Thanks
  to Ilya Tumaykin for raising this issue.
- Don't show strange whitespace matches on ":SearchAutoHighlighting wWORD"
  caused by empty \%(^\|\s\)\zs\ze\%(\s\|$\) pattern. Set completely empty
  pattern then.
- Re-enable search highlighting when switching to a window that has Auto
  Search. Clear search highlighting when switching from a window that has Auto
  Search to one that hasn't, and search highlighting was previously turned
  off.
- Save and restore the Auto Search pattern from a selection source when
  updating.
  __You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.023!__

##### 1.22    19-Jun-2014
- Add <Leader>\* visual mode mapping that turns on auto-search only for
  selected text (without affecting the original {what} default).
- Add "selection" value for {what} in :SearchHighlightingAutoSearch that only
  highlights selected text.

##### 1.21    23-May-2014
- Also abort on :SearchAutoHighlighting error.
- Remove duplicate /.\*.\*/ in pattern for visual blockwise search.

##### 1.20    29-Nov-2013
- ENH: Add ,\* search that keeps the current position within the current word
  when jumping to subsequent matches.
- Correctly emulate \* behavior on whitespace-only lines where there's no
  cword: Issue "E348: No string under cursor".
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)). __You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.015 (or higher)!__

##### 1.10    19-Jan-2013 (unreleased)
- For a blockwise visual selection, don't just match the block's lines on
  their own, but also when contained in other text.
- BUG: For {Visual}\*, a [count] isn't considered.

##### 1.02    17-Jan-2013
- Do not trigger modeline processing when enabling auto-search highlighting.

##### 1.01    03-Dec-2012
- FIX: Prevent repeated error message when an invalid {what} was given to
:SearchAutoHighlighting.

##### 1.00    23-Nov-2012
- First published version.

##### 0.01    06-Jun-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2008-2017 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat <ingo@karkat.de>
