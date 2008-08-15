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

function! s:ReverseStr( expr )
    return join( reverse( split( a:expr, '\zs' ) ), '' )
endfunction
function! s:HasMoreThanVirtCol( expr, virtCol )
    return (match( a:expr, '^.*\%>' . a:virtCol . 'v' ) != -1)
endfunction
function! EchoWithoutScrolling#DetermineVirtColNum( expr )
    let i = 1
    while 1
	if ! s:HasMoreThanVirtCol( a:expr, i )
	    return i - 1
	endif
	let i += 1
    endwhile
endfunction
function! s:VirtColStrFromStart( expr, virtCol )
    " Must add 1 because a "before-column" pattern is used in case the exact
    " column cannot be matched (because its halfway through a tab or other wide
    " character). 
    return matchstr(a:expr, '^.*\%<' . (a:virtCol + 1) . 'v')
endfunction
function! s:VirtColStrFromEnd( expr, virtCol )
    " Virtual columns are always counted from the start, not the end. To specify
    " the column counting from the end, the string is reversed during the
    " matching. 
    return s:ReverseStr( s:VirtColStrFromStart( s:ReverseStr(a:expr), a:virtCol ) )
endfunction

function! EchoWithoutScrolling#GetTabReplacement( column, tabstop )
    return a:tabstop - (a:column - 1) % a:tabstop
endfunction
function! EchoWithoutScrolling#RenderTabs( text, tabstop, startColumn )
"*******************************************************************************
"* PURPOSE:
"   Replaces <Tab> characters in a:text with the correct amount of <Space>,
"   depending on the a:tabstop value. a:startColumn specifies at which start
"   column a:text will be printed. 
"* ASSUMPTIONS / PRECONDITIONS:
"   none
"* EFFECTS / POSTCONDITIONS:
"   none
"* INPUTS:
"   a:text	    Text to be rendered. 
"   a:tabstop	    tabstop value (The built-in :echo command always uses a
"		    fixed value of 8; it isn't affected by the 'tabstop'
"		    setting.)
"   a:startColumn   Column at which the text is to be rendered (typically 1). 
"* RETURN VALUES: 
"   a:text with replaced <Tab> characters. 
"*******************************************************************************
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

function! EchoWithoutScrolling#Truncate( text, ... ) 
"*******************************************************************************
"* PURPOSE:
"   Truncate a:text so that it can be echoed to the command line without causing
"   the "Hit ENTER" prompt. Truncation will only happen in (the middle of)
"   a:text. 
"* ASSUMPTIONS / PRECONDITIONS:
"   none
"* EFFECTS / POSTCONDITIONS:
"   none
"* INPUTS:
"   a:text	Text which may be truncated to fit. 
"   a:reservedColumns	Optional number of columns that are already taken in the
"			line; if specified, a:text will be truncated to
"			(MaxLength() - a:reservedColumns). 
"* RETURN VALUES: 
"   Truncated a:text. 
"*******************************************************************************
    if &shortmess !~# 'T'
	" People who have removed the 'T' flag from 'shortmess' want no
	" truncation. 
	return a:text
    endif

    let l:reservedColumns = (a:0 > 0 ? a:1 : 0)
    let l:maxLength = EchoWithoutScrolling#MaxLength() - l:reservedColumns
    if l:maxLength <= 0
	return ''
    endif

    " The \%<23v regexp item uses the local 'tabstop' value to determine the
    " virtual column. As we want to echo with default tabstop 8, we need to
    " temporarily set it up this way. 
    let l:save_ts = &l:tabstop
    setlocal tabstop=8

    let l:text = a:text
    try
	if s:HasMoreThanVirtCol(l:text, l:maxLength)
	    " We need 3 characters for the '...'; 1 must be added to both lengths
	    " because columns start at 1, not 0. 
	    let l:frontCol = l:maxLength / 2
	    let l:backCol  = (l:maxLength % 2 == 0 ? (l:frontCol - 1) : l:frontCol)
"**** echomsg '**** ' l:maxLength ':' l:frontCol '-' l:backCol
	    let l:text =  s:VirtColStrFromStart(l:text, l:frontCol) . '...' . s:VirtColStrFromEnd(l:text, l:backCol)
	endif
    finally
	let &l:tabstop = l:save_ts
    endtry
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
