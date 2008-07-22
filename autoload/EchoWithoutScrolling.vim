" TODO: summary
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
" DEPENDENCIES:
" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	22-Jul-2008	file creation

" Avoid installing when in unsupported VIM version. 
if v:version < 700
    finish
endif

" If the line containing the matching brace is too long, echoing it will
" cause a 'Hit ENTER' prompt to appear.  This function cleans up the line
" so that doesn't happen.
" The echoed line is too long if it is wider than the width of the window,
" minus cmdline space taken up by the ruler and showcmd features.
" TODO: Consider 'cmdheight', add argument isSingleLine
function! EchoWithoutScrolling#MaxLength()
    let l:maxLength = &columns

    " Account for space used by elements in the command-line to avoid
    " 'Hit ENTER' prompts.
    " If showcmd is on, it will take up 12 columns.
    " If the ruler is enabled, but not displayed in the status line, it
    " will in its default form take 17 columns.  If the user defines
    " a custom &rulerformat, they will need to specify how wide it is.
    if has('cmdline_info')
	if &showcmd == 1
	    let l:maxLength -= 12
	else
	    let l:maxLength -= 1
	endif
	if &ruler == 1 && has('statusline') && ((&laststatus == 0) || (&laststatus == 1 && winnr('$') == 1))
	    if &rulerformat == ''
		" Default ruler is 17 chars wide. 
		let l:maxLength -= 17
	    elseif exists('g:rulerwidth')
		" User specified width of custom ruler. 
		let l:maxLength -= g:rulerwidth
	    else
		" Don't know width of custom ruler, make a conservative
		" guess. 
		let l:maxLength -= &columns / 2
	    endif
	endif
    else
	let l:maxLength -= 1
    endif
    return l:maxLength
endfunction

function! EchoWithoutScrolling#GetTabReplacement( column, tabstop )
    return a:tabstop - (a:column - 1) % a:tabstop
endfunction

" TODO: Handle tabs. In an :echo, tabstop is fixed at 8. 
function! EchoWithoutScrolling#RenderTabs( text, tabstop, startColumn )
    if a:text !~# "\t"
	return a:text
    endif

    let l:pos = 0
    let l:text = a:text
    while l:pos < strlen(l:text)
	let l:pos = stridx( l:text, "\t", l:pos )
	if l:pos == -1
	    break
	endif
	let l:text = strpart( l:text, 0, l:pos ) . repeat( ' ', EchoWithoutScrolling#GetTabReplacement( l:pos + a:startColumn, a:tabstop ) ) . strpart( l:text, l:pos + 1 )
    endwhile
    return l:text
    
endfunction

function! EchoWithoutScrolling#Truncate( text ) 
    if &shortmess !~# 'T'
	" People who have removed the 'T' flag from 'shortmess' want no
	" truncation. 
	return a:text
    endif

    let l:maxLength = EchoWithoutScrolling#MaxLength()

    let l:text = EchoWithoutScrolling#RenderTabs(a:text, 8, 1)
    if strlen(l:text) > l:maxLength
	let l:front = l:maxLength / 2 - 1
	let l:back  = (l:maxLength % 2 == 0 ? (l:front - 1) : l:front)
	return strpart(l:text, 0, l:front) . '...' . strpart(l:text, strlen(l:text) - l:back)
    endif
    return l:text
endfunction

function! EchoWithoutScrolling#Echo( text ) 
    echo EchoWithoutScrolling#Truncate( a:text )
endfunction
function! EchoWithoutScrolling#EchoWithHl( highlightGroup, text ) 
    if ! empty(a:highlightGroup)
	execute 'echohl' a:highlightGroup
    endif
    echo EchoWithoutScrolling#Truncate( a:text )
    echohl NONE
endfunction
function! EchoWithoutScrolling#EchoMsg( text ) 
    echomsg EchoWithoutScrolling#Truncate( a:text )
endfunction
function! EchoWithoutScrolling#EchoMsgWithHl( highlightGroup, text ) 
    if ! empty(a:highlightGroup)
	execute 'echohl' a:highlightGroup
    endif
    echomsg EchoWithoutScrolling#Truncate( a:text )
    echohl NONE
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
