" ingointegration.vim: Custom functions for Vim integration. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010-2011 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	005	22-Sep-2011	Include ingointegration#IsOnSyntaxItem() from
"				SearchInSyntax.vim to allow reuse. 
"	004	12-Sep-2011	Add ingointegration#GetVisualSelection(). 
"	003	06-Jul-2010	Added ingointegration#DoWhenBufLoaded(). 
"	002	24-Mar-2010	Added ingointegration#BufferRangeToLineRangeCommand(). 
"	001	19-Mar-2010	file creation

function! s:OpfuncExpression( opfunc )
"******************************************************************************
"* PURPOSE:
"   Define a custom operator mapping "\xx{motion}" (where \xx is a:mapKeys) that
"   allow a [count] before and after the operator and support repetition via
"   |.|. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   Defines a normal mode mapping for a:mapKeys. 
"* INPUTS:
"   a:mapArgs	Arguments to the :map command, like '<buffer>' for a
"		buffer-local mapping. 
"   a:mapKeys	Mapping key [sequence]. 
"   a:rangeCommand  Custom Ex command which takes a [range]. 
"
"* RETURN VALUES: 
"   None. 
"******************************************************************************
    let &opfunc = a:opfunc
    return 'g@'
endfunction
function! ingointegration#OperatorMappingForRangeCommand( mapArgs, mapKeys, rangeCommand )
    let l:rangeCommandOperator = a:rangeCommand . 'Operator'
    execute printf("
    \	function! s:%s( type )\n
    \	    execute \"'[,']%s\"\n
    \	endfunction\n",
    \	l:rangeCommandOperator,
    \	a:rangeCommand
    \)

    execute 'nnoremap <expr>' a:mapArgs a:mapKeys '<SID>OpfuncExpression(''<SID>' . l:rangeCommandOperator . ''')'
endfunction


function! ingointegration#BufferRangeToLineRangeCommand( cmd ) range
"******************************************************************************
"* MOTIVATION:
"   You want to invoke a command :Foo in a line-wise mapping <Leader>foo; the
"   command has a default range=%. The simplest solution is
"	nnoremap <Leader>foo :<C-u>.Foo<CR>
"   but that doesn't support a [count]. You cannot use
"	nnoremap <Leader>foo :Foo<CR>
"   neither, because then the mapping will work on the entire buffer if no
"   [count] is given. This utility function wraps the Foo command, passes the
"   given range, and falls back to the current line when no [count] is given: 
"	nnoremap <Leader>foo :call ingointegration#BufferRangeToLineRangeCommand('Foo')<CR>
"
"* PURPOSE:
"   Always pass the line-wise range to a:cmd. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:cmd   Ex command which has a default range=%. 
"* RETURN VALUES: 
"   None. 
"******************************************************************************
    try
	execute a:firstline . ',' . a:lastline . a:cmd
    catch /^Vim\%((\a\+)\)\=:E/
	echohl ErrorMsg
	" v:exception contains what is normally in v:errmsg, but with extra
	" exception source info prepended, which we cut away. 
	let v:errmsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
	echomsg v:errmsg
	echohl None
    endtry
endfunction


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



function! ingointegration#GetVisualSelection()
"******************************************************************************
"* PURPOSE:
"   Retrieve the contents of the current visual selection without clobbering any
"   register. 
"* ASSUMPTIONS / PRECONDITIONS:
"   Visual selection is / has been made. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   None. 
"* RETURN VALUES: 
"   Text of visual selection. 
"******************************************************************************
    let l:save_clipboard = &clipboard
    set clipboard= " Avoid clobbering the selection and clipboard registers. 
    let l:save_reg = getreg('"')
    let l:save_regmode = getregtype('"')
    execute 'silent normal! gvy'
    let l:selection = @"
    call setreg('"', l:save_reg, l:save_regmode)
    let &clipboard = l:save_clipboard
    return l:selection
endfunction


if exists('*synstack')
function! ingointegration#IsOnSyntaxItem( pos, syntaxItemPattern )
    " Taking the example of comments: 
    " Other syntax groups (e.g. Todo) may be embedded in comments. We must thus
    " check whole stack of syntax items at the cursor position for comments. 
    " Comments are detected via the translated, effective syntax name. (E.g. in
    " Vimscript, 'vimLineComment' is linked to 'Comment'.) 
    for l:id in synstack(a:pos[1], a:pos[2])
	let l:actualSyntaxItemName = synIDattr(l:id, 'name')
	let l:effectiveSyntaxItemName = synIDattr(synIDtrans(l:id), 'name')
"****D echomsg '****' l:actualSyntaxItemName . '->' . l:effectiveSyntaxItemName
	if l:actualSyntaxItemName =~# a:syntaxItemPattern || l:effectiveSyntaxItemName =~# a:syntaxItemPattern
	    return 1
	endif
    endfor
    return 0
endfunction
else
function! ingointegration#IsOnSyntaxItem( pos, syntaxItemPattern )
    " Taking the example of comments: 
    " Other syntax groups (e.g. Todo) may be embedded in comments. As the
    " synstack() function is not available, we can only try to get the actual
    " syntax ID and the one of the syntax item that determines the effective
    " color. 
    " Comments are detected via the translated, effective syntax name. (E.g. in
    " Vimscript, 'vimLineComment' is linked to 'Comment'.) 
    for l:id in [synID(a:pos[1], a:pos[2], 0), synID(a:pos[1], a:pos[2], 1)]
	let l:actualSyntaxItemName = synIDattr(l:id, 'name')
	let l:effectiveSyntaxItemName = synIDattr(synIDtrans(l:id), 'name')
"****D echomsg '****' l:actualSyntaxItemName . '->' . l:effectiveSyntaxItemName
	if l:actualSyntaxItemName =~# a:syntaxItemPattern || l:effectiveSyntaxItemName =~# a:syntaxItemPattern
	    return 1
	endif
    endfor
    return 0
endfunction
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
