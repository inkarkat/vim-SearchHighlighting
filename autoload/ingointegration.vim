" ingointegration.vim: Custom functions for Vim integration.
"
" DEPENDENCIES:
"
" Copyright: (C) 2010-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	016	24-May-2013	Move ingointegration#GetVisualSelection() to
"				ingo#selection#Get().
"	015	02-May-2013	Move ingointegration#IsOnSyntaxItem() to
"				ingo#syntaxitem#IsOnSyntax().
"	014	17-Apr-2013	Move
"				ingointegration#BufferRangeToLineRangeCommand()
"				to ingo#cmdrangeconverter#BufferToLineRange().
"				Move
"				ingointegration#OperatorMappingForRangeCommand()
"				to
"				ingo#mapmaker#OperatorMappingForRangeCommand().
"	013	18-Jan-2013	Allow non-identifier characters in rangeCommand
"				of
"				ingointegration#OperatorMappingForRangeCommand()
"				(e.g. "retab! 4"). Do not just use the
"				rangeCommand as-is to generate a function name,
"				but just extract the first word and resolve name
"				clashes by appending a counter.
"   	012	28-Dec-2012	Minor: Correct lnum for no-modifiable buffer
"				check.
"	011	01-Sep-2012	Duplicate CompleteHelper#ExtractText() here as
"				ingointegration#GetText() to avoid that
"				unrelated plugins have a dependency to that
"				library.
"	010	20-Jun-2012	BUG: ingointegration#GetRange() can throw E486;
"				add try...finally and document this.
"	009	14-Jun-2012	Add ingointegration#GetRange().
"	008	16-May-2012	Add ingointegration#GetCurrentRegexpSelection()
"				and ingointegration#SelectCurrentRegexp().
"	007     06-Mar-2012     Add ingointegration#IsFiletype() from
"				insertsignature.vim.
"	006	12-Dec-2011	Assume mutating a:rangeCommand in
"				ingointegration#OperatorMappingForRangeCommand()
"				and handle 'readonly' and 'nomodifiable' buffers
"				without function errors. Implementation copied
"				from autoload/ReplaceWithRegister.vim.
"	005	22-Sep-2011	Include ingointegration#IsOnSyntaxItem() from
"				SearchInSyntax.vim to allow reuse.
"	004	12-Sep-2011	Add ingointegration#GetVisualSelection().
"	003	06-Jul-2010	Added ingointegration#DoWhenBufLoaded().
"	002	24-Mar-2010	Added ingointegration#BufferRangeToLineRangeCommand().
"	001	19-Mar-2010	file creation

let s:autocmdCnt = 0
function! ingointegration#DoWhenBufLoaded( command, ... )
"******************************************************************************
"* MOTIVATION:
"   You want execute a command from a ftplugin (e.g. "normal! gg0") that only is
"   effective when the buffer is already fully loaded, modelines have been
"   processed, other autocmds have run, etc.
"
"* PURPOSE:
"   Schedule the passed a:command to execute once after the current buffer has
"   been fully loaded.
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:command	Ex command to be executed.
"   a:when	Optional configuration of when a:command is executed.
"		By default, it is only executed on the BufWinEnter event, i.e.
"		only when the buffer actually is being loaded. If you want to
"		always execute it (and can live with it being potentially
"		executed twice), so that it is also executed when just the
"		filetype changed of an existing buffer, pass "always" in here.
"* RETURN VALUES:
"   None.
"******************************************************************************
    if a:0 && a:1 ==# 'always'
	execute a:command
    endif

    let s:autocmdCnt += 1
    let l:groupName = 'ingointegration' . s:autocmdCnt
    execute 'augroup' l:groupName
	autocmd!
	execute 'autocmd BufWinEnter <buffer> execute' string(a:command) '| autocmd!' l:groupName '* <buffer>'
	" Remove the run-once autocmd in case the this command was NOT set up
	" during the loading of the buffer (but e.g. by a :setfiletype in an
	" existing buffer), so that it doesn't linger and surprise the user
	" later on.
	execute 'autocmd BufWinLeave,CursorHold,CursorHoldI,WinLeave <buffer> autocmd!' l:groupName '* <buffer>'
    augroup END
endfunction



