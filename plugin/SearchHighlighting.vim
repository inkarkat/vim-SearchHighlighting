" SearchHighlighting.vim: Highlighting of searches via star, auto-highlighting.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - SearchHighlighting.vim autoload script
"   - SearchHighlighting/AutoSearch.vim autoload script
"   - ingo/avoidprompt.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/regexp.vim autoload script
"   - ingo/selection.vim autoload script
"
" Copyright: (C) 2008-2015 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.032	26-Jan-2015	Generalize the ,* mapping to support all four
"				variants of the * mapping (whole / current,
"				cword, cWORD), too.
"				Only define default ,* etc. mappings when the
"				map leader isn't set to ",", which would make it
"				conflict with the <Leader>* Auto-Search mapping.
"				Thanks to Ilya Tumaykin for raising this issue.
"   2.00.031	23-Jan-2015	FIX: Also handle error in
"				<Plug>SearchHighlightingStar.
"				Refactoring: Drop a:isWholeWordSearch from
"				SearchHighlighting#SearchHighlightingNoJump().
"				ENH: <A-8>, g<A-8> mappings star-like search for
"				[whole] cWORD (instead of cword).
"   1.50.030	07-Dec-2014	Split off Auto Search stuff into separate
"				SearchHighlighting/AutoSearch.vim.
"   1.50.029	06-Dec-2014	ENH: Allow tab page- and window-local Auto
"				Search Highlighting via new
"				:SearchAutoHighlightingTabLocal,
"				:SearchAutoHighlightingWinLocal commands.
"   1.22.028	13-Jun-2014	Add <Leader>* visual mode mapping.
"				FIX: Use <Plug>SearchHighlightingAutoSearch rhs
"				instead of duplicating the command-line.
"   1.21.027	05-May-2014	Also abort on :SearchAutoHighlighting error.
"   1.20.026	07-Aug-2013	ENH: Add ,* search that keeps the current
"				position within the current word when jumping to
"				subsequent matches.
"				Correctly emulate * behavior on whitespace-only
"				lines where there's no cword: Issue "E348: No
"				string under cursor".
"   1.11.025	07-Jun-2013	Move EchoWithoutScrolling.vim into ingo-library.
"   1.11.024	24-May-2013	Move ingointegration#GetVisualSelection() into
"				ingo-library.
"			    	Move ingosearch.vim to ingo-library.
"   1.10.023	19-Jan-2013	BUG: For {Visual}*, a [count] isn't considered.
"				The problem is that getting the visual selection
"				clobbers v:count. Instead of evaluating v:count
"				only inside
"				SearchHighlighting#SearchHighlightingNoJump(),
"				pass it into the function as an argument before
"				the selected text, so that it gets evaluated
"				before the normal mode command clears the count.
"   1.01.022	03-Dec-2012	FIX: Prevent repeated error message when
"				an invalid {what} was given to
"				:SearchAutoHighlighting.
"   1.00.021	18-Apr-2012	Rename :AutoSearch to :SearchAutoHighlighting,
"				because I couldn't remember the command name and
"				always tried completing :Search.
"				Make the {what} argument to
"				:SearchAutoHighlighting optional.
"	020	17-Feb-2012	Add :AutoSearch {what} and :NoAutoSearch
"				commands.
"				ENH: Extend Autosearch to highlight other
"				occurrences of the line, cWORD, etc.
"				Split off documentation into help file.
"	019	30-Sep-2011	Use <silent> for <Plug> mapping instead of
"				default mapping.
"	018	12-Sep-2011	Use ingointegration#GetVisualSelection() instead
"				of inline capture.
"				Visual * and # mappings with jumping behavior
"				now support [count], too, and use
"				c_CTRL-R_CTRL-R for literal insertion into
"				command line.
"	017	10-Jun-2011	Duplicate invocation of
"				SearchHighlighting#AutoSearchOff(); it's also
"				done in
"				SearchHighlighting#SearchHighlightingNoJump().
"	016	17-May-2011	Also save and restore regtype of the unnamed
"				register in mappings.
"				Also avoid clobbering the selection and
"				clipboard registers.
"	015	14-Dec-2010	BUG: :silent'ing yank command to avoid "N lines
"				yanked" followed by "More" prompt when using *
"				on multi-line visual selection.
"				Adding intermediate
"				<Plug>SearchHighlightingExtende... mappings for
"				g:SearchHighlighting_ExtendStandardCommands
"				branch to avoid errors in SearchRepeat.vim when
"				re-mapping the complex RHS of the mappings. Now,
"				the simple <Plug> mapping can be easily
"				remapped.
"	014	05-Jan-2010	Moved SearchHighlighting#GetSearchPattern() into
"				separate ingosearch.vim utility module and
"				renamed to
"				ingosearch#LiteralTextToSearchPattern().
"	013	06-Oct-2009	Do not define * and # mappings for select mode;
"				printable characters should start insert mode.
"	012	03-Jul-2009	Replaced global g:SearchHighlighting_IsSearchOn
"				flag with s:isSearchOn and
"				SearchHighlighting#SearchOn(),
"				SearchHighlighting#SearchOff() and
"				SearchHighlighting#IsSearch() functions.
"   	011 	30-May-2009	Moved functions from plugin to separate autoload
"				script.
"	010	30-May-2009	Tested with Vim 6 and disabled functionality
"				that does not work there.
"	009	15-May-2009	BF: Translating line breaks in search pattern
"				via EchoWithoutScrolling#TranslateLineBreaks()
"				to avoid echoing only the last part of the
"				search pattern when it contains line breaks.
"	008	31-Jul-2008	Added <Plug>SearchHighlightingToggleHlsearch.
"	007	22-Jul-2008	Now truncates echoed search pattern like the
"				original commands, courtesy of
"				EchoWithoutScrolling.vim.
"	006	29-Jun-2008	Replaced literal ^S, ^V with escaped versions to
"				avoid :scriptencoding command.
"				Added global function SearchHighlightingNoJump()
"				for use by other scripts.
"				BF: [count]* didn't open fold at match.
"				ENH: Added {Visual}[count]* command.
"	005	27-Jun-2008	Added <Plug> mappings, so that the non-jump
"				commands can be mapped to different keys.
"				Separated configuration of non-jump from
"				extension of standard commands.
"				Added <Plug> mapping for :nohlsearch.
"	004	09-Jun-2008	BF: Escaping of backslash got lost.
"	003	08-Jun-2008	Added original star command behavior.
"				Made jump behavior configurable.
"				New star command now also echoes search pattern.
"				Instead of simply using "very nomagic" (\V) in
"				the search pattern, (try to) do proper escaping,
"				like the star command itself.
"				Do a whole word search only if <cword> actually
"				only consists of keyword characters.
"	002	07-Jun-2008	Implemented toggling of search highlighting.
"				Implemented auto-search highlighting.
"	001	06-Jun-2008	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchHighlighting') || (v:version < 700)
    finish
