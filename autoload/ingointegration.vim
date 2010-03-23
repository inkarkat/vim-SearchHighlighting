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
"	001	19-Mar-2010	file creation

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
function! s:OpfuncExpression( opfunc )
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

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
