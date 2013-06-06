" EchoWithoutScrolling.vim: :echo overloads that truncate to avoid the hit-enter
" prompt.
"
" DESCRIPTION:
"   When using the :echo or :echomsg commands with a long text, Vim will show a
"   'Hit ENTER' prompt (|hit-enter|), so that the user has a chance to actually
"   read the entire text. In most cases, this is good; however, some mappings
"   and custom commands just want to echo additional, secondary information
"   without disrupting the user. Especially for mappings that are usually
"   repeated quickly "/foo<CR>, n, n, n", a hit-enter prompt would be highly
"   irritating.
"   This script provides :echo[msg]-alike functions which truncate lines so that
"   the hit-enter prompt doesn't happen. The echoed line is too long if it is
"   wider than the width of the window, minus cmdline space taken up by the
"   ruler and showcmd features. The non-standard widths of <Tab>, unprintable
"   (e.g. ^M) and double-width characters (e.g. Japanese Kanji) are taken into
"   account.

" USAGE:
" INSTALLATION:
" DEPENDENCIES:
" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
"  - EchoWithoutScrolling#RenderTabs(): The assumption index == char width
"    doesn't work for unprintable ASCII and any non-ASCII characters.
"
" TODO:
"   - Consider 'cmdheight', add argument isSingleLine.
"
" Copyright: (C) 2008-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	004	05-Jun-2013	In EchoWithoutScrolling#RenderTabs(), make
"				a:tabstop and a:startColumn optional.
"	003	15-May-2009	Added utility function
"				EchoWithoutScrolling#TranslateLineBreaks() to
"				help clients who want to echo a single line, but
"				have text that potentially contains line breaks.
"	002	16-Aug-2008	Split off TruncateTo() from Truncate().
"	001	22-Jul-2008	file creation

function! s:ReverseStr( expr )
    return join( reverse( split( a:expr, '\zs' ) ), '' )
endfunction
function! s:HasMoreThanVirtCol( expr, virtCol )
    return (match( a:expr, '^.*\%>' . a:virtCol . 'v' ) != -1)
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
function! EchoWithoutScrolling#RenderTabs( text, ... )
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
"		    setting.) Defaults to the buffer's 'tabstop' value.
"   a:startColumn   Column at which the text is to be rendered (default 1).
"* RETURN VALUES:
"   a:text with replaced <Tab> characters.
"*******************************************************************************
    if a:text !~# "\t"
	return a:text
    endif

    let l:tabstop = (a:0 ? a:1 : &l:tabstop)
    let l:startColumn = (a:0 > 1 ? a:2 : 1)
    let l:pos = 0
    let l:text = a:text
    while l:pos < strlen(l:text)
	" FIXME: The assumption index == char width doesn't work for unprintable
	" ASCII and any non-ASCII characters.
	let l:pos = stridx( l:text, "\t", l:pos )
	if l:pos == -1
	    break
	endif
	let l:text = strpart(l:text, 0, l:pos) . repeat(' ', EchoWithoutScrolling#GetTabReplacement(l:pos + l:startColumn, l:tabstop)) . strpart(l:text, l:pos + 1)
    endwhile

    return l:text
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
