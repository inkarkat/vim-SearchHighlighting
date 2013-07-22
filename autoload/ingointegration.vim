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
"	018	23-Jul-2013	Move ingointegration#DoWhenBufLoaded() to
"				ingo#ftplugin#onbufwinenter#Execute().
"				Move ingointegration#GetCurrentRegexpSelection()
"				and ingointegration#SelectCurrentRegexp() to
"				ingo/selection/frompattern.vim.
"				Move ingointegration#GetRange() to
"				ingo#range#Get().
"				Move ingointegration#GetText() to
"				ingo#text#Get().
"	017	22-Jul-2013	Move ingointegration#IsFiletype() to
"				ingo#filetype#Is().
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


" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
