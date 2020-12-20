" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" VimRoam syntax file
" Description: Defines markdown custom syntax
" Home: https://github.com/jeffmm/vimroam/


function! s:add_target_syntax_ON(target, type) abort
  let prefix0 = 'syntax match '.a:type.' `'
  let suffix0 = '` display contains=@NoSpell,VimRoamLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match '.a:type.'T `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:add_target_syntax_OFF(target, type) abort
  let prefix0 = 'syntax match VimRoamNoExistsLink `'
  let suffix0 = '` display contains=@NoSpell,VimRoamLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match VimRoamNoExistsLinkT `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:wrap_wikilink1_rx(target) abort
  return vimroam#vars#get_syntaxlocal('rxWikiLink1InvalidPrefix') . a:target.
        \ vimroam#vars#get_syntaxlocal('rxWikiLink1InvalidSuffix')
endfunction


function! s:existing_mkd_refs() abort
  return keys(vimroam#markdown_base#scan_reflinks())
endfunction


function! s:highlight_existing_links() abort
  " Wikilink1
  " Conditional highlighting that depends on the existence of a wiki file or
  "   directory is only available for *schemeless* wiki links
  " Links are set up upon BufEnter (see plugin/...)
  let safe_links = '\%('.
        \ vimroam#base#file_pattern(vimroam#vars#get_bufferlocal('existing_wikifiles')) .
        \ '\%(#[^|]*\)\?\|#[^|]*\)'
  " Wikilink1 Dirs set up upon BufEnter (see plugin/...)
  let safe_dirs = vimroam#base#file_pattern(vimroam#vars#get_bufferlocal('existing_wikidirs'))
  " Ref links are cached
  let safe_reflinks = vimroam#base#file_pattern(s:existing_mkd_refs())


  " match [URL][]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template1')),
        \ safe_links, vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimRoamWikiLink1')
  " match [DESCRIPTION][URL]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template2')),
        \ safe_links, vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimRoamWikiLink1')

  " match [DIRURL][]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template1')),
        \ safe_dirs, vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimRoamWikiLink1')
  " match [DESCRIPTION][DIRURL]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template2')),
        \ safe_dirs, vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimRoamWikiLink1')

  " match [MKDREF][]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template1')),
        \ safe_reflinks, vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimRoamWikiLink1')
  " match [DESCRIPTION][MKDREF]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template2')),
        \ safe_reflinks, vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimRoamWikiLink1')
endfunction


" use max highlighting - could be quite slow if there are too many wikifiles
if vimroam#vars#get_wikilocal('maxhi')
  " WikiLink
  call s:add_target_syntax_OFF(vimroam#vars#get_syntaxlocal('rxWikiLink1'), 'VimRoamWikiLink1')

  " Subsequently, links verified on vimroam's path are highlighted as existing
  call s:highlight_existing_links()
else
  " Wikilink
  call s:add_target_syntax_ON(vimroam#vars#get_syntaxlocal('rxWikiLink1'), 'VimRoamWikiLink1')
endif


" Weblink
call s:add_target_syntax_ON(vimroam#vars#get_syntaxlocal('rxWeblink1'), 'VimRoamWeblink1')
call s:add_target_syntax_ON(vimroam#vars#get_syntaxlocal('rxImage'), 'VimRoamImage')


" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ vimroam#vars#get_global('schemes') . '\|'.
      \ vimroam#vars#get_global('web_schemes1').
      \ '\):'

" a) match [nonwiki-scheme-URL]
let s:target = vimroam#base#apply_template(
      \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template1')),
      \ s:rxSchemes . vimroam#vars#get_syntaxlocal('rxWikiLink1Url'),
      \ vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
call s:add_target_syntax_ON(s:wrap_wikilink1_rx(s:target), 'VimRoamWikiLink1')
" b) match [DESCRIPTION][nonwiki-scheme-URL]
let s:target = vimroam#base#apply_template(
      \ vimroam#u#escape(vimroam#vars#get_syntaxlocal('WikiLink1Template2')),
      \ s:rxSchemes . vimroam#vars#get_syntaxlocal('rxWikiLink1Url'),
      \ vimroam#vars#get_syntaxlocal('rxWikiLink1Descr'), '', '')
call s:add_target_syntax_ON(s:wrap_wikilink1_rx(s:target), 'VimRoamWikiLink1')


" concealed chars
if exists('+conceallevel')
  syntax conceal on
endif

syntax spell toplevel

" VimRoamWikiLink1Char is for syntax markers (and also URL when a description
" is present) and may be concealed
let s:options = ' contained transparent contains=NONE'
" conceal wikilink1
execute 'syn match VimRoamWikiLink1Char /'.
            \ vimroam#vars#get_syntaxlocal('rx_wikilink_md_prefix').'/'.s:options
execute 'syn match VimRoamWikiLink1Char /'.
            \ vimroam#vars#get_syntaxlocal('rx_wikilink_md_suffix').'/'.s:options
execute 'syn match VimRoamWikiLink1Char /'.
            \ vimroam#vars#get_syntaxlocal('rxWikiLink1Prefix1').'/'.s:options
execute 'syn match VimRoamWikiLink1Char /'.
            \ vimroam#vars#get_syntaxlocal('rxWikiLink1Suffix1').'/'.s:options

" conceal weblink1
execute 'syn match VimRoamWeblink1Char "'.
            \ vimroam#vars#get_syntaxlocal('rxWeblink1Prefix1').'"'.s:options
execute 'syn match VimRoamWeblink1Char "'.
            \ vimroam#vars#get_syntaxlocal('rxWeblink1Suffix1').'"'.s:options
"image
execute 'syn match VimRoamImageChar "!"'.s:options
execute 'syn match VimRoamImageChar "'.
            \ vimroam#vars#get_syntaxlocal('rxWeblink1Prefix1').'"'.s:options
execute 'syn match VimRoamImageChar "'.
            \ vimroam#vars#get_syntaxlocal('rxWeblink1Suffix1').'"'.s:options

if exists('+conceallevel')
  syntax conceal off
endif



" Tables
syntax match VimRoamTableRow /^\s*|.\+|\s*$/
      \ transparent contains=VimRoamCellSeparator,
                           \ VimRoamLinkT,
                           \ VimRoamWeblink1T,
                           \ VimRoamWikiLink1T,
                           \ VimRoamNoExistsLinkT,
                           \ VimRoamTodo,
                           \ VimRoamBoldT,
                           \ VimRoamItalicT,
                           \ VimRoamBoldItalicT,
                           \ VimRoamItalicBoldT,
                           \ VimRoamDelTextT,
                           \ VimRoamSuperScriptT,
                           \ VimRoamSubScriptT,
                           \ VimRoamCodeT,
                           \ VimRoamEqInT,
                           \ @Spell

" TODO fix behavior within lists https://github.github.com/gfm/#list-items
" indented code blocks https://github.github.com/gfm/#indented-code-blocks
" execute 'syntax match VimRoamIndentedCodeBlock /' . vimroam#vars#get_syntaxlocal('rxIndentedCodeBlock') . '/'
" hi def link VimRoamIndentedCodeBlock VimRoamPre

" syntax group highlighting
hi def link VimRoamImage VimRoamLink
hi def link VimRoamImageT VimRoamLink
hi def link VimRoamWeblink1 VimRoamLink
hi def link VimRoamWeblink1T VimRoamLink

hi def link VimRoamWikiLink1 VimRoamLink
hi def link VimRoamWikiLink1T VimRoamLink

