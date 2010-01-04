" SearchHighlighting.vim: Highlighting of searches via star, auto-search. 
"
" DESCRIPTION:
" Changes the "star" command '*', so that it doesn't jump to the next match. 
" (Unless you supply a [count], so '1*' now restores the old '*' behavior.)
" If you issue a star command on the same text as before, the search
" highlighting is turned off (via :nohlsearch); the search pattern remains set,
" so a 'n' / 'N' command will turn highlighting on again. With this, you can
" easily toggle highlighting for the current word / visual selection. 
"
" With the disabling of the jump to the next match, there is no difference
" between * and # any more, so the # key can now be used for some other mapping. 
"
" The auto-search functionality instantly highlights the word under the cursor
" when typing or moving around. This can be helpful while browsing source code;
" whenever you position the cursor on an identifier, all other occurrences are
" instantly highlighted. This functionality is toggled on/off via <Leader>*. You
" can also :nohlsearch to temporarily disable the highlighting. 
"
" USAGE:
"   *		Toggle search highlighting for the current whole \<word\> on/off. 
"   g*	    	Toggle search highlighting for the current word on/off. 
"   {Visual}*  	Toggle search highlighting for the selection on/off. 
"
"   [count]*,	Search forward for the [count]'th occurrence of the word nearest
"   [count]g*	to the cursor.
"   {Visual}[count]*
"
"   <Leader>*   Toggle auto-search highlighting. 
"
" INSTALLATION:
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - ingosearch.vim autoload script. 
"   - SearchHighlighting.vim autoload script. 
"   - EchoWithoutScrolling.vim (optional). 
"
" CONFIGURATION:
"   If you do not want the new non-jumping behavior of the star commands at all: 
"	let g:SearchHighlighting_NoJump = 0
"	let g:SearchHighlighting_ExtendStandardCommands = 1
"
"   If you want the new non-jumping behavior, but map it to different keys:
"	let g:SearchHighlighting_ExtendStandardCommands = 1
"	nmap <silent> <Leader>*  <Plug>SearchHighlightingStar
"	nmap <silent> <Leader>g* <Plug>SearchHighlightingGStar
"	vmap <silent> <Leader>*  <Plug>SearchHighlightingStar
"
"   If you want a mapping to turn off hlsearch, use this:
"	nmap <silent> <A-/> <Plug>SearchHighlightingNohlsearch
"	vmap <silent> <A-/> <Plug>SearchHighlightingNohlsearch
"
"   To toggle hlsearch (temporarily, so that a new search or 'n' command will
"   automatically re-enable it), use: 
"	nmap <silent> <F12> <Plug>SearchHighlightingToggleHlsearch
"	vmap <silent> <F12> <Plug>SearchHighlightingToggleHlsearch
"
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" History:
"   I came up with this on my own; however, the idea can be traced back to
"   francoissteinmetz@yahoo.fr and da.thompson@yahoo.com in vimtip #1:
"   map <silent> <F10> :set invhls<CR>:let @/="<C-r><C-w>"<CR>
"
" REVISION	DATE		REMARKS 
"	014	05-Jan-2010	Moved SearchHighlighting#GetSearchPattern() into
"				separate ingosearch.vim utility module. 
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
nnoremap <Plug>SearchHighlightingNohlsearch :<C-U>call SearchHighlighting#SearchOff()<Bar>nohlsearch<Bar>echo ':nohlsearch'<CR>
vnoremap <Plug>SearchHighlightingNohlsearch :<C-U>call SearchHighlighting#SearchOff()<Bar>nohlsearch<CR>gv