endif
let g:loaded_SearchHighlighting = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration --------------------------------------------------------------

if ! exists('g:SearchHighlighting_NoJump')
    let g:SearchHighlighting_NoJump = 1
endif
if ! exists('g:SearchHighlighting_ExtendStandardCommands')
    let g:SearchHighlighting_ExtendStandardCommands = 0
endif



"- integration ----------------------------------------------------------------

" Use ingo#avoidprompt#EchoAsSingleLine() to emulate the built-in truncation of
" the search pattern (via ':set shortmess+=T').
cnoremap <SID>EchoSearchPatternForward  call ingo#avoidprompt#EchoAsSingleLine('/'.@/)
cnoremap <SID>EchoSearchPatternBackward call ingo#avoidprompt#EchoAsSingleLine('?'.@/)



"- Toggle hlsearch ------------------------------------------------------------

" If you map to this instead of defining a separate :nohlsearch mapping, the
" hlsearch state will be tracked more accurately.
nnoremap <silent> <Plug>SearchHighlightingNohlsearch :<C-u>call SearchHighlighting#SearchOff()<Bar>nohlsearch<Bar>echo ':nohlsearch'<CR>
vnoremap <silent> <Plug>SearchHighlightingNohlsearch :<C-u>call SearchHighlighting#SearchOff()<Bar>nohlsearch<CR>gv

" Toggle hlsearch. This differs from ':set invhlsearch' in that it only
" temporarily clears the highlighting; a new search or 'n' command will
" automatically re-enable highlighting.
" Since the current state of hlsearch cannot be determined 100% reliably, we
" want the toggle mapping to first always clear the highlighting (as this is the
" most common operation). Only if the mapping is invoked again at the same
" place, hlsearch will be turned on again.
nnoremap <script> <silent> <Plug>SearchHighlightingToggleHlsearch
\ :<C-u>if SearchHighlighting#ToggleHlsearch()<Bar>set hlsearch<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>
vnoremap <script> <silent> <Plug>SearchHighlightingToggleHlsearch
\ :<C-u>if SearchHighlighting#ToggleHlsearch()<Bar>set hlsearch<Bar>else<Bar>nohlsearch<Bar>endif<CR>gv



"- mappings Search Highlighting -----------------------------------------------

