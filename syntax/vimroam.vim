" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" VimRoam syntax file
" Home: https://github.com/jeffmm/vimroam/


" Quit if syntax file is already loaded
if v:version < 600
  syntax clear
elseif exists('b:current_syntax')
  finish
endif


let s:current_syntax = vimroam#vars#get_wikilocal('syntax')

" Get config: possibly concealed chars
let b:vimroam_syntax_conceal = exists('+conceallevel') ? ' conceal' : ''
let b:vimroam_syntax_concealends = has('conceal') ? ' concealends' : ''


" Populate all syntax vars
" Include syntax/vimroam_markdown.vim as "side effect"
call vimroam#vars#populate_syntax_vars(s:current_syntax)
let syntax_dic = g:vimroam_syntaxlocal_vars[s:current_syntax]

" Declare nesting capabilities
" -- to be embeded in standard: bold, italic, underline

" text: `code` or ``code`` only inline
" Note: `\%(^\|[^`]\)\@<=` means after a new line or a non `

" LINKS: highlighting is complicated due to "nonexistent" links feature
function! s:add_target_syntax_ON(target, type) abort
  let prefix0 = 'syntax match '.a:type.' `'
  let suffix0 = '` display contains=@NoSpell,VimRoamLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match '.a:type.'T `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:add_target_syntax_OFF(target) abort
  let prefix0 = 'syntax match VimRoamNoExistsLink `'
  let suffix0 = '` display contains=@NoSpell,VimRoamLinkRest,VimRoamLinkChar'
  let prefix1 = 'syntax match VimRoamNoExistsLinkT `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:highlight_existing_links() abort
  " Wikilink
  " Conditional highlighting that depends on the existence of a wiki file or
  "   directory is only available for *schemeless* wiki links
  " Links are set up upon BufEnter (see plugin/...)
  let safe_links = '\%('.vimroam#base#file_pattern(
        \ vimroam#vars#get_bufferlocal('existing_wikifiles')) . '\%(#[^|]*\)\?\|#[^|]*\)'
  " Wikilink Dirs set up upon BufEnter (see plugin/...)
  let safe_dirs = vimroam#base#file_pattern(vimroam#vars#get_bufferlocal('existing_wikidirs'))

  " match [[URL]]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_global('WikiLinkTemplate1')),
        \ safe_links, vimroam#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimRoamLink')
  " match [[URL|DESCRIPTION]]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_global('WikiLinkTemplate2')),
        \ safe_links, vimroam#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimRoamLink')

  " match {{URL}}
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_global('WikiInclTemplate1')),
        \ safe_links, vimroam#vars#get_global('rxWikiInclArgs'), '', '')
  call s:add_target_syntax_ON(target, 'VimRoamLink')
  " match {{URL|...}}
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_global('WikiInclTemplate2')),
        \ safe_links, vimroam#vars#get_global('rxWikiInclArgs'), '', '')
  call s:add_target_syntax_ON(target, 'VimRoamLink')
  " match [[DIRURL]]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_global('WikiLinkTemplate1')),
        \ safe_dirs, vimroam#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimRoamLink')
  " match [[DIRURL|DESCRIPTION]]
  let target = vimroam#base#apply_template(
        \ vimroam#u#escape(vimroam#vars#get_global('WikiLinkTemplate2')),
        \ safe_dirs, vimroam#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimRoamLink')
endfunction


