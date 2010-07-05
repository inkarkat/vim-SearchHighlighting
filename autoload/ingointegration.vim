" ingointegration.vim: Custom functions for Vim integration. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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
function! ingointegration#DoWhenBufLoaded( command )
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
"* RETURN VALUES: 
"   None. 
"******************************************************************************
    let s:autocmdCnt += 1
    let l:groupName = 'ingointegration' . s:autocmdCnt
    execute 'augroup' l:groupName
	autocmd!
	execute 'autocmd BufWinEnter <buffer> execute' string(a:command) '| autocmd!' l:groupName '* <buffer>'
    augroup END
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