function! ingointegration#GetRange( range )
"******************************************************************************
"* PURPOSE:
"   Retrieve the contents of the passed range without clobbering any register.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:range A valid |:range|; when empty, the current line is used.
"* RETURN VALUES:
"   Text of the range on lines. Each line ends with a newline character.
"   Throws Vim error "E486: Pattern not found" when the range does not match.
"******************************************************************************
    let l:save_clipboard = &clipboard
    set clipboard= " Avoid clobbering the selection and clipboard registers.
    let l:save_reg = getreg('"')
    let l:save_regmode = getregtype('"')
    try
	silent execute a:range . 'yank'
	let l:contents = @"
    finally
	call setreg('"', l:save_reg, l:save_regmode)
	let &clipboard = l:save_clipboard
    endtry

    return l:contents
endfunction
function! ingointegration#GetText( startPos, endPos )
"*******************************************************************************
"* PURPOSE:
"   Extract the text between a:startPos and a:endPos from the current buffer.
"   Multiple lines will be delimited by a newline character.
"* ASSUMPTIONS / PRECONDITIONS:
"   none
"* EFFECTS / POSTCONDITIONS:
"   none
"* INPUTS:
"   a:startPos	    [line,col]
"   a:endPos	    [line,col]
"* RETURN VALUES:
"   string text
"*******************************************************************************
    let [l:line, l:column] = a:startPos
    let [l:endLine, l:endColumn] = a:endPos
    if l:line > l:endLine || (l:line == l:endLine && l:column > l:endColumn)
	return ''
    endif

    let l:text = ''
    while 1
	if l:line == l:endLine
	    let l:text .= matchstr(getline(l:line) . "\n", '\%' . l:column . 'c' . '.*\%' . (l:endColumn + 1) . 'c')
	    break
	else
	    let l:text .= matchstr(getline(l:line) . "\n", '\%' . l:column . 'c' . '.*')
	    let l:line += 1
	    let l:column = 1
	endif
    endwhile
    return l:text
endfunction


function! ingointegration#GetCurrentRegexpSelection( pattern, ... )
"******************************************************************************
"* PURPOSE:
"   Similar to <cword>, get the selection under / after the cursor that matches
"   a:pattern.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:pattern   Regular expression to match at the cursor position.
"   a:stopline  Optional line number where the search will stop. To get a
"		behavior like <cword>, pass in line('.').
"   a:timeout   Optional timeout when the search will stop.
"* RETURN VALUES:
"   [startLnum, startCol, endLnum, endCol] or [0, 0, 0, 0]
"******************************************************************************
    let l:save_view = winsaveview()
	let l:endPos = call('searchpos', [a:pattern, 'ceW'] + a:000)
	if l:endPos == [0, 0]
	    return [0, 0, 0, 0]
	endif

	let l:startPos = call('searchpos', [a:pattern, 'bcnW'] + a:000)
	if l:startPos == [0, 0]
	    let l:selection = [0, 0, 0, 0]
	else
	    let l:selection = l:startPos + l:endPos
	endif
    call winrestview(l:save_view)

    return l:selection
endfunction

function! ingointegration#SelectCurrentRegexp( selectMode, pattern, ... )
"******************************************************************************
"* PURPOSE:
"   Similar to <cword>, create a visual selection of the text region under /
"   after the cursor that matches a:pattern.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   Creates a visual selection if a:pattern matches.
"* INPUTS:
"   a:selectMode    Visual selection mode, one of "v", "V", or "\<C-v>".
"   a:pattern   Regular expression to match at the cursor position.
"   a:stopline  Optional line number where the search will stop. To get a
"		behavior like <cword>, pass in line('.').
"   a:timeout   Optional timeout when the search will stop.
"* RETURN VALUES:
"   1 if a selection was made, 0 if there was no match.
"******************************************************************************
    let [l:startLnum, l:startCol, l:endLnum, l:endCol] = call('ingointegration#GetCurrentRegexpSelection', [a:pattern] + a:000)
    if [l:startLnum, l:startCol, l:endLnum, l:endCol] == [0, 0, 0, 0]
	return 0
    endif
    call cursor(l:startLnum, l:startCol)
    execute 'normal! zv' . a:selectMode
    call cursor(l:endLnum, l:endCol)
    if &selection ==# 'exclusive'
	normal! l
    endif
    execute "normal! \<Esc>"

    return 1
endfunction

function! ingointegration#IsFiletype( filetypes )
    let l:filetypes = (type(a:filetypes) == type([]) ? a:filetypes : [a:filetypes])

    for l:ft in split(&filetype, '\.')
	if (index(l:filetypes, l:ft) != -1)
	    return 1
	endif
    endfor

    return 0
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