if g:SearchHighlighting_NoJump
    " Highlight current word as search pattern, but do not jump to next match.
    "
    " If a count is given, preserve the default behavior and jump to the
    " [count]'th occurence.
    " <cword> selects the (key)word under or after the cursor, just like the star command.
    " If highlighting is turned on, the search pattern is echoed, just like the star command does.
    nnoremap <script> <silent> <Plug>SearchHighlightingStar
    \ :<C-u>if SearchHighlighting#SearchHighlightingNoJump( '*', v:count, expand('<cword>'))<Bar>
    \if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>if ingo#err#IsSet()<Bar>echoerr ingo#err#Get()<Bar>else<Bar>nohlsearch<Bar>endif<Bar>endif<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingGStar
    \ :<C-u>if SearchHighlighting#SearchHighlightingNoJump('g*', v:count, expand('<cword>'))<Bar>
    \if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>if ingo#err#IsSet()<Bar>echoerr ingo#err#Get()<Bar>else<Bar>nohlsearch<Bar>endif<Bar>endif<CR>

    " Highlight selected text in visual mode as search pattern, but do not jump to
    " next match.
    " gV avoids automatic re-selection of the Visual area in select mode.
    vnoremap <script> <silent> <Plug>SearchHighlightingStar
    \ :<C-u>if SearchHighlighting#SearchHighlightingNoJump('gv*', v:count, ingo#selection#Get())<Bar>
    \if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>if ingo#err#IsSet()<Bar>echoerr ingo#err#Get()<Bar>else<Bar>nohlsearch<Bar>endif<Bar>endif<CR>gV

    if ! hasmapto('<Plug>SearchHighlightingStar', 'n')
	nmap * <Plug>SearchHighlightingStar
    endif
    if ! hasmapto('<Plug>SearchHighlightingGStar', 'n')
	nmap g* <Plug>SearchHighlightingGStar
    endif
    if ! hasmapto('<Plug>SearchHighlightingStar', 'x')
	xmap * <Plug>SearchHighlightingStar
    endif
endif
if g:SearchHighlighting_ExtendStandardCommands
    " Search for the [count]'th occurrence of the word nearest to the cursor.
    "
    " We need <silent>, so that the :call isn't echoed. But this also swallows
    " the echoing of the search pattern done by the star commands. Thus, we
    " explicitly echo the search pattern.
    "
    " The star command must come first so that it receives the optional [count].
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedStar   *:call SearchHighlighting#AutoSearch#Off()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedGStar g*:call SearchHighlighting#AutoSearch#Off()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedHash   #:call SearchHighlighting#AutoSearch#Off()<Bar><SID>EchoSearchPatternBackward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedGHash g#:call SearchHighlighting#AutoSearch#Off()<Bar><SID>EchoSearchPatternBackward<CR>
    nmap * <Plug>SearchHighlightingExtendedStar
    nmap g* <Plug>SearchHighlightingExtendedGStar
    nmap # <Plug>SearchHighlightingExtendedHash
    nmap g# <Plug>SearchHighlightingExtendedGHash

    " Search for selected text in visual mode.
    nnoremap <expr> <SID>(SearchForwardWithCount)  (v:count ? v:count : '') . '/'
    nnoremap <expr> <SID>(SearchBackwardWithCount) (v:count ? v:count : '') . '?'
    vnoremap <script> <silent> <Plug>SearchHighlightingExtendedStar
    \ :<C-u>call SearchHighlighting#AutoSearch#Off()<CR><SID>(SearchForwardWithCount)
    \<C-r><C-r>=ingo#regexp#FromLiteralText(ingo#selection#Get(), 0, '/')<CR><CR>:<SID>EchoSearchPatternForward<CR>gV
    vnoremap <script> <silent> <Plug>SearchHighlightingExtendedHash
    \ :<C-u>call SearchHighlighting#AutoSearch#Off()<CR><SID>(SearchBackwardWithCount)
    \<C-r><C-r>=ingo#regexp#FromLiteralText(ingo#selection#Get(), 0, '?')<CR><CR>:<SID>EchoSearchPatternBackward<CR>gV
    xmap * <Plug>SearchHighlightingExtendedStar
    xmap # <Plug>SearchHighlightingExtendedHash
endif



"- mappings star-like search for cWORD -----------------------------------------

nnoremap <script> <silent> <Plug>SearchHighlightingWORD
\ :<C-u>if SearchHighlighting#SearchHighlightingNoJump( 'W', v:count, expand('<cWORD>'))<Bar>
\if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>if ingo#err#IsSet()<Bar>echoerr ingo#err#Get()<Bar>else<Bar>nohlsearch<Bar>endif<Bar>endif<CR>
nnoremap <script> <silent> <Plug>SearchHighlightingGWORD
\ :<C-u>if SearchHighlighting#SearchHighlightingNoJump('gW', v:count, expand('<cWORD>'))<Bar>
\if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>if ingo#err#IsSet()<Bar>echoerr ingo#err#Get()<Bar>else<Bar>nohlsearch<Bar>endif<Bar>endif<CR>
if ! hasmapto('<Plug>SearchHighlightingWORD', 'n')
    nmap <A-8> <Plug>SearchHighlightingWORD
