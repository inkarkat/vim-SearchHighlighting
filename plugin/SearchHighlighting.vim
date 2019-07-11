" SearchHighlighting.vim: Highlighting of searches via star, auto-highlighting.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2008-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

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
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedStar   *:call SearchHighlighting#AutoSearch#Off()<Bar>call SearchHighlighting#LastSearchPatternChanged()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedGStar g*:call SearchHighlighting#AutoSearch#Off()<Bar>call SearchHighlighting#LastSearchPatternChanged()<Bar><SID>EchoSearchPatternForward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedHash   #:call SearchHighlighting#AutoSearch#Off()<Bar>call SearchHighlighting#LastSearchPatternChanged()<Bar><SID>EchoSearchPatternBackward<CR>
    nnoremap <script> <silent> <Plug>SearchHighlightingExtendedGHash g#:call SearchHighlighting#AutoSearch#Off()<Bar>call SearchHighlighting#LastSearchPatternChanged()<Bar><SID>EchoSearchPatternBackward<CR>
    nmap * <Plug>SearchHighlightingExtendedStar
    nmap g* <Plug>SearchHighlightingExtendedGStar
    nmap # <Plug>SearchHighlightingExtendedHash
    nmap g# <Plug>SearchHighlightingExtendedGHash

    " Search for selected text in visual mode.
    nnoremap <expr> <SID>(SearchForwardWithCount)  (v:count ? v:count : '') . '/'
    nnoremap <expr> <SID>(SearchBackwardWithCount) (v:count ? v:count : '') . '?'
    vnoremap <script> <silent> <Plug>SearchHighlightingExtendedStar
    \ :<C-u>call SearchHighlighting#AutoSearch#Off()<Bar>call SearchHighlighting#LastSearchPatternChanged()<CR><SID>(SearchForwardWithCount)
    \<C-r><C-r>=ingo#regexp#FromLiteralText(ingo#selection#Get(), 0, '/')<CR><CR>:<SID>EchoSearchPatternForward<CR>gV
    vnoremap <script> <silent> <Plug>SearchHighlightingExtendedHash
    \ :<C-u>call SearchHighlighting#AutoSearch#Off()<Bar>call SearchHighlighting#LastSearchPatternChanged()<CR><SID>(SearchBackwardWithCount)
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



"- mappings Repeat Current Position --------------------------------------------

nnoremap <script> <silent> <Plug>(SearchHighlightingCNext)
\ :<C-u>execute SearchHighlighting#RepeatWithCurrentPosition(0, v:count)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
nnoremap <script> <silent> <Plug>(SearchHighlightingCPrev)
\ :<C-u>execute SearchHighlighting#RepeatWithCurrentPosition(1, v:count)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
if ! hasmapto('<Plug>(SearchHighlightingCNext)', 'n')
    nmap ,n <Plug>(SearchHighlightingCNext)
endif
if ! hasmapto('<Plug>(SearchHighlightingCPrev)', 'n')
    nmap ,N <Plug>(SearchHighlightingCPrev)
endif



"- mappings Auto Search Highlighting ------------------------------------------

nnoremap <silent> <Plug>SearchHighlightingAutoSearch
\ :<C-u>if SearchHighlighting#AutoSearch#Toggle(0)<Bar>call SearchHighlighting#LastSearchPatternChanged()<Bar>
\if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>nohlsearch<Bar>endif<CR>
vnoremap <silent> <Plug>SearchHighlightingAutoSearch
\ :<C-u>if SearchHighlighting#AutoSearch#Toggle(1)<Bar>call SearchHighlighting#LastSearchPatternChanged()<Bar>let @/ = ingo#regexp#EscapeLiteralText(ingo#selection#Get(), '/')<Bar>
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
\       call SearchHighlighting#LastSearchPatternChanged() |
\       if &hlsearch | set hlsearch | endif |
\   else | echoerr ingo#err#Get() |
\   endif
command! -bar -nargs=? -complete=customlist,SearchHighlighting#AutoSearch#Complete SearchAutoHighlightingWinLocal
\   if SearchHighlighting#AutoSearch#Set('w', <f-args>) |
\       call SearchHighlighting#AutoSearch#On() |
\       call SearchHighlighting#LastSearchPatternChanged() |
\       if &hlsearch | set hlsearch | endif |
\   else | echoerr ingo#err#Get() |
\   endif
command! -bar -nargs=? -complete=customlist,SearchHighlighting#AutoSearch#Complete SearchAutoHighlightingTabLocal
\   if SearchHighlighting#AutoSearch#Set('t', <f-args>) |
\       call SearchHighlighting#AutoSearch#On() |
\       call SearchHighlighting#LastSearchPatternChanged() |
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
