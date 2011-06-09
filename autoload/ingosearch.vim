" ingosearch.vim: Custom search functions. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010-2011 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	005	10-Jun-2011	Add ingosearch#NormalizeMagicness(). 
"	004	17-May-2011	Make ingosearch#EscapeText() public. 
"				Extract ingosearch#GetSpecialSearchCharacters()
"				from s:specialSearchCharacters and expose it. 
"	003	12-Feb-2010	Added ingosearch#WildcardExprToSearchPattern()
"				from the :Help command in ingocommands.vim. 
"	002	05-Jan-2010	BUG: Wrong escaping with 'nomagic' setting.
"				Corrected s:specialSearchCharacters for that
"				case. 
"				Renamed ingosearch#GetSearchPattern() to
"				ingosearch#LiteralTextToSearchPattern(). 
"	001	05-Jan-2010	file creation with content from
"				SearchHighlighting.vim. 

function! ingosearch#GetSpecialSearchCharacters()
    " The set of characters that must be escaped depends on the 'magic' setting. 
    return ['^$', '^$.*[~'][&magic]
endfunction
function! ingosearch#EscapeText( text, additionalEscapeCharacters )
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
    return substitute( escape(a:text, '\' . ingosearch#GetSpecialSearchCharacters() . a:additionalEscapeCharacters), "\n", '\\n', 'ge' )
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
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
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
    return s:MakeWholeWordSearch( a:text, a:isWholeWordSearch, ingosearch#EscapeText( a:text, a:additionalEscapeCharacters) )
endfunction

function! ingosearch#WildcardExprToSearchPattern( wildcardExpr, additionalEscapeCharacters )
"*******************************************************************************
"* PURPOSE:
"   Convert a shell-like a:wildcardExpr which may contain wildcards ? and * into
"   a regular expression. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:wildcardExpr  Text containing file wildcards. 
"   a:additionalEscapeCharacters    For use in the / command, add '/', for the
"				    backward search command ?, add '?'. For
"				    assignment to @/, always add '/', regardless
"				    of the search direction; this is how Vim
"				    escapes it, too. For use in search(), pass
"				    nothing. 
"* RETURN VALUES: 
"   Regular expression for matching a:wildcardExpr. 
"*******************************************************************************
    " From the ? and * and [xyz] wildcards; we emulate the first two here: 
    return '\V' . substitute( substitute( escape(a:wildcardExpr, '\' . a:additionalEscapeCharacters), '?', '\\.', 'g' ), '*', '\\.\\*', 'g' )
endfunction

function! ingosearch#NormalizeMagicness( pattern )
"******************************************************************************
"* PURPOSE:
"   Return normalizing /\m (or /\M) if a:pattern contains atom(s) that change
"   the default magicness. This makes it possible to append another pattern
"   without having a:pattern affect it. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:pattern	Regular expression to observe. 
"* RETURN VALUES: 
"   Normalizing atom or empty string. 
"******************************************************************************
    let l:normalizingAtom = (&magic ? 'm' : 'M')
    let l:magicChangeAtoms = substitute('vmMV', l:normalizingAtom, '', '')

    return (a:pattern =~# '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\\[' . l:magicChangeAtoms . ']' ? '\' . l:normalizingAtom : '')
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
