" ingosearch.vim: Custom search functions. 
"
" DEPENDENCIES:
"   - ingocollections.vim autoload script for ingosearch#NormalizeMagicness(). 
"
" Copyright: (C) 2010-2011 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	007	03-Sep-2011	Extend ingosearch#GetLastForwardSearchPattern()
"				to take optional count into search history. 
"	006	02-Sep-2011	Add ingosearch#GetLastForwardSearchPattern(). 
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

function! ingosearch#GetNormalizeMagicnessAtom( pattern )
"******************************************************************************
"* PURPOSE:
"   Return normalizing \m (or \M) if a:pattern contains atom(s) that change the
"   default magicness. This makes it possible to append another pattern without
"   having a:pattern affect it. 
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

let s:magicAtomsExpr = '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\\[vmMV]'
function! ingosearch#HasMagicAtoms( pattern )
    return a:pattern =~# s:magicAtomsExpr
endfunction
let s:specialSearchCharacterExpressions = {
\   'v': '\W',
\   'm': '[\\^$.*[~]',
\   'M': '[\\^$]',
\   'V': '\\',
\}
function! s:ConvertMagicness( pattern, sourceSpecialCharacterExpr, targetSpecialCharacterExpr )
    let l:isEscaped = 0
    let l:chars = split(a:pattern, '\zs') 
    for l:index in range(len(l:chars))
	let l:char = l:chars[l:index]

	if (l:char =~# a:sourceSpecialCharacterExpr) + (l:char =~# a:targetSpecialCharacterExpr) == 1
	    " The current character belongs to different classes in source and target. 
	    if l:isEscaped
		let l:chars[l:index - 1] = ''
	    else
		let l:chars[l:index] = '\' . l:char
	    endif
	endif

	if l:char ==# '\'
	    let l:isEscaped = ! l:isEscaped
	else
	    let l:isEscaped = 0
	endif
    endfor

    return join(l:chars, '')
endfunction
function! ingosearch#NormalizeMagicness( pattern )
"******************************************************************************
"* PURPOSE:
"   Remove any \v, /m, \M, \V atoms from a:pattern that change the magicness,
"   and re-write the pattern (by selective escaping and unescaping) into an
"   equivalent pattern that is based on the current 'magic' setting. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:pattern	Regular expression that may contain atoms that affect the
"		magicness. 
"* RETURN VALUES: 
"   Equivalent pattern that has any atoms affecting the magicness removed and is
"   based on the current 'magic' setting. 
"******************************************************************************
    let l:currentMagicMode = (&magic ? 'm' : 'M')
    let l:defaultMagicMode = l:currentMagicMode
    let l:patternFragments = ingocollections#SplitKeepSeparators(a:pattern, s:magicAtomsExpr, 1)
    " Because we asked to keep any empty fragments, we can easily test whether
    " there's any work to do. 
    if len(l:patternFragments) == 1
	return a:pattern
    endif
"****D echomsg string(l:patternFragments)
    for l:fragmentIndex in range(len(l:patternFragments))
	let l:fragment = l:patternFragments[l:fragmentIndex]
	if l:fragment =~# s:magicAtomsExpr
	    let l:currentMagicMode = l:fragment[1]
	    let l:patternFragments[l:fragmentIndex] = ''
	    continue
	endif

	if l:currentMagicMode ==# l:defaultMagicMode
	    " No need for conversion. 
	    continue
	endif

	let l:patternFragments[l:fragmentIndex] = s:ConvertMagicness(
	\   l:fragment,
	\   s:specialSearchCharacterExpressions[l:currentMagicMode],
	\   s:specialSearchCharacterExpressions[l:defaultMagicMode]
	\)
    endfor
"****D echomsg string(l:patternFragments)
    return join(l:patternFragments, '')
endfunction

function! ingosearch#GetLastForwardSearchPattern( ... )
"******************************************************************************
"* PURPOSE:
"   Get @/, or the a:count'th last search pattern, but also handle the case
"   where the pattern was set from a backward search, and doesn't have "/"
"   characters properly escaped. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   None. 
"* RETURN VALUES: 
"   Last search pattern ready to use in a :s/{pat}/ command, with forward
"   slashes properly escaped. 
"******************************************************************************
    return substitute((a:0 ? histget('search', -1 * a:1) : @/), '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!/', '\\/', 'g')
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
