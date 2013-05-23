" SearchHighlighting.vim: Highlighting of searches via star, auto-highlighting.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingointegration.vim autoload script
"   - ingosearch.vim autoload script
"   - SearchHighlighting.vim autoload script
"   - EchoWithoutScrolling.vim (optional)
"
" Copyright: (C) 2008-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
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

"- configuration --------------------------------------------------------------

if ! exists('g:SearchHighlighting_NoJump')
    let g:SearchHighlighting_NoJump = 1
endif
if ! exists('g:SearchHighlighting_ExtendStandardCommands')
    let g:SearchHighlighting_ExtendStandardCommands = 0
endif



"- integration ----------------------------------------------------------------

" Use EchoWithoutScrolling#Echo to emulate the built-in truncation of the search
" pattern (via ':set shortmess+=T').
silent! call EchoWithoutScrolling#MaxLength()	" Execute a function to force autoload.
if exists('*EchoWithoutScrolling#Echo')
    cnoremap <SID>EchoSearchPatternForward  call EchoWithoutScrolling#Echo(EchoWithoutScrolling#TranslateLineBreaks('/'.@/))
    cnoremap <SID>EchoSearchPatternBackward call EchoWithoutScrolling#Echo(EchoWithoutScrolling#TranslateLineBreaks('?'.@/))
else " fallback
    cnoremap <SID>EchoSearchPatternForward  echo '/'.@/
    cnoremap <SID>EchoSearchPatternBackward echo '?'.@/
endif



"- Toggle hlsearch ------------------------------------------------------------

" If you map to this instead of defining a separate :nohlsearch mapping, the
" hlsearch state will be tracked more accurately.
nnoremap <silent> <Plug>SearchHighlightingNohlsearch :<C-U>call SearchHighlighting#SearchOff()<Bar>nohlsearch<Bar>echo ':nohlsearch'<CR>
vnoremap <silent> <Plug>SearchHighlightingNohlsearch :<C-U>call SearchHighlighting#SearchOff()<Bar>nohlsearch<CR>gv

" Toggle hlsearch. This differs from ':set invhlsearch' in that it only
" temporarily clears the highlighting; a new search or 'n' command will
" automatically re-enable highlighting.
" Since the current state of hlsearch cannot be determined 100% reliably, we
" want the toggle mapping to first always clear the highlighting (as this is the
" most common operation). Only if the mapping is invoked again at the same
" place, hlsearch will be turned on again.
nnoremap <script> <silent> <Plug>SearchHighlightingToggleHlsearch :<C-U>if SearchHighlighting#ToggleHlsearch()<Bar>set hlsearch<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>
vnoremap <script> <silent> <Plug>SearchHighlightingToggleHlsearch :<C-U>if SearchHighlighting#ToggleHlsearch()<Bar>set hlsearch<Bar>else<Bar>nohlsearch<Bar>endif<CR>gv



"- mappings Search Highlighting -----------------------------------------------

if g:SearchHighlighting_NoJump
    " Highlight current word as search pattern, but do not jump to next match.
    "
    " If a count is given, preserve the default behavior and jump to the
    " [count]'th occurence.
    " <cword> selects the (key)word under or after the cursor, just like the star command.
    " If highlighting is turned on, the search pattern is echoed, just like the star command does.
    nnoremap <script> <silent> <Plug>SearchHighlightingStar  :<C-U>if SearchHighlighting#SearchHighlightingNoJump( '*', v:count, expand('<cword>'), 1)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingGStar :<C-U>if SearchHighlighting#SearchHighlightingNoJump('g*', v:count, expand('<cword>'), 0)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>

    " Highlight selected text in visual mode as search pattern, but do not jump to
    " next match.
    " gV avoids automatic re-selection of the Visual area in select mode.
    vnoremap <script> <silent> <Plug>SearchHighlightingStar :<C-U>if SearchHighlighting#SearchHighlightingNoJump('gv*', v:count, ingointegration#GetVisualSelection(), 0)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>gV

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
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedStar   *:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedGStar g*:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedHash   #:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternBackward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedGHash g#:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternBackward<CR>
    nmap * <Plug>SearchHighlightingExtendedStar
    nmap g* <Plug>SearchHighlightingExtendedGStar
    nmap # <Plug>SearchHighlightingExtendedHash
    nmap g# <Plug>SearchHighlightingExtendedGHash

    " Search for selected text in visual mode.
    nnoremap <expr> <SID>(SearchForwardWithCount)  (v:count ? v:count : '') . '/'
    nnoremap <expr> <SID>(SearchBackwardWithCount) (v:count ? v:count : '') . '?'
    vnoremap <script> <silent> <Plug>SearchHighlightingExtendedStar :<C-U>call SearchHighlighting#AutoSearchOff()<CR><SID>(SearchForwardWithCount)<C-R><C-R>=ingosearch#LiteralTextToSearchPattern(ingointegration#GetVisualSelection(), 0, '/')<CR><CR>:<SID>EchoSearchPatternForward<CR>gV
    vnoremap <script> <silent> <Plug>SearchHighlightingExtendedHash :<C-U>call SearchHighlighting#AutoSearchOff()<CR><SID>(SearchBackwardWithCount)<C-R><C-R>=ingosearch#LiteralTextToSearchPattern(ingointegration#GetVisualSelection(), 0, '?')<CR><CR>:<SID>EchoSearchPatternBackward<CR>gV
    xmap * <Plug>SearchHighlightingExtendedStar
    xmap # <Plug>SearchHighlightingExtendedHash
endif



"- mappings Auto Search Highlighting ------------------------------------------

nnoremap <silent> <Plug>SearchHighlightingAutoSearch :if SearchHighlighting#ToggleAutoSearch()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
if ! hasmapto('<Plug>SearchHighlightingAutoSearch', 'n')
    nmap <silent> <Leader>* :if SearchHighlighting#ToggleAutoSearch()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
endif

"- commands Auto Search Highlighting ------------------------------------------

command! -bar -nargs=? -complete=customlist,SearchHighlighting#AutoSearchComplete SearchAutoHighlighting if SearchHighlighting#SetAutoSearch(<f-args>) | call SearchHighlighting#AutoSearchOn() | if &hlsearch | set hlsearch | endif | endif
command! -bar NoSearchAutoHighlighting call SearchHighlighting#AutoSearchOff() | nohlsearch

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
