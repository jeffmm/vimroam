" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" VimRoam filetype plugin file
" Home: https://github.com/jeffmm/vimroam/


" Cause: load only onces per buffer
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

if vimroam#vars#get_global('conceallevel') && exists('+conceallevel')
  let &l:conceallevel = vimroam#vars#get_global('conceallevel')
endif

" This is for GOTO FILE: gf
execute 'setlocal suffixesadd='.vimroam#vars#get_wikilocal('ext')
setlocal isfname-=[,]

exe 'setlocal tags+=' . escape(vimroam#tags#metadata_file_path(), ' \|"')


" Help for omnicompletion
function! Complete_wikifiles(findstart, base) abort
  " s:line_context = link | tag | ''
  if a:findstart == 1
    " Find line context
    " Called: first time
    let column = col('.')-2
    let line = getline('.')[:column]

    " Check Link:
    " -- WikiLink
    let startoflink = match(line, '\[\[\zs[^\\[\]]*$')
    if startoflink != -1
      let s:line_context = 'link'
      return startoflink
    endif
    " -- WebLink
    if vimroam#vars#get_wikilocal('syntax') ==? 'markdown'
      let startofinlinelink = match(line, '\[.*\](\zs[^)]*$')
      if startofinlinelink != -1
        let s:line_context = 'link'
        return startofinlinelink
      endif
    endif

    " Check Tag:
    let tf = vimroam#vars#get_syntaxlocal('tag_format')
    let startoftag = match(line, tf.pre_mark . '\zs' . tf.in . '*$')
    if startoftag != -1
      let s:line_context = 'tag'
      return startoftag
    endif

    " Nothing can do ...
    let s:line_context = ''
    return -1
  else
    " Completion works for wikilinks/anchors, and for tags. s:line_content
    " tells us which string came before a:base. There seems to be no easier
    " solution, because calling col('.') here returns garbage.
    if s:line_context ==? ''
      return []
    elseif s:line_context ==# 'tag'
      " Look Tags: completion
      let tags = vimroam#tags#get_tags()
      if a:base !=? ''
        call filter(tags,
            \ 'v:val[:' . (len(a:base)-1) . "] == '" . substitute(a:base, "'", "''", '') . "'" )
      endif
      return tags
    elseif a:base !~# '#'
      " Look Wiki: files
      if a:base =~# '\m^wiki\d\+:'
        let wikinumber = eval(matchstr(a:base, '\m^wiki\zs\d\+'))
        if wikinumber >= vimroam#vars#number_of_wikis()
          return []
        endif
        let prefix = matchstr(a:base, '\m^wiki\d\+:\zs.*')
        let scheme = matchstr(a:base, '\m^wiki\d\+:\ze')
      elseif a:base =~# '^diary:'
        let wikinumber = -1
        let prefix = matchstr(a:base, '^diary:\zs.*')
        let scheme = matchstr(a:base, '^diary:\ze')
      else " current wiki
        let wikinumber = vimroam#vars#get_bufferlocal('wiki_nr')
        let prefix = a:base
        let scheme = ''
      endif

      let links = vimroam#base#get_wikilinks(wikinumber, 1, '')
      let result = []
      for wikifile in links
        if wikifile =~ '^'.vimroam#u#escape(prefix)
          call add(result, scheme . wikifile)
        endif
      endfor
      return result

    else
      " Look Anchor: in the given wikifile

      let segments = split(a:base, '#', 1)
      let given_wikifile = segments[0] ==? '' ? expand('%:t:r') : segments[0]
      let link_infos = vimroam#base#resolve_link(given_wikifile.'#')
      let wikifile = link_infos.filename
      let syntax = vimroam#vars#get_wikilocal('syntax', link_infos.index)
      let anchors = vimroam#base#get_anchors(wikifile, syntax)

      let filtered_anchors = []
      let given_anchor = join(segments[1:], '#')
      for anchor in anchors
        if anchor =~# '^'.vimroam#u#escape(given_anchor)
          call add(filtered_anchors, segments[0].'#'.anchor)
        endif
      endfor
      return filtered_anchors

    endif
  endif
endfunction

" Set completion
setlocal omnifunc=Complete_wikifiles
if and(vimroam#vars#get_global('emoji_enable'), 2) != 0
      \ && &completefunc ==# ''
  set completefunc=vimroam#emoji#complete
endif


" Declare settings necessary for the automatic formatting of lists
" ------------------------------------------------
setlocal autoindent
setlocal nosmartindent
setlocal nocindent

" Set comments: to insert and format 'comments' or cheat
" Used to break blockquote prepending one on each new line (see: #915)
" B like blank character follow
" blockquotes
let comments = 'b:>'
for bullet in vimroam#vars#get_syntaxlocal('bullet_types')
  " task list
  for point in vimroam#vars#get_wikilocal('listsyms_list')
        \ + [vimroam#vars#get_wikilocal('listsym_rejected')]
    let comments .= ',fb:' . bullet . ' [' . point . ']'
  endfor
  " list
  let comments .= ',fb:' . bullet
endfor
let &l:comments = comments

" Set format options (:h fo-table)
" Disable autocomment because, vimroam does it better
setlocal formatoptions-=r
setlocal formatoptions-=o
setlocal formatoptions-=2
" Autowrap with leading comment
setlocal formatoptions+=c
" Do not wrap if line was already long
setlocal formatoptions+=l
" AutoWrap inteligent with lists
setlocal formatoptions+=n
let &formatlistpat = vimroam#vars#get_wikilocal('rxListItem')
" Used to join 'commented' lines (blockquote, list) (see: #915)
if v:version > 703
  setlocal formatoptions+=j
endif

" Set commentstring %%%s
let &l:commentstring = vimroam#vars#get_wikilocal('commentstring')


" ------------------------------------------------
" Folding stuff
" ------------------------------------------------

" Get fold level for a list
function! VimRoamFoldListLevel(lnum) abort
  return vimroam#lst#fold_level(a:lnum)
endfunction


" Get fold level for 1. line number
function! VimRoamFoldLevel(lnum) abort
  let line = getline(a:lnum)

  " Header/section folding...
  if line =~# vimroam#vars#get_syntaxlocal('rxHeader') && !vimroam#u#is_codeblock(a:lnum)
    return '>'.vimroam#u#count_first_sym(line)
  " Code block folding...
  elseif line =~# vimroam#vars#get_syntaxlocal('rxPreStart')
    return 'a1'
  elseif line =~# vimroam#vars#get_syntaxlocal('rxPreEnd')
    return 's1'
  else
    return '='
  endif
endfunction


" Declare constants used by VimRoamFoldText
" use \u2026 and \u21b2 (or \u2424) if enc=utf-8 to save screen space
let s:ellipsis = (&encoding ==? 'utf-8') ? "\u2026" : '...'
let s:ell_len = strlen(s:ellipsis)
let s:newline = (&encoding ==? 'utf-8') ? "\u21b2 " : '  '
let s:tolerance = 5


" unused: too naive
function! s:shorten_text_simple(text, len) abort
  let spare_len = a:len - len(a:text)
  return (spare_len>=0) ? [a:text,spare_len] : [a:text[0:a:len].s:ellipsis, -1]
endfunction


" Shorten text
" Called: by VimRoamFoldText
" s:shorten_text(text, len) = [string, spare] with "spare" = len-strlen(string)
" for long enough "text", the string's length is within s:tolerance of "len"
" (so that -s:tolerance <= spare <= s:tolerance, "string" ends with s:ellipsis)
" Return: [string, spare]
function! s:shorten_text(text, len) abort
  " strlen() returns lenght in bytes, not in characters, so we'll have to do a
  " trick here -- replace all non-spaces with dot, calculate lengths and
  " indexes on it, then use original string to break at selected index.
  let text_pattern = substitute(a:text, '\m\S', '.', 'g')
  let spare_len = a:len - strlen(text_pattern)
  if (spare_len + s:tolerance >= 0)
    return [a:text, spare_len]
  endif
  " try to break on a space; assumes a:len-s:ell_len >= s:tolerance
  let newlen = a:len - s:ell_len
  let idx = strridx(text_pattern, ' ', newlen + s:tolerance)
  let break_idx = (idx + s:tolerance >= newlen) ? idx : newlen
  return [matchstr(a:text, '\m^.\{'.break_idx.'\}').s:ellipsis, newlen - break_idx]
endfunction


" Fold text chapter
function! VimRoamFoldText() abort
  let line = getline(v:foldstart)
  let main_text = substitute(line, '^\s*', repeat(' ',indent(v:foldstart)), '')
  let fold_len = v:foldend - v:foldstart + 1
  let len_text = ' ['.fold_len.'] '
  if line !~# vimroam#vars#get_syntaxlocal('rxPreStart')
    let [main_text, spare_len] = s:shorten_text(main_text, 50)
    return main_text.len_text
  else
    " fold-text for code blocks: use one or two of the starting lines
    let [main_text, spare_len] = s:shorten_text(main_text, 24)
    let line1 = substitute(getline(v:foldstart+1), '^\s*', ' ', '')
    let [content_text, spare_len] = s:shorten_text(line1, spare_len+20)
    if spare_len > s:tolerance && fold_len > 3
      let line2 = substitute(getline(v:foldstart+2), '^\s*', s:newline, '')
      let [more_text, spare_len] = s:shorten_text(line2, spare_len+12)
      let content_text .= more_text
    endif
    return main_text.len_text.content_text
  endif
endfunction



" ------------------------------------------------
" Commands
" ------------------------------------------------

command! -buffer VimRoam2HTML
      \ if filewritable(expand('%')) | silent noautocmd w | endif
      \ <bar>
      \ let res = vimroam#html#Wiki2HTML(
      \   expand(vimroam#vars#get_wikilocal('path_html')), expand('%'))
      \ <bar>
      \ if res != '' | call vimroam#u#echo('HTML conversion is done, output: '
      \      . expand(vimroam#vars#get_wikilocal('path_html'))) | endif

command! -buffer VimRoam2HTMLBrowse
      \ if filewritable(expand('%')) | silent noautocmd w | endif
      \ <bar>
      \ call vimroam#base#system_open_link(vimroam#html#Wiki2HTML(
      \         expand(vimroam#vars#get_wikilocal('path_html')),
      \         expand('%')))

command! -buffer -bang VimRoamAll2HTML
      \ call vimroam#html#WikiAll2HTML(expand(vimroam#vars#get_wikilocal('path_html')), <bang>0)

command! -buffer VimRoamRss call vimroam#html#diary_rss()

command! -buffer VimRoamTOC call vimroam#base#table_of_contents(1)

command! -buffer VimRoamNextTask call vimroam#base#find_next_task()
command! -buffer VimRoamNextLink call vimroam#base#find_next_link()
command! -buffer VimRoamPrevLink call vimroam#base#find_prev_link()
command! -buffer VimRoamDeleteFile call vimroam#base#delete_link()
command! -buffer VimRoamDeleteLink
      \ call vimroam#base#deprecate("VimRoamDeleteLink", "VimRoamDeleteFile") |
      \ call vimroam#base#delete_link()
command! -buffer -nargs=? -complete=customlist,vimroam#base#complete_file
      \ VimRoamRenameFile call vimroam#base#rename_link(<f-args>)
command! -buffer VimRoamRenameLink
      \ call vimroam#base#deprecate("VimRoamRenameLink", "VimRoamRenameFile") |
      \ call vimroam#base#rename_link()
command! -buffer VimRoamFollowLink call vimroam#base#follow_link('nosplit', 0, 1)
command! -buffer VimRoamGoBackLink call vimroam#base#go_back_link()
command! -buffer -nargs=* VimRoamSplitLink call vimroam#base#follow_link('hsplit', <f-args>)
command! -buffer -nargs=* VimRoamVSplitLink call vimroam#base#follow_link('vsplit', <f-args>)

" JMM -- New functions using FZF search
" Create function for inserting a link to another note
command! -bang VimRoamInsertLink call vimroam#base#insert_link(<bang>0)

command! -buffer -nargs=? VimRoamNormalizeLink call vimroam#base#normalize_link(<f-args>)

command! -buffer VimRoamTabnewLink call vimroam#base#follow_link('tab', 0, 1)

command! -buffer -nargs=? VimRoamGenerateLinks call vimroam#base#generate_links(1, <f-args>)

command! -buffer -nargs=0 VimRoamBacklinks call vimroam#base#backlinks()
command! -buffer -nargs=0 VWB call vimroam#base#backlinks()

command! -buffer -nargs=* VimRoamSearch call vimroam#base#search(<q-args>)
command! -buffer -nargs=* VWS call vimroam#base#search(<q-args>)

command! -buffer -nargs=* -complete=customlist,vimroam#base#complete_links_escaped
      \ VimRoamGoto call vimroam#base#goto(<f-args>)

command! -buffer -range VimRoamCheckLinks call vimroam#base#check_links(<range>, <line1>, <line2>)

" list commands
command! -buffer -nargs=+ VimRoamReturn call <SID>CR(<f-args>)
command! -buffer -range -nargs=1 VimRoamChangeSymbolTo
      \ call vimroam#lst#change_marker(<line1>, <line2>, <f-args>, 'n')
command! -buffer -range -nargs=1 VimRoamListChangeSymbolI
      \ call vimroam#lst#change_marker(<line1>, <line2>, <f-args>, 'i')
command! -buffer -nargs=1 VimRoamChangeSymbolInListTo
      \ call vimroam#lst#change_marker_in_list(<f-args>)
command! -buffer -range VimRoamToggleListItem call vimroam#lst#toggle_cb(<line1>, <line2>)
command! -buffer -range VimRoamToggleRejectedListItem
      \ call vimroam#lst#toggle_rejected_cb(<line1>, <line2>)
command! -buffer -range VimRoamIncrementListItem call vimroam#lst#increment_cb(<line1>, <line2>)
command! -buffer -range VimRoamDecrementListItem call vimroam#lst#decrement_cb(<line1>, <line2>)
command! -buffer -range -nargs=+ VimRoamListChangeLvl
      \ call vimroam#lst#change_level(<line1>, <line2>, <f-args>)
command! -buffer -range VimRoamRemoveSingleCB call vimroam#lst#remove_cb(<line1>, <line2>)
command! -buffer VimRoamRemoveCBInList call vimroam#lst#remove_cb_in_list()
command! -buffer VimRoamRenumberList call vimroam#lst#adjust_numbered_list()
command! -buffer VimRoamRenumberAllLists call vimroam#lst#adjust_whole_buffer()
command! -buffer VimRoamListToggle call vimroam#lst#toggle_list_item()
command! -buffer -range VimRoamRemoveDone call vimroam#lst#remove_done(1, "<range>", <line1>, <line2>)

" table commands
command! -buffer -nargs=* VimRoamTable call vimroam#tbl#create(<f-args>)
command! -buffer -nargs=? VimRoamTableAlignQ call vimroam#tbl#align_or_cmd('gqq', <f-args>)
command! -buffer -nargs=? VimRoamTableAlignW call vimroam#tbl#align_or_cmd('gww', <f-args>)
command! -buffer VimRoamTableMoveColumnLeft call vimroam#tbl#move_column_left()
command! -buffer VimRoamTableMoveColumnRight call vimroam#tbl#move_column_right()

" diary commands
command! -buffer VimRoamDiaryNextDay call vimroam#diary#goto_next_day()
command! -buffer VimRoamDiaryPrevDay call vimroam#diary#goto_prev_day()

" tags commands
command! -buffer -bang VimRoamRebuildTags call vimroam#tags#update_tags(1, '<bang>')
command! -buffer -nargs=* -complete=custom,vimroam#tags#complete_tags
      \ VimRoamSearchTags VimRoamSearch /:<args>:/
command! -buffer -nargs=* -complete=custom,vimroam#tags#complete_tags
      \ VimRoamGenerateTagLinks call vimroam#tags#generate_tags(1, <f-args>)
command! -buffer -nargs=* -complete=custom,vimroam#tags#complete_tags
      \ VimRoamGenerateTags
      \ call vimroam#base#deprecate("VimRoamGenerateTags", "VimRoamGenerateTagLinks") |
      \ call vimroam#tags#generate_tags(1, <f-args>)

command! -buffer VimRoamPasteUrl call vimroam#html#PasteUrl(expand('%:p'))
command! -buffer VimRoamCatUrl call vimroam#html#CatUrl(expand('%:p'))

command! -buffer -nargs=* -complete=custom,vimroam#base#complete_colorize
      \ VimRoamColorize call vimroam#base#colorize(<f-args>)

" ------------------------------------------------
" Keybindings
" ------------------------------------------------

" mouse mappings
if str2nr(vimroam#vars#get_global('key_mappings').mouse)
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  nnoremap <silent><buffer> <2-LeftMouse>
        \ :call vimroam#base#follow_link('nosplit', 0, 1, "\<lt>2-LeftMouse>")<CR>
  nnoremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimRoamSplitLink<CR>
  nnoremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimRoamVSplitLink<CR>
  nnoremap <silent><buffer> <RightMouse><LeftMouse> :VimRoamGoBackLink<CR>
endif

" <Plug> HTML definitions
nnoremap <script><buffer> <Plug>VimRoam2HTML :VimRoam2HTML<CR>
nnoremap <script><buffer> <Plug>VimRoam2HTMLBrowse :VimRoam2HTMLBrowse<CR>

" default HTML key mappings
if str2nr(vimroam#vars#get_global('key_mappings').html)
  call vimroam#u#map_key('n', vimroam#vars#get_global('map_prefix').'h', '<Plug>VimRoam2HTML')
  call vimroam#u#map_key('n', vimroam#vars#get_global('map_prefix').'hh', '<Plug>VimRoam2HTMLBrowse')
endif

" <Plug> links definitions
inoremap <silent><script><buffer> <Plug>VimRoamInsertLink
    \ <ESC>:VimRoamInsertLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamFollowLink
    \ :VimRoamFollowLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamSplitLink
    \ :VimRoamSplitLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamVSplitLink
    \ :VimRoamVSplitLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamNormalizeLink
    \ :VimRoamNormalizeLink 0<CR>
vnoremap <silent><script><buffer> <Plug>VimRoamNormalizeLinkVisual
    \ :<C-U>VimRoamNormalizeLink 1<CR>
vnoremap <silent><script><buffer> <Plug>VimRoamNormalizeLinkVisualCR
    \ :<C-U>VimRoamNormalizeLink 1<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamTabnewLink
    \ :VimRoamTabnewLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamGoBackLink
    \ :VimRoamGoBackLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamNextLink
    \ :VimRoamNextLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamPrevLink
    \ :VimRoamPrevLink<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamGoto
    \ :VimRoamGoto<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamDeleteFile
    \ :VimRoamDeleteFile<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamRenameFile
    \ :VimRoamRenameFile<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamDiaryNextDay
    \ :VimRoamDiaryNextDay<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamDiaryPrevDay
    \ :VimRoamDiaryPrevDay<CR>
"
" default links key mappings
if str2nr(vimroam#vars#get_global('key_mappings').links)
  call vimroam#u#map_key('n', '<CR>', '<Plug>VimRoamFollowLink')
  call vimroam#u#map_key('n', '<S-CR>', '<Plug>VimRoamSplitLink')
  call vimroam#u#map_key('n', '<C-CR>', '<Plug>VimRoamVSplitLink')
  call vimroam#u#map_key('n', '+', '<Plug>VimRoamNormalizeLink')
  call vimroam#u#map_key('v', '+', '<Plug>VimRoamNormalizeLinkVisual')
  call vimroam#u#map_key('v', '<CR>', '<Plug>VimRoamNormalizeLinkVisualCR')
  call vimroam#u#map_key('n', '<D-CR>', '<Plug>VimRoamTabnewLink')
  call vimroam#u#map_key('n', '<C-S-CR>', '<Plug>VimRoamTabnewLink', 1)
  call vimroam#u#map_key('n', '<BS>', '<Plug>VimRoamGoBackLink')
  call vimroam#u#map_key('n', vimroam#vars#get_global('map_prefix').'D', '<Plug>VimRoamDeleteFile')
  call vimroam#u#map_key('n', vimroam#vars#get_global('map_prefix').'R', '<Plug>VimRoamRenameFile')
  call vimroam#u#map_key('n', '-', '<Plug>VimRoamDiaryNextDay')
  call vimroam#u#map_key('n', '=', '<Plug>VimRoamDiaryPrevDay')
  call vimroam#u#map_key('i', '[]', '<Plug>VimRoamInsertLink')
endif

" <Plug> lists definitions
nnoremap <silent><script><buffer> <Plug>VimRoamNextTask
    \ :VimRoamNextTask<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamToggleListItem
    \ :VimRoamToggleListItem<CR>
vnoremap <silent><script><buffer> <Plug>VimRoamToggleListItem
    \ :VimRoamToggleListItem<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamToggleRejectedListItem
    \ :VimRoamToggleRejectedListItem<CR>
vnoremap <silent><script><buffer> <Plug>VimRoamToggleRejectedListItem
    \ :VimRoamToggleRejectedListItem<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamIncrementListItem
    \ :VimRoamIncrementListItem<CR>
vnoremap <silent><script><buffer> <Plug>VimRoamIncrementListItem
    \ :VimRoamIncrementListItem<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamDecrementListItem
    \ :VimRoamDecrementListItem<CR>
vnoremap <silent><script><buffer> <Plug>VimRoamDecrementListItem
    \ :VimRoamDecrementListItem<CR>
inoremap <silent><script><buffer> <Plug>VimRoamDecreaseLvlSingleItem
    \ <C-O>:VimRoamListChangeLvl decrease 0<CR>
inoremap <silent><script><buffer> <Plug>VimRoamIncreaseLvlSingleItem
    \ <C-O>:VimRoamListChangeLvl increase 0<CR>
inoremap <silent><script><buffer> <Plug>VimRoamListNextSymbol
    \ <C-O>:VimRoamListChangeSymbolI next<CR>
inoremap <silent><script><buffer> <Plug>VimRoamListPrevSymbol
    \ <C-O>:VimRoamListChangeSymbolI prev<CR>
inoremap <silent><script><buffer> <Plug>VimRoamListToggle
    \ <Esc>:VimRoamListToggle<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamRenumberList
    \ :VimRoamRenumberList<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamRenumberAllLists
    \ :VimRoamRenumberAllLists<CR>
noremap <silent><script><buffer> <Plug>VimRoamDecreaseLvlSingleItem
    \ :VimRoamListChangeLvl decrease 0<CR>
noremap <silent><script><buffer> <Plug>VimRoamIncreaseLvlSingleItem
    \ :VimRoamListChangeLvl increase 0<CR>
noremap <silent><script><buffer> <Plug>VimRoamDecreaseLvlWholeItem
    \ :VimRoamListChangeLvl decrease 1<CR>
noremap <silent><script><buffer> <Plug>VimRoamIncreaseLvlWholeItem
    \ :VimRoamListChangeLvl increase 1<CR>
noremap <silent><script><buffer> <Plug>VimRoamRemoveSingleCB
    \ :VimRoamRemoveSingleCB<CR>
noremap <silent><script><buffer> <Plug>VimRoamRemoveCBInList
    \ :VimRoamRemoveCBInList<CR>
nnoremap <silent><buffer> <Plug>VimRoamListo
    \ :<C-U>call vimroam#u#count_exe('call vimroam#lst#kbd_o()')<CR>
nnoremap <silent><buffer> <Plug>VimRoamListO
    \ :<C-U>call vimroam#u#count_exe('call vimroam#lst#kbd_O()')<CR>

" default lists key mappings
if str2nr(vimroam#vars#get_global('key_mappings').lists)
  call vimroam#u#map_key('n', 'gnt', '<Plug>VimRoamNextTask')
  call vimroam#u#map_key('n', '<C-Space>', '<Plug>VimRoamToggleListItem')
  call vimroam#u#map_key('v', '<C-Space>', '<Plug>VimRoamToggleListItem')
  if has('unix')
    call vimroam#u#map_key('n', '<C-@>', '<Plug>VimRoamToggleListItem')
    call vimroam#u#map_key('v', '<C-@>', '<Plug>VimRoamToggleListItem')
  endif
  call vimroam#u#map_key('n', 'glx', '<Plug>VimRoamToggleRejectedListItem')
  call vimroam#u#map_key('v', 'glx', '<Plug>VimRoamToggleRejectedListItem', 1)
  call vimroam#u#map_key('n', 'gln', '<Plug>VimRoamIncrementListItem')
  call vimroam#u#map_key('v', 'gln', '<Plug>VimRoamIncrementListItem', 1)
  call vimroam#u#map_key('n', 'glp', '<Plug>VimRoamDecrementListItem')
  call vimroam#u#map_key('v', 'glp', '<Plug>VimRoamDecrementListItem', 1)
  call vimroam#u#map_key('i', '<C-D>', '<Plug>VimRoamDecreaseLvlSingleItem')
  call vimroam#u#map_key('i', '<C-T>', '<Plug>VimRoamIncreaseLvlSingleItem')
  call vimroam#u#map_key('n', 'glh', '<Plug>VimRoamDecreaseLvlSingleItem', 1)
  call vimroam#u#map_key('n', 'gll', '<Plug>VimRoamIncreaseLvlSingleItem', 1)
  call vimroam#u#map_key('n', 'gLh', '<Plug>VimRoamDecreaseLvlWholeItem')
  call vimroam#u#map_key('n', 'gLH', '<Plug>VimRoamDecreaseLvlWholeItem', 1)
  call vimroam#u#map_key('n', 'gLl', '<Plug>VimRoamIncreaseLvlWholeItem')
  call vimroam#u#map_key('n', 'gLL', '<Plug>VimRoamIncreaseLvlWholeItem', 1)
  call vimroam#u#map_key('i', '<C-L><C-J>', '<Plug>VimRoamListNextSymbol')
  call vimroam#u#map_key('i', '<C-L><C-K>', '<Plug>VimRoamListPrevSymbol')
  call vimroam#u#map_key('i', '<C-L><C-M>', '<Plug>VimRoamListToggle')
  call vimroam#u#map_key('n', 'glr', '<Plug>VimRoamRenumberList')
  call vimroam#u#map_key('n', 'gLr', '<Plug>VimRoamRenumberAllLists')
  call vimroam#u#map_key('n', 'gLR', '<Plug>VimRoamRenumberAllLists', 1)
  call vimroam#u#map_key('n', 'gl', '<Plug>VimRoamRemoveSingleCB')
  call vimroam#u#map_key('n', 'gL', '<Plug>VimRoamRemoveCBInList')
  call vimroam#u#map_key('n', 'o', '<Plug>VimRoamListo')
  call vimroam#u#map_key('n', 'O', '<Plug>VimRoamListO')

  " Handle case of existing VimRoamReturn mappings outside the <Plug> definition
  " Note: Avoid interfering with popup/completion menu if it's active (#813)
  if maparg('<CR>', 'i') !~# '.*VimRoamReturn*.'
    if has('patch-7.3.489')
      " expand iabbrev on enter
      inoremap <expr><silent><buffer> <CR> pumvisible() ? '<CR>' : '<C-]><Esc>:VimRoamReturn 1 5<CR>'
    else
      inoremap <expr><silent><buffer> <CR> pumvisible() ? '<CR>' : '<Esc>:VimRoamReturn 1 5<CR>'
    endif
  endif
  if  maparg('<S-CR>', 'i') !~# '.*VimRoamReturn*.'
    inoremap <expr><silent><buffer> <S-CR> pumvisible() ? '<CR>' : '<Esc>:VimRoamReturn 2 2<CR>'
  endif

  " change symbol for bulleted lists
  for s:char in vimroam#vars#get_syntaxlocal('bullet_types')
    if !hasmapto(':VimRoamChangeSymbolTo '.s:char.'<CR>')
      exe 'noremap <silent><buffer> gl'.s:char.' :VimRoamChangeSymbolTo '.s:char.'<CR>'
    endif
    if !hasmapto(':VimRoamChangeSymbolInListTo '.s:char.'<CR>')
      exe 'noremap <silent><buffer> gL'.s:char.' :VimRoamChangeSymbolInListTo '.s:char.'<CR>'
    endif
  endfor

  " change symbol for numbered lists
  for s:typ in vimroam#vars#get_syntaxlocal('number_types')
    if !hasmapto(':VimRoamChangeSymbolTo '.s:typ.'<CR>')
      exe 'noremap <silent><buffer> gl'.s:typ[0].' :VimRoamChangeSymbolTo '.s:typ.'<CR>'
    endif
    if !hasmapto(':VimRoamChangeSymbolInListTo '.s:typ.'<CR>')
      exe 'noremap <silent><buffer> gL'.s:typ[0].' :VimRoamChangeSymbolInListTo '.s:typ.'<CR>'
    endif
  endfor

  " insert items in a list using langmap characters (see :h langmap)
  if !empty(&langmap)
    " Valid only if langmap is a comma separated pairs of chars
    let s:l_o = matchstr(&langmap, '\C,\zs.\zeo,')
    if s:l_o
      exe 'nnoremap <silent><buffer> '.s:l_o.' :call vimroam#lst#kbd_o()<CR>a'
    endif

    let s:l_O = matchstr(&langmap, '\C,\zs.\zeO,')
    if s:l_O
      exe 'nnoremap <silent><buffer> '.s:l_O.' :call vimroam#lst#kbd_O()<CR>a'
    endif
  endif
endif

function! s:CR(normal, just_mrkr) abort
  let res = vimroam#tbl#kbd_cr()
  if res !=? ''
    exe 'normal! ' . res . "\<Right>"
    startinsert
    return
  endif
  call vimroam#lst#kbd_cr(a:normal, a:just_mrkr)
endfunction

" insert mode table mappings
inoremap <silent><buffer><expr> <Plug>VimRoamTableNextCell
    \ vimroam#tbl#kbd_tab()
inoremap <silent><buffer><expr> <Plug>VimRoamTablePrevCell
    \ vimroam#tbl#kbd_shift_tab()
if str2nr(vimroam#vars#get_global('key_mappings').table_mappings)
  call vimroam#u#map_key('i', '<Tab>', '<Plug>VimRoamTableNextCell')
  call vimroam#u#map_key('i', '<S-Tab>', '<Plug>VimRoamTablePrevCell')
endif

" <Plug> table formatting definitions
nnoremap <silent><buffer> <Plug>VimRoamTableAlignQ
    \ :VimRoamTableAlignQ<CR>
nnoremap <silent><buffer> <Plug>VimRoamTableAlignQ1
    \ :VimRoamTableAlignQ 2<CR>
nnoremap <silent><buffer> <Plug>VimRoamTableAlignW
    \ :VimRoamTableAlignW<CR>
nnoremap <silent><buffer> <Plug>VimRoamTableAlignW1
    \ :VimRoamTableAlignW 2<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamTableMoveColumnLeft
    \ :VimRoamTableMoveColumnLeft<CR>
nnoremap <silent><script><buffer> <Plug>VimRoamTableMoveColumnRight
    \ :VimRoamTableMoveColumnRight<CR>

" default table formatting key mappings
if str2nr(vimroam#vars#get_global('key_mappings').table_format)
  call vimroam#u#map_key('n', 'gqq', '<Plug>VimRoamTableAlignQ')
  call vimroam#u#map_key('n', 'gq1', '<Plug>VimRoamTableAlignQ1')
  call vimroam#u#map_key('n', 'gww', '<Plug>VimRoamTableAlignW')
  call vimroam#u#map_key('n', 'gw1', '<Plug>VimRoamTableAlignW1')
  call vimroam#u#map_key('n', '<A-Left>', '<Plug>VimRoamTableMoveColumnLeft')
  call vimroam#u#map_key('n', '<A-Right>', '<Plug>VimRoamTableMoveColumnRight')
endif

" <Plug> text object definitions
onoremap <silent><buffer> <Plug>VimRoamTextObjHeader
    \ :<C-U>call vimroam#base#TO_header(0, 0, v:count1)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjHeaderV
    \ :<C-U>call vimroam#base#TO_header(0, 0, v:count1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjHeaderContent
    \ :<C-U>call vimroam#base#TO_header(1, 0, v:count1)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjHeaderContentV
    \ :<C-U>call vimroam#base#TO_header(1, 0, v:count1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjHeaderSub
    \ :<C-U>call vimroam#base#TO_header(0, 1, v:count1)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjHeaderSubV
    \ :<C-U>call vimroam#base#TO_header(0, 1, v:count1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjHeaderSubContent
    \ :<C-U>call vimroam#base#TO_header(1, 1, v:count1)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjHeaderSubContentV
    \ :<C-U>call vimroam#base#TO_header(1, 1, v:count1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjTableCell
    \ :<C-U>call vimroam#base#TO_table_cell(0, 0)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjTableCellV
    \ :<C-U>call vimroam#base#TO_table_cell(0, 1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjTableCellInner
    \ :<C-U>call vimroam#base#TO_table_cell(1, 0)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjTableCellInnerV
    \ :<C-U>call vimroam#base#TO_table_cell(1, 1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjColumn
    \ :<C-U>call vimroam#base#TO_table_col(0, 0)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjColumnV
    \ :<C-U>call vimroam#base#TO_table_col(0, 1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjColumnInner
    \ :<C-U>call vimroam#base#TO_table_col(1, 0)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjColumnInnerV
    \ :<C-U>call vimroam#base#TO_table_col(1, 1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjListChildren
    \ :<C-U>call vimroam#lst#TO_list_item(0, 0)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjListChildrenV
    \ :<C-U>call vimroam#lst#TO_list_item(0, 1)<CR>
onoremap <silent><buffer> <Plug>VimRoamTextObjListSingle
    \ :<C-U>call vimroam#lst#TO_list_item(1, 0)<CR>
vnoremap <silent><buffer> <Plug>VimRoamTextObjListSingleV
    \ :<C-U>call vimroam#lst#TO_list_item(1, 1)<CR>

" default text object key mappings
if str2nr(vimroam#vars#get_global('key_mappings').text_objs)
  call vimroam#u#map_key('o', 'ah', '<Plug>VimRoamTextObjHeader')
  call vimroam#u#map_key('v', 'ah', '<Plug>VimRoamTextObjHeaderV')
  call vimroam#u#map_key('o', 'ih', '<Plug>VimRoamTextObjHeaderContent')
  call vimroam#u#map_key('v', 'ih', '<Plug>VimRoamTextObjHeaderContentV')
  call vimroam#u#map_key('o', 'aH', '<Plug>VimRoamTextObjHeaderSub')
  call vimroam#u#map_key('v', 'aH', '<Plug>VimRoamTextObjHeaderSubV')
  call vimroam#u#map_key('o', 'iH', '<Plug>VimRoamTextObjHeaderSubContent')
  call vimroam#u#map_key('v', 'iH', '<Plug>VimRoamTextObjHeaderSubContentV')
  call vimroam#u#map_key('o', 'a\', '<Plug>VimRoamTextObjTableCell')
  call vimroam#u#map_key('v', 'a\', '<Plug>VimRoamTextObjTableCellV')
  call vimroam#u#map_key('o', 'i\', '<Plug>VimRoamTextObjTableCellInner')
  call vimroam#u#map_key('v', 'i\', '<Plug>VimRoamTextObjTableCellInnerV')
  call vimroam#u#map_key('o', 'ac', '<Plug>VimRoamTextObjColumn')
  call vimroam#u#map_key('v', 'ac', '<Plug>VimRoamTextObjColumnV')
  call vimroam#u#map_key('o', 'ic', '<Plug>VimRoamTextObjColumnInner')
  call vimroam#u#map_key('v', 'ic', '<Plug>VimRoamTextObjColumnInnerV')
  call vimroam#u#map_key('o', 'al', '<Plug>VimRoamTextObjListChildren')
  call vimroam#u#map_key('v', 'al', '<Plug>VimRoamTextObjListChildrenV')
  call vimroam#u#map_key('o', 'il', '<Plug>VimRoamTextObjListSingle')
  call vimroam#u#map_key('v', 'il', '<Plug>VimRoamTextObjListSingleV')
endif

" <Plug> header definitions
nnoremap <silent><buffer> <Plug>VimRoamAddHeaderLevel
      \ :<C-U>call vimroam#base#AddHeaderLevel(v:count)<CR>
nnoremap <silent><buffer> <Plug>VimRoamRemoveHeaderLevel
      \ :<C-U>call vimroam#base#RemoveHeaderLevel(v:count)<CR>
nnoremap <silent><buffer> <Plug>VimRoamGoToParentHeader
      \ :<C-u>call vimroam#base#goto_parent_header()<CR>
nnoremap <silent><buffer> <Plug>VimRoamGoToNextHeader
      \ :<C-u>call vimroam#base#goto_next_header()<CR>
nnoremap <silent><buffer> <Plug>VimRoamGoToPrevHeader
      \ :<C-u>call vimroam#base#goto_prev_header()<CR>
nnoremap <silent><buffer> <Plug>VimRoamGoToNextSiblingHeader
      \ :<C-u>call vimroam#base#goto_sibling(+1)<CR>
nnoremap <silent><buffer> <Plug>VimRoamGoToPrevSiblingHeader
      \ :<C-u>call vimroam#base#goto_sibling(-1)<CR>

" default header key mappings
if str2nr(vimroam#vars#get_global('key_mappings').headers)
  call vimroam#u#map_key('n', '=', '<Plug>VimRoamAddHeaderLevel')
  call vimroam#u#map_key('n', '-', '<Plug>VimRoamRemoveHeaderLevel')
  call vimroam#u#map_key('n', ']u', '<Plug>VimRoamGoToParentHeader')
  call vimroam#u#map_key('n', '[u', '<Plug>VimRoamGoToParentHeader', 1)
  call vimroam#u#map_key('n', ']]', '<Plug>VimRoamGoToNextHeader')
  call vimroam#u#map_key('n', '[[', '<Plug>VimRoamGoToPrevHeader')
  call vimroam#u#map_key('n', ']=', '<Plug>VimRoamGoToNextSiblingHeader')
  call vimroam#u#map_key('n', '[=', '<Plug>VimRoamGoToPrevSiblingHeader')
endif

if vimroam#vars#get_wikilocal('auto_export')
  " Automatically generate HTML on page write.
  augroup vimroam
    au BufWritePost <buffer>
      \ call vimroam#html#Wiki2HTML(expand(vimroam#vars#get_wikilocal('path_html')),
      \                             expand('%'))
  augroup END
endif

if vimroam#vars#get_wikilocal('auto_toc')
  " Automatically update the TOC *before* the file is written
  augroup vimroam
    au BufWritePre <buffer> call vimroam#base#table_of_contents(0)
  augroup END
endif

if vimroam#vars#get_wikilocal('auto_tags')
  " Automatically update tags metadata on page write.
  augroup vimroam
    au BufWritePre <buffer> call vimroam#tags#update_tags(0, '')
  augroup END
endif

if vimroam#vars#get_wikilocal('auto_generate_links')
  " Automatically generate links *before* the file is written
  augroup vimroam
    au BufWritePre <buffer> call vimroam#base#generate_links(0)
  augroup END
endif

if vimroam#vars#get_wikilocal('auto_generate_tags')
  " Automatically generate tags *before* the file is written
  augroup vimroam
    au BufWritePre <buffer> call vimroam#tags#generate_tags(0)
  augroup END
endif


" format of a new zettel filename
if !exists('g:zettel_format')
  let g:zettel_format = "%y%m%d-%H%M"
endif


function! s:wiki_yank_name()
  let filename = expand("%")
  let link = vimroam#zettel#get_link(filename)
  let clipboardtype=&clipboard
  if clipboardtype=="unnamed"  
    let @* = link
  elseif clipboardtype=="unnamedplus"
    let @+ = link
  else
    let @@ = link
  endif
  return link
endfunction

" replace file name under cursor which corresponds to a wiki file with a
" corresponding Wiki link
function! s:replace_file_with_link()
  let filename = expand("<cfile>")
  let link = vimroam#zettel#get_link(filename)
  execute "normal BvExa" . link
endfunction

command! -bang -nargs=* ZettelYankName call <sid>wiki_yank_name()

" crate new zettel using command
command! -bang -nargs=* ZettelNew call vimroam#zettel#zettel_new(<q-args>)

command! -buffer ZettelGenerateLinks call vimroam#zettel#generate_links()
command! -buffer -nargs=* -complete=custom,vimroam#tags#complete_tags
      \ ZettelGenerateTags call vimroam#zettel#generate_tags(<f-args>)

command! -buffer ZettelBackLinks call vimroam#zettel#backlinks()
command! -buffer ZettelInbox call vimroam#zettel#inbox()
command! -buffer ZettelCreateNew call vimroam#zettel#new_note()

if !exists('g:zettel_default_mappings')
  let g:zettel_default_mappings=1
endif
nnoremap <silent> <Plug>ZettelSearchMap :ZettelSearch<cr>
nnoremap <silent> <Plug>ZettelYankNameMap :ZettelYankName<cr> 
nnoremap <silent> <Plug>ZettelReplaceFileWithLink :call <sid>replace_file_with_link()<cr> 
xnoremap <silent> <Plug>ZettelNewSelectedMap :call vimroam#zettel#zettel_new_selected()<CR>
xnoremap <silent> <Plug>ZettelImage :call vimroam#zettel#zettel_make_image_link()<CR>