" Toggle hlsearch. This differs from ':set invhlsearch' in that it only
" temporarily clears the highlighting; a new search or 'n' command will
" automatically re-enable highlighting. 
" Since the current state of hlsearch cannot be determined 100% reliably, we
" want the toggle mapping to first always clear the highlighting (as this is the
" most common operation). Only if the mapping is invoked again at the same
" place, hlsearch will be turned on again. 
nnoremap <script> <Plug>SearchHighlightingToggleHlsearch :<C-U>if SearchHighlighting#ToggleHlsearch()<Bar>set hlsearch<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>
vnoremap <script> <Plug>SearchHighlightingToggleHlsearch :<C-U>if SearchHighlighting#ToggleHlsearch()<Bar>set hlsearch<Bar>else<Bar>nohlsearch<Bar>endif<CR>gv



"- mappings Search Highlighting -----------------------------------------------
if g:SearchHighlighting_NoJump
    " Highlight current word as search pattern, but do not jump to next match. 
    "
    " If a count is given, preserve the default behavior and jump to the
    " [count]'th occurence. 
    " <cword> selects the (key)word under or after the cursor, just like the star command. 
    " If highlighting is turned on, the search pattern is echoed, just like the star command does. 
    nnoremap <script> <Plug>SearchHighlightingStar  :<C-U>call SearchHighlighting#AutoSearchOff()<Bar>if SearchHighlighting#SearchHighlightingNoJump( '*',expand('<cword>'),1)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>
    nnoremap <script> <Plug>SearchHighlightingGStar :<C-U>call SearchHighlighting#AutoSearchOff()<Bar>if SearchHighlighting#SearchHighlightingNoJump('g*',expand('<cword>'),0)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<CR>

    " Highlight selected text in visual mode as search pattern, but do not jump to
    " next match. 
    " gV avoids automatic re-selection of the Visual area in select mode. 
    vnoremap <script> <Plug>SearchHighlightingStar :<C-U>call SearchHighlighting#AutoSearchOff()<Bar>let save_unnamedregister=@@<Bar>execute 'normal! gvy'<Bar>if SearchHighlighting#SearchHighlightingNoJump('gv*',@@,0)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar><SID>EchoSearchPatternForward<Bar>else<Bar>nohlsearch<Bar>endif<Bar>:let @@=save_unnamedregister<Bar>unlet save_unnamedregister<CR>gV

    if ! hasmapto('<Plug>SearchHighlightingStar', 'n')
	nmap <silent> * <Plug>SearchHighlightingStar
    endif
    if ! hasmapto('<Plug>SearchHighlightingGStar', 'n')
	nmap <silent> g* <Plug>SearchHighlightingGStar
    endif
    if ! hasmapto('<Plug>SearchHighlightingStar', 'x')
	xmap <silent> * <Plug>SearchHighlightingStar
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
    nnoremap <script> <silent>  *  *:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> g* g*:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent>  #  #:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternBackward<CR>
    nnoremap <script> <silent> g# g#:call SearchHighlighting#AutoSearchOff()<Bar><SID>EchoSearchPatternBackward<CR>

    " Search for selected text in visual mode. 
    xnoremap <script> <silent> * :<C-U>call SearchHighlighting#AutoSearchOff()<Bar>let save_unnamedregister=@@<CR>gvy/<C-R>=ingosearch#GetSearchPattern(@@,0,'/')<CR><CR>:let @@=save_unnamedregister<Bar>unlet save_unnamedregister<Bar><SID>EchoSearchPatternForward<CR>gV
    xnoremap <script> <silent> # :<C-U>call SearchHighlighting#AutoSearchOff()<Bar>let save_unnamedregister=@@<CR>gvy?<C-R>=ingosearch#GetSearchPattern(@@,0,'?')<CR><CR>:let @@=save_unnamedregister<Bar>unlet save_unnamedregister<Bar><SID>EchoSearchPatternBackward<CR>gV
endif



"- mappings Autosearch --------------------------------------------------------
nnoremap <Plug>SearchHighlightingAutoSearch :if SearchHighlighting#ToggleAutoSearch()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
if ! hasmapto('<Plug>SearchHighlightingAutoSearch', 'n')
    nmap <silent> <Leader>* :if SearchHighlighting#ToggleAutoSearch()<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