" use max highlighting - could be quite slow if there are too many wikifiles
if vimroam#vars#get_wikilocal('maxhi')
  " WikiLink
  call s:add_target_syntax_OFF(vimroam#vars#get_syntaxlocal('rxWikiLink'))
  " WikiIncl
  call s:add_target_syntax_OFF(vimroam#vars#get_global('rxWikiIncl'))

  " Subsequently, links verified on vimroam's path are highlighted as existing
  call s:highlight_existing_links()
else
  " Wikilink
  call s:add_target_syntax_ON(vimroam#vars#get_syntaxlocal('rxWikiLink'), 'VimRoamLink')
  " WikiIncl
  call s:add_target_syntax_ON(vimroam#vars#get_global('rxWikiIncl'), 'VimRoamLink')
endif


" Weblink: [DESCRIPTION](FILE)
call s:add_target_syntax_ON(vimroam#vars#get_syntaxlocal('rxWeblink'), 'VimRoamLink')


" WikiLink:
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ vimroam#vars#get_global('schemes') . '\|'.
      \ vimroam#vars#get_global('web_schemes1').
      \ '\):'

" a) match [[nonwiki-scheme-URL]]
let s:target = vimroam#base#apply_template(
      \ vimroam#u#escape(vimroam#vars#get_global('WikiLinkTemplate1')),
      \ s:rxSchemes.vimroam#vars#get_global('rxWikiLinkUrl'),
      \ vimroam#vars#get_global('rxWikiLinkDescr'), '', '')
call s:add_target_syntax_ON(s:target, 'VimRoamLink')
" b) match [[nonwiki-scheme-URL|DESCRIPTION]]
let s:target = vimroam#base#apply_template(
      \ vimroam#u#escape(vimroam#vars#get_global('WikiLinkTemplate2')),
      \ s:rxSchemes.vimroam#vars#get_global('rxWikiLinkUrl'),
      \ vimroam#vars#get_global('rxWikiLinkDescr'), '', '')
call s:add_target_syntax_ON(s:target, 'VimRoamLink')

" a) match {{nonwiki-scheme-URL}}
let s:target = vimroam#base#apply_template(
      \ vimroam#u#escape(vimroam#vars#get_global('WikiInclTemplate1')),
      \ s:rxSchemes.vimroam#vars#get_global('rxWikiInclUrl'),
      \ vimroam#vars#get_global('rxWikiInclArgs'), '', '')
call s:add_target_syntax_ON(s:target, 'VimRoamLink')
" b) match {{nonwiki-scheme-URL}[{...}]}
let s:target = vimroam#base#apply_template(
      \ vimroam#u#escape(vimroam#vars#get_global('WikiInclTemplate2')),
      \ s:rxSchemes.vimroam#vars#get_global('rxWikiInclUrl'),
      \ vimroam#vars#get_global('rxWikiInclArgs'), '', '')
call s:add_target_syntax_ON(s:target, 'VimRoamLink')


" Header Level: 1..6
for s:i in range(1,6)
  " WebLink are for markdown but putting them here avoidcode duplication 
  " -- and syntax folding Issue #1009
  execute 'syntax match VimRoamHeader'.s:i
      \ . ' /'.vimroam#vars#get_syntaxlocal('rxH'.s:i, s:current_syntax)
      \ . '/ contains=VimRoamTodo,VimRoamHeaderChar,VimRoamNoExistsLink,VimRoamCode,'
      \ . 'VimRoamLink,VimRoamWeblink1,VimRoamWikiLink1,VimRoamList,VimRoamListTodo,@Spell'
  execute 'syntax region VimRoamH'.s:i.'Folding start=/'
      \ . vimroam#vars#get_syntaxlocal('rxH'.s:i.'_Start', s:current_syntax).'/ end=/'
      \ . vimroam#vars#get_syntaxlocal('rxH'.s:i.'_End', s:current_syntax)
      \ . '/me=s-1'
      \ . ' transparent fold'
endfor


" SetExt Header:
" TODO mutualise SetExt Regexp
let setex_header1_re = '^\s\{0,3}[^>].*\n\s\{0,3}==\+$'
let setex_header2_re = '^\s\{0,3}[^>].*\n\s\{0,3}--\+$'
execute 'syntax match VimRoamHeader1'
    \ . ' /'. setex_header1_re . '/ '
    \ 'contains=VimRoamTodo,VimRoamHeaderChar,VimRoamNoExistsLink,VimRoamCode,'.
    \ 'VimRoamLink,@Spell'
execute 'syntax match VimRoamHeader2'
    \ . ' /'. setex_header2_re . '/ ' .
    \ 'contains=VimRoamTodo,VimRoamHeaderChar,VimRoamNoExistsLink,VimRoamCode,'.
    \ 'VimRoamLink,@Spell'


let s:options = ' contained transparent contains=NONE'
if exists('+conceallevel')
  let s:options .= b:vimroam_syntax_conceal
endif

" A shortener for long URLs: LinkRest (a middle part of the URL) is concealed
" VimRoamLinkRest group is left undefined if link shortening is not desired
if exists('+conceallevel') && vimroam#vars#get_global('url_maxsave') > 0
  execute 'syn match VimRoamLinkRest `\%(///\=[^/ \t]\+/\)\zs\S\+\ze'
        \.'\%([/#?]\w\|\S\{'.vimroam#vars#get_global('url_maxsave').'}\)`'.' cchar=~'.s:options
endif

" VimRoamLinkChar is for syntax markers (and also URL when a description
" is present) and may be concealed

" conceal wikilinks
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rx_wikilink_prefix').'/'.s:options
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rx_wikilink_suffix').'/'.s:options
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rx_wikilink_prefix1').'/'.s:options
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rx_wikilink_suffix1').'/'.s:options

" conceal wikiincls
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rxWikiInclPrefix').'/'.s:options
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rxWikiInclSuffix').'/'.s:options
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rxWikiInclPrefix1').'/'.s:options
execute 'syn match VimRoamLinkChar /'.vimroam#vars#get_global('rxWikiInclSuffix1').'/'.s:options


" non concealed chars
execute 'syn match VimRoamHeaderChar contained /\%(^\s*'.
      \ vimroam#vars#get_syntaxlocal('header_symbol').'\+\)\|\%('.vimroam#vars#get_syntaxlocal('header_symbol').
      \ '\+\s*$\)/'

execute 'syntax match VimRoamTodo /'. vimroam#vars#get_wikilocal('rx_todo') .'/'


" Table:
syntax match VimRoamTableRow /^\s*|.\+|\s*$/
      \ transparent contains=VimRoamCellSeparator,
                           \ VimRoamLinkT,
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
                           \ VimRoamEmoji,
                           \ @Spell

syntax match VimRoamCellSeparator /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained

" List:
execute 'syntax match VimRoamList /'.vimroam#vars#get_wikilocal('rxListItemWithoutCB').'/'
execute 'syntax match VimRoamList /'.vimroam#vars#get_syntaxlocal('rxListDefine').'/'
execute 'syntax match VimRoamListTodo /'.vimroam#vars#get_wikilocal('rxListItem').'/'

" Task List Done:
if vimroam#vars#get_global('hl_cb_checked') == 1
  execute 'syntax match VimRoamCheckBoxDone /'.vimroam#vars#get_wikilocal('rxListItemWithoutCB')
        \ . '\s*\[['.vimroam#vars#get_wikilocal('listsyms_list')[-1]
        \ . vimroam#vars#get_global('listsym_rejected')
        \ . ']\]\s\(.*\)$/ '
        \ . 'contains=' . syntax_dic.nested . ',VimRoamNoExistsLink,VimRoamLink,VimRoamWeblink1,VimRoamWikiLink1,@Spell'
elseif vimroam#vars#get_global('hl_cb_checked') == 2
  execute 'syntax match VimRoamCheckBoxDone /'
        \ . vimroam#vars#get_wikilocal('rxListItemAndChildren')
        \ .'/ contains=VimRoamNoExistsLink,VimRoamLink,VimRoamWeblink1,VimRoamWikiLink1,@Spell'
endif


" Horizontal Rule: <hr>
execute 'syntax match VimRoamHR /'.vimroam#vars#get_syntaxlocal('rxHR').'/'

let concealpre = vimroam#vars#get_global('conceal_pre') ? ' concealends' : ''
execute 'syntax region VimRoamPre matchgroup=VimRoamPreDelim start=/'.vimroam#vars#get_syntaxlocal('rxPreStart').
      \ '/ end=/'.vimroam#vars#get_syntaxlocal('rxPreEnd').'/ contains=@NoSpell'.concealpre

execute 'syntax region VimRoamMath start=/'.vimroam#vars#get_syntaxlocal('rxMathStart').
      \ '/ end=/'.vimroam#vars#get_syntaxlocal('rxMathEnd').'/ contains=@NoSpell'


" Placeholder:
syntax match VimRoamPlaceholder /^\s*%nohtml\s*$/
syntax match VimRoamPlaceholder
      \ /^\s*%title\ze\%(\s.*\)\?$/ nextgroup=VimRoamPlaceholderParam skipwhite
syntax match VimRoamPlaceholder
      \ /^\s*%date\ze\%(\s.*\)\?$/ nextgroup=VimRoamPlaceholderParam skipwhite
syntax match VimRoamPlaceholder
      \ /^\s*%template\ze\%(\s.*\)\?$/ nextgroup=VimRoamPlaceholderParam skipwhite
syntax match VimRoamPlaceholderParam /.*/ contained


" Html Tag: <u>
if vimroam#vars#get_global('valid_html_tags') !=? ''
  let s:html_tags = join(split(vimroam#vars#get_global('valid_html_tags'), '\s*,\s*'), '\|')
  exe 'syntax match VimRoamHTMLtag #\c</\?\%('.s:html_tags.'\)\%(\s\{-1}\S\{-}\)\{-}\s*/\?>#'
  
  " Typeface:
  let html_typeface = {
    \ 'bold': [['<b>', '</b\_s*>'], ['<strong>', '</strong\_s*>']],
    \ 'italic': [['<i>', '</i\_s*>'], ['<em>', '</em\_s*>']],
    \ 'underline': [['<u>', '</u\_s*>']],
    \ 'code': [['<code>', '</code\_s*>']],
    \ 'del': [['<del>', '</del\_s*>']],
    \ 'eq': [],
    \ 'sup': [['<sup>', '</sup\_s*>']],
    \ 'sub': [['<sub>', '</sub\_s*>']],
    \ }
  call vimroam#u#hi_typeface(html_typeface)
endif

" Html Color: <span style="color:#FF0000";>Red paragraph</span>
" -- See: h color_dic
let color_dic = vimroam#vars#get_wikilocal('color_dic')
let color_tag = vimroam#vars#get_wikilocal('color_tag_template')
for [color_key, color_value] in items(color_dic)
  let [fg, bg] = color_value
  let delimiter = color_tag
  let delimiter = substitute(delimiter, '__COLORFG__', fg, 'g')
  let delimiter = substitute(delimiter, '__COLORBG__', bg, 'g')
  " The user input has been already checked
  let [pre_region, post_region] = split(delimiter, '__CONTENT__')
  let cmd = 'syntax region VimRoam' . color_key . ' matchgroup=VimRoamDelimiterColor'
        \ . ' start=/' . pre_region . '/'
        \ . ' end=/' . post_region . '/'
        \ . ' ' . b:vimroam_syntax_concealends
  execute cmd

  " Build hightlight command
  let cmd = 'hi VimRoam' . color_key
  if fg !=# ''
    let cmd .= ' guifg=' . fg
  endif
  if bg !=# ''
    let cmd .= ' guibg=' . bg
  endif
  execute cmd
endfor


" Comment: home made
execute 'syntax match VimRoamComment /'.vimroam#vars#get_syntaxlocal('comment_regex').
    \ '/ contains=@Spell,VimRoamTodo'
" Only do syntax highlighting for multiline comments if they exist
let mc_format = vimroam#vars#get_syntaxlocal('multiline_comment_format')
if !empty(mc_format.pre_mark) && !empty(mc_format.post_mark)
execute 'syntax region VimRoamMultilineComment start=/'.mc_format.pre_mark.
      \ '/ end=/'.mc_format.post_mark.'/ contains=@NoSpell,VimRoamTodo'
endif

" Tag:
let tag_cmd = 'syntax match VimRoamTag /'.vimroam#vars#get_syntaxlocal('rxTags').'/'
let tf = vimroam#vars#get_wikilocal('tag_format')
if exists('+conceallevel') && tf.conceal != 0
  let tag_cmd .= ' conceal'
  if tf.cchar !=# ''
    let tag_cmd .= ' cchar=' . tf.cchar
  endif
endif
execute tag_cmd


" Header Groups: highlighting
if vimroam#vars#get_global('hl_headers') == 0
  " Strangely in default colorscheme Title group is not set to bold for cterm...
  if !exists('g:colors_name')
    hi Title cterm=bold
  endif
  for s:i in range(1,6)
    execute 'hi def link VimRoamHeader'.s:i.' Title'
  endfor
else
  for s:i in range(1,6)
    execute 'hi def VimRoamHeader'.s:i.' guibg=bg guifg='
          \ .vimroam#vars#get_global('hcolor_guifg_'.&background)[s:i-1].' gui=bold ctermfg='
          \ .vimroam#vars#get_global('hcolor_ctermfg_'.&background)[s:i-1].' term=bold cterm=bold'
  endfor
endif


" Typeface: -> u.vim
let s:typeface_dic = vimroam#vars#get_syntaxlocal('typeface')
call vimroam#u#hi_typeface(s:typeface_dic)


" Link highlighting groups
""""""""""""""""""""""""""

hi def link VimRoamMarkers Normal
hi def link VimRoamError Normal

hi def link VimRoamEqIn Number
hi def link VimRoamEqInT VimRoamEqIn

" Typeface 1
hi def VimRoamBold term=bold cterm=bold gui=bold
hi def link VimRoamBoldT VimRoamBold

hi def VimRoamItalic term=italic cterm=italic gui=italic
hi def link VimRoamItalicT VimRoamItalic

hi def VimRoamUnderline term=underline cterm=underline gui=underline

" Typeface 2
" Bold > Italic > Underline
hi def VimRoamBoldItalic term=bold,italic cterm=bold,italic gui=bold,italic
hi def link VimRoamItalicBold VimRoamBoldItalic
hi def link VimRoamBoldItalicT VimRoamBoldItalic
hi def link VimRoamItalicBoldT VimRoamBoldItalic

hi def VimRoamBoldUnderline term=bold,underline cterm=bold,underline gui=bold,underline
hi def link VimRoamUnderlineBold VimRoamBoldUnderline

hi def VimRoamItalicUnderline term=italic,underline cterm=italic,underline gui=italic,underline
hi def link VimRoamUnderlineItalic VimRoamItalicUnderline

" Typeface 3
hi def VimRoamItalicUnderline term=italic,underline cterm=italic,underline gui=italic,underline
hi def link VimRoamBoldUnderlineItalic VimRoamBoldItalicUnderline
hi def link VimRoamItalicBoldUnderline VimRoamBoldItalicUnderline
hi def link VimRoamItalicUnderlineBold VimRoamBoldItalicUnderline
hi def link VimRoamUnderlineBoldItalic VimRoamBoldItalicUnderline
hi def link VimRoamUnderlineItalicBold VimRoamBoldItalicUnderline

" Typeface 2
hi def VimRoamBoldUnderlineItalic term=bold,italic,underline cterm=bold,italic,underline gui=bold,italic,underline

" Code
hi def link VimRoamCode PreProc
hi def link VimRoamCodeT VimRoamCode

hi def link VimRoamPre PreProc
hi def link VimRoamPreT VimRoamPre
hi def link VimRoamPreDelim VimRoamPre

hi def link VimRoamMath Number
hi def link VimRoamMathT VimRoamMath

hi def link VimRoamNoExistsLink SpellBad
hi def link VimRoamNoExistsLinkT VimRoamNoExistsLink

hi def link VimRoamLink Underlined
hi def link VimRoamLinkT VimRoamLink

hi def link VimRoamList Identifier
hi def link VimRoamListTodo VimRoamList
hi def link VimRoamCheckBoxDone Comment
hi def link VimRoamHR Identifier
hi def link VimRoamTag Keyword


" Deleted called strikethrough
" See $VIMRUTIME/syntax/html.vim
if v:version > 800 || (v:version == 800 && has('patch1038')) || has('nvim-0.4.3')
  hi def VimRoamDelText term=strikethrough cterm=strikethrough gui=strikethrough
else
  hi def link VimRoamDelText Constant
endif
hi def link VimRoamDelTextT VimRoamDelText

hi def link VimRoamSuperScript Number
hi def link VimRoamSuperScriptT VimRoamSuperScript

hi def link VimRoamSubScript Number
hi def link VimRoamSubScriptT VimRoamSubScript

hi def link VimRoamTodo Todo
hi def link VimRoamComment Comment
hi def link VimRoamMultilineComment Comment

hi def link VimRoamPlaceholder SpecialKey
hi def link VimRoamPlaceholderParam String
hi def link VimRoamHTMLtag SpecialKey

hi def link VimRoamEqInChar VimRoamMarkers
hi def link VimRoamCellSeparator VimRoamMarkers
hi def link VimRoamBoldChar VimRoamMarkers
hi def link VimRoamItalicChar VimRoamMarkers
hi def link VimRoamBoldItalicChar VimRoamMarkers
hi def link VimRoamItalicBoldChar VimRoamMarkers
hi def link VimRoamDelTextChar VimRoamMarkers
hi def link VimRoamSuperScriptChar VimRoamMarkers
hi def link VimRoamSubScriptChar VimRoamMarkers
hi def link VimRoamCodeChar VimRoamMarkers
hi def link VimRoamHeaderChar VimRoamMarkers

" TODO remove unsued due to region refactoring
hi def link VimRoamEqInCharT VimRoamMarkers
hi def link VimRoamBoldCharT VimRoamMarkers
hi def link VimRoamItalicCharT VimRoamMarkers
hi def link VimRoamBoldItalicCharT VimRoamMarkers
hi def link VimRoamItalicBoldCharT VimRoamMarkers
hi def link VimRoamDelTextCharT VimRoamMarkers
hi def link VimRoamSuperScriptCharT VimRoamMarkers
hi def link VimRoamSubScriptCharT VimRoamMarkers
hi def link VimRoamCodeCharT VimRoamMarkers
hi def link VimRoamHeaderCharT VimRoamMarkers
hi def link VimRoamLinkCharT VimRoamLinkT
hi def link VimRoamNoExistsLinkCharT VimRoamNoExistsLinkT


" Load syntax-specific functionality
call vimroam#u#reload_regexes_custom()


" FIXME it now does not make sense to pretend there is a single syntax "vimroam"
let b:current_syntax='vimroam'


" Include: Code: EMBEDDED syntax setup -> base.vim
let s:nested = vimroam#vars#get_wikilocal('nested_syntaxes')
if vimroam#vars#get_wikilocal('automatic_nested_syntaxes')
  let s:nested = extend(s:nested, vimroam#base#detect_nested_syntax(), 'keep')
endif
if !empty(s:nested)
  for [s:hl_syntax, s:vim_syntax] in items(s:nested)
    call vimroam#base#nested_syntax(s:vim_syntax,
          \ vimroam#vars#get_syntaxlocal('rxPreStart').'\%(.*[[:blank:][:punct:]]\)\?'.
          \ s:hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
          \ vimroam#vars#get_syntaxlocal('rxPreEnd'), 'VimRoamPre')
  endfor
endif

" LaTex: Load
if !empty(globpath(&runtimepath, 'syntax/tex.vim'))
  execute 'syntax include @textGrouptex syntax/tex.vim'
endif
if !empty(globpath(&runtimepath, 'after/syntax/tex.vim'))
  execute 'syntax include @textGrouptex after/syntax/tex.vim'
endif

" LaTeX: Block
call vimroam#base#nested_syntax('tex',
      \ vimroam#vars#get_syntaxlocal('rxMathStart').'\%(.*[[:blank:][:punct:]]\)\?'.
      \ '\%([[:blank:][:punct:]].*\)\?',
      \ vimroam#vars#get_syntaxlocal('rxMathEnd'), 'VimRoamMath')

" LaTeX: Inline
for u in syntax_dic.typeface.eq
  execute 'syntax region textSniptex  matchgroup=texSnip'
        \ . ' start="'.u[0].'" end="'.u[1].'"'
        \ . ' contains=@texMathZoneGroup'
        \ . ' keepend oneline '. b:vimroam_syntax_concealends
endfor

" Emoji: :dog: (after tags to take precedence, after nested to not be reset)
if and(vimroam#vars#get_global('emoji_enable'), 1) != 0 && has('conceal')
  call vimroam#emoji#apply_conceal()
  exe 'syn iskeyword '.&iskeyword.',-,:'
endif


syntax spell toplevel