endif
if ! hasmapto('<Plug>SearchHighlightingGWORD', 'n')
    nmap g<A-8> <Plug>SearchHighlightingGWORD
endif



"- mappings Search Current Position --------------------------------------------

nnoremap <script> <silent> <Plug>SearchHighlightingCStar
\ :<C-u>execute SearchHighlighting#SearchHighlightingNoJump('c*',  v:count, expand('<cword>'))<Bar>call SearchHighlighting#OffsetPostCommand()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
nnoremap <script> <silent> <Plug>SearchHighlightingGCStar
\ :<C-u>execute SearchHighlighting#SearchHighlightingNoJump('gc*', v:count, expand('<cword>'))<Bar>call SearchHighlighting#OffsetPostCommand()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
nnoremap <script> <silent> <Plug>SearchHighlightingCWORD
\ :<C-u>execute SearchHighlighting#SearchHighlightingNoJump('cW',  v:count, expand('<cWORD>'))<Bar>call SearchHighlighting#OffsetPostCommand()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
nnoremap <script> <silent> <Plug>SearchHighlightingGCWORD
\ :<C-u>execute SearchHighlighting#SearchHighlightingNoJump('gcW', v:count, expand('<cWORD>'))<Bar>call SearchHighlighting#OffsetPostCommand()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
if ! exists('g:mapleader') || g:mapleader !=# ','
    if ! hasmapto('<Plug>SearchHighlightingCStar', 'n')
	nmap ,* <Plug>SearchHighlightingCStar
    endif
    if ! hasmapto('<Plug>SearchHighlightingGCStar', 'n')
	nmap ,g* <Plug>SearchHighlightingGCStar
    endif
    if ! hasmapto('<Plug>SearchHighlightingCWORD', 'n')
	nmap ,<A-8> <Plug>SearchHighlightingCWORD
    endif
    if ! hasmapto('<Plug>SearchHighlightingGCWORD', 'n')
	nmap ,g<A-8> <Plug>SearchHighlightingGCWORD
    endif
endif



"- mappings Auto Search Highlighting ------------------------------------------

nnoremap <silent> <Plug>SearchHighlightingAutoSearch
\ :<C-u>if SearchHighlighting#AutoSearch#Toggle(0)<Bar>
\if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
vnoremap <silent> <Plug>SearchHighlightingAutoSearch
\ :<C-u>if SearchHighlighting#AutoSearch#Toggle(1)<Bar>let @/ = ingo#regexp#EscapeLiteralText(ingo#selection#Get(), '/')<Bar>
\if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
" Note: Need to set the last search pattern to the selected text here, as this
" cannot be done inside the function.
if ! hasmapto('<Plug>SearchHighlightingAutoSearch', 'n')
    nmap <silent> <Leader>* <Plug>SearchHighlightingAutoSearch
endif
if ! hasmapto('<Plug>SearchHighlightingAutoSearch', 'x')
    xmap <silent> <Leader>* <Plug>SearchHighlightingAutoSearch
endif



"- commands Auto Search Highlighting ------------------------------------------

command! -bar -nargs=? -complete=customlist,SearchHighlighting#AutoSearch#Complete SearchAutoHighlighting
\   if SearchHighlighting#AutoSearch#Set('g', <f-args>) |
\       call SearchHighlighting#AutoSearch#On() |
\       if &hlsearch | set hlsearch | endif |
\   else | echoerr ingo#err#Get() |
\   endif
command! -bar -nargs=? -complete=customlist,SearchHighlighting#AutoSearch#Complete SearchAutoHighlightingWinLocal
\   if SearchHighlighting#AutoSearch#Set('w', <f-args>) |
\       call SearchHighlighting#AutoSearch#On() |
\       if &hlsearch | set hlsearch | endif |
\   else | echoerr ingo#err#Get() |
\   endif
command! -bar -nargs=? -complete=customlist,SearchHighlighting#AutoSearch#Complete SearchAutoHighlightingTabLocal
\   if SearchHighlighting#AutoSearch#Set('t', <f-args>) |
\       call SearchHighlighting#AutoSearch#On() |
\       if &hlsearch | set hlsearch | endif |
\   else | echoerr ingo#err#Get() |
\   endif

command! -bar -bang NoSearchAutoHighlighting
\   call SearchHighlighting#AutoSearch#Off('g', <bang>0)
command! -bar -bang NoSearchAutoHighlightingWinLocal
\   call SearchHighlighting#AutoSearch#Off('w', <bang>0)
command! -bar -bang NoSearchAutoHighlightingTabLocal
\   call SearchHighlighting#AutoSearch#Off('t', <bang>0)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
