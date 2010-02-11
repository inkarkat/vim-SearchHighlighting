" ingosearch.vim: Custom search functions. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	002	05-Jan-2010	BUG: Wrong escaping with 'nomagic' setting.
"				Corrected s:specialSearchCharacters for that
"				case. 
"				Renamed ingosearch#GetSearchPattern() to
"				ingosearch#LiteralTextToSearchPattern(). 
"	001	05-Jan-2010	file creation with content from
"				SearchHighlighting.vim. 

" The set of characters that must be escaped depends on the 'magic' setting. 
let s:specialSearchCharacters = ['^$', '^$.*[~']
function! s:EscapeText( text, additionalEscapeCharacters )
"*******************************************************************************
"* PURPOSE:
"   Escape the literal a:text for use in search command. 
"   The ignorant approach is to use atom \V, which sets the following pattern to
"   "very nomagic", i.e. only the backslash has special meaning. For \V, \ still
"   must be escaped. But that's not how the built-in star command works.
"   Instead, all special search characters must be escaped. 
"
"   This works well even with <Tab> (no need to change ^I into \t), but not with
"   a line break, which must be changed from ^M to \n. 
"
"   We also may need to escape additional characters like '/' or '?', because
"   that's done in a search via '*', '/' or '?', too. As the character depends
"   on the search direction ('/' vs. '?'), this is passed in as
"   a:additionalEscapeCharacters. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:text  Literal text. 
"   a:additionalEscapeCharacters    For use in the / command, add '/', for the
"				    backward search command ?, add '?'. For
"				    assignment to @/, always add '/', regardless
"				    of the search direction; this is how Vim
"				    escapes it, too. For use in search(), pass
"				    nothing. 
"* RETURN VALUES: 
"   Regular expression for matching a:text. 
"*******************************************************************************
    return substitute( escape(a:text, '\' . s:specialSearchCharacters[&magic] . a:additionalEscapeCharacters), "\n", '\\n', 'ge' )
endfunction

function! s:MakeWholeWordSearch( text, isWholeWordSearch, pattern )
    " The star command only creates a \<whole word\> search pattern if the
    " <cword> actually only consists of keyword characters. 
    if a:isWholeWordSearch && a:text =~# '^\k\+$'
	return '\<' . a:pattern . '\>'
    else
	return a:pattern
    endif
endfunction

function! ingosearch#LiteralTextToSearchPattern( text, isWholeWordSearch, additionalEscapeCharacters )
"*******************************************************************************
"* PURPOSE:
"   Convert literal a:text into a regular expression, similar to what the
"   built-in * command does. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:text  Literal text. 
"   a:isWholeWordSearch	Flag whether only whole words (* command) or any
"			contained text (g* command) should match. 
"   a:additionalEscapeCharacters    For use in the / command, add '/', for the
"				    backward search command ?, add '?'. For
"				    assignment to @/, always add '/', regardless
"				    of the search direction; this is how Vim
"				    escapes it, too. For use in search(), pass
"				    nothing. 
"* RETURN VALUES: 
"   Regular expression for matching a:text. 
"*******************************************************************************
    " return '\V' . (a:isWholeWordSearch ? '\<' : '') . substitute( escape(a:text, a:additionalEscapeCharacters . '\'), "\n", '\\n', 'ge' ) . (a:isWholeWordSearch ? '\>' : '')
    return s:MakeWholeWordSearch( a:text, a:isWholeWordSearch, s:EscapeText( a:text, a:additionalEscapeCharacters) )
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
