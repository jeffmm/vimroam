" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" VimRoam plugin file
" Home: https://github.com/jeffmm/vimroam/
" GetLatestVimScripts: 2226 1 :AutoInstall: vimroam


" Clause: load only onces
if exists('g:loaded_vimroam') || &compatible
  finish
endif
let g:loaded_vimroam = 1

" Set to version number for release, otherwise -1 for dev-branch
let s:plugin_vers = str2float('-1')

" Get the directory the script is installed in
let s:plugin_dir = expand('<sfile>:p:h:h')

" Save peace in the galaxy
let s:old_cpo = &cpoptions
set cpoptions&vim

" Save autowriteall varaible state
if exists('g:vimroam_autowriteall')
  let s:vimroam_autowriteall_saved = g:vimroam_autowriteall
else
  let s:vimroam_autowriteall_saved = 1
endif


" Autocommand called when the cursor leaves the buffer
function! s:setup_buffer_leave() abort
  " don't do anything if it's not managed by VimRoam (that is, when it's not in
  " a registered wiki and not a temporary wiki)
  if vimroam#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  let &autowriteall = s:vimroam_autowriteall_saved

  if !empty(vimroam#vars#get_global('menu'))
    exe 'nmenu disable '.vimroam#vars#get_global('menu').'.Table'
  endif
endfunction

" JMM - Function for creating a new zettel note from scratch
function! s:vimroam_new_note()
    let idx = vimroam#vars#get_bufferlocal('wiki_nr')
    if idx > 0
      call vimroam#base#goto_index(idx)
    else
      call vimroam#base#goto_index(0)
    endif
    let title = input("New note name: ", strftime("%Y%m%d%H%M"))
    call vimroam#zettel#zettel_new(title)
endfunction

" Autocommand called when Vim opens a new buffer with a known wiki
" extension. Both when the buffer has never been opened in this session and
" when it has.
function! s:setup_new_wiki_buffer() abort
  let wiki_nr = vimroam#vars#get_bufferlocal('wiki_nr')
  if wiki_nr == -1    " it's not in a known wiki directory
    return
  endif

  if vimroam#vars#get_wikilocal('maxhi')
    call vimroam#vars#set_bufferlocal('existing_wikifiles', vimroam#base#get_wikilinks(wiki_nr, 1, ''))
    call vimroam#vars#set_bufferlocal('existing_wikidirs',
          \ vimroam#base#get_wiki_directories(wiki_nr))
  endif

  " this makes that ftplugin/vimroam.vim and afterwards syntax/vimroam.vim are
  " sourced
  call vimroam#u#ft_set()
endfunction


" Autocommand called when the cursor enters the buffer
function! s:setup_buffer_enter() abort
  " don't do anything if it's not managed by VimRoam
  if vimroam#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  call s:set_global_options()
endfunction


" Autocommand called when the buffer enters a window or when running a  diff
function! s:setup_buffer_win_enter() abort
  " don't do anything if it's not managed by VimRoam
  if vimroam#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  if !vimroam#u#ft_is_vw()
    call vimroam#u#ft_set()
  endif

  call s:set_windowlocal_options()
endfunction


" Help syntax reloading
function! s:setup_cleared_syntax() abort
  " highlight groups that get cleared
  " on colorscheme change because they are not linked to Vim-predefined groups
  hi def VimRoamBold term=bold cterm=bold gui=bold
  hi def VimRoamItalic term=italic cterm=italic gui=italic
  hi def VimRoamBoldItalic term=bold cterm=bold gui=bold,italic
  hi def VimRoamUnderline gui=underline
  if vimroam#vars#get_global('hl_headers') == 1
    for i in range(1,6)
      execute 'hi def VimRoamHeader'.i.' guibg=bg guifg='
            \ . vimroam#vars#get_global('hcolor_guifg_'.&background)[i-1]
            \ .' gui=bold ctermfg='.vimroam#vars#get_global('hcolor_ctermfg_'.&background)[i-1]
            \ .' term=bold cterm=bold'
    endfor
  endif
endfunction


" Return: list of extension known vy vimroam
function! s:vimroam_get_known_extensions() abort
  " Getting all extensions that different wikis could have
  let extensions = {}
  for idx in range(vimroam#vars#number_of_wikis())
    let ext = vimroam#vars#get_wikilocal('ext', idx)
    let extensions[ext] = 1
  endfor
  " append extensions from g:vimroam_ext2syntax
  for ext in keys(vimroam#vars#get_global('ext2syntax'))
    let extensions[ext] = 1
  endfor
  return keys(extensions)
endfunction


" Set settings which are global for Vim, but should only be executed for
" VimRoam buffers. So they must be set when the cursor enters a VimRoam buffer
" and reset when the cursor leaves the buffer.
function! s:set_global_options() abort
  let s:vimroam_autowriteall_saved = &autowriteall
  let &autowriteall = vimroam#vars#get_global('autowriteall')

  if !empty(vimroam#vars#get_global('menu'))
    exe 'nmenu enable '.vimroam#vars#get_global('menu').'.Table'
  endif
endfunction


" Set settings which are local to a window. In a new tab they would be reset to
" Vim defaults. So we enforce our settings here when the cursor enters a
" VimRoam buffer.
function! s:set_windowlocal_options() abort
  if !&diff   " if Vim is currently in diff mode, don't interfere with its folding
    let foldmethod = vimroam#vars#get_global('folding')
    if foldmethod =~? '^expr.*'
      setlocal foldmethod=expr
      setlocal foldexpr=VimRoamFoldLevel(v:lnum)
      setlocal foldtext=VimRoamFoldText()
    elseif foldmethod =~? '^list.*' || foldmethod =~? '^lists.*'
      setlocal foldmethod=expr
      setlocal foldexpr=VimRoamFoldListLevel(v:lnum)
      setlocal foldtext=VimRoamFoldText()
    elseif foldmethod =~? '^syntax.*'
      setlocal foldmethod=syntax
      setlocal foldtext=VimRoamFoldText()
    elseif foldmethod =~? '^custom.*'
      " do nothing
    else
      setlocal foldmethod=manual
      normal! zE
    endif
  endif

  if exists('+conceallevel')
    let &l:conceallevel = vimroam#vars#get_global('conceallevel')
  endif

  if vimroam#vars#get_global('auto_chdir')
    exe 'lcd' vimroam#vars#get_wikilocal('path')
  endif
endfunction


" Echo vimroam version
" Called by :VimRoamShowVersion
function! s:get_version() abort
  if s:plugin_vers != -1
    echo 'Stable version: ' . string(s:plugin_vers)
  else
    let l:plugin_rev    = system('git --git-dir ' . s:plugin_dir . '/.git rev-parse --short HEAD')
    let l:plugin_branch = system('git --git-dir ' . s:plugin_dir . '/.git rev-parse --abbrev-ref HEAD')
    let l:plugin_date   = system('git --git-dir ' . s:plugin_dir . '/.git show -s --format=%ci')
    if v:shell_error == 0
      echo 'Os: ' . vimroam#u#os_name()
      echo 'Vim: ' . v:version
      echo 'Branch: ' . l:plugin_branch
      echo 'Revision: ' . l:plugin_rev
      echo 'Date: ' . l:plugin_date
    else
      echo 'Unknown version'
    endif
  endif
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialization of VimRoam starts here.
" Make sure everything below does not cause autoload/vimroam/base.vim
" to be loaded
call vimroam#vars#init()


" Define callback functions which the user can redefine
if !exists('*VimRoamLinkHandler')
  function VimRoamLinkHandler(url)
    return 0
  endfunction
endif

if !exists('*VimRoamLinkConverter')
  function VimRoamLinkConverter(url, source, target)
    " Return the empty string when unable to process link
    return ''
  endfunction
endif

if !exists('*VimRoamWikiIncludeHandler')
  function! VimRoamWikiIncludeHandler(value)
    return ''
  endfunction
endif


" Write a level 1 header to new wiki files
" a:fname should be an absolute filepath
function! s:create_h1(fname) abort
  " Clause: Don't do anything for unregistered wikis
  let idx = vimroam#vars#get_bufferlocal('wiki_nr')
  if idx == -1
    return
  endif

  " Clause: no auto_header
  if !vimroam#vars#get_global('auto_header')
    return
  endif

  " Clause: don't create header for the journal index page
  if vimroam#path#is_equal(a:fname,
        \ vimroam#vars#get_wikilocal('path', idx).vimroam#vars#get_wikilocal('journal_rel_path', idx).
        \ vimroam#vars#get_wikilocal('journal_index', idx).vimroam#vars#get_wikilocal('ext', idx))
    return
  endif

  " Get tail of filename without extension
  let title = expand('%:t:r')

  " Clause: don't insert header for index page
  if title ==# vimroam#vars#get_wikilocal('index', idx)
    return
  endif

  " Don't substitute space char for journal pages
  if title !~# '^\d\{4}-\d\d-\d\d'
    " NOTE: it is possible this could remove desired characters if the 'links_space_char'
    " character matches characters that are intentionally used in the title.
    let title = substitute(title, vimroam#vars#get_wikilocal('links_space_char'), ' ', 'g')
  endif

  " Insert the header
  if vimroam#vars#get_wikilocal('syntax') ==? 'markdown'
    keepjumps call append(0, '# ' . title)
    for _ in range(vimroam#vars#get_global('markdown_header_style'))
      keepjumps call append(1, '')
    endfor
  else
    keepjumps call append(0, '= ' . title . ' =')
  endif
endfunction

" Define autocommands for all known wiki extensions
let s:known_extensions = s:vimroam_get_known_extensions()

if index(s:known_extensions, '.wiki') > -1
  augroup filetypedetect
    " Clear FlexWiki's stuff
    au! * *.wiki
  augroup end
endif

augroup vimroam
  autocmd!
  autocmd ColorScheme * call s:setup_cleared_syntax()

  " ['.md', '.mdown'] => *.md,*.mdown
  let pat = join(map(s:known_extensions, '"*" . v:val'), ',')
  exe 'autocmd BufNewFile,BufRead '.pat.' call s:setup_new_wiki_buffer()'
  exe 'autocmd BufEnter '.pat.' call s:setup_buffer_enter()'
  exe 'autocmd BufLeave '.pat.' call s:setup_buffer_leave()'
  exe 'autocmd BufWinEnter '.pat.' call s:setup_buffer_win_enter()'
  if exists('##DiffUpdated')
    exe 'autocmd DiffUpdated '.pat.' call s:setup_buffer_win_enter()'
  endif
  " automatically generate a level 1 header for new files
  exe 'autocmd BufNewFile '.pat.' call s:create_h1(expand("%:p"))'
  " Format tables when exit from insert mode. Do not use textwidth to
  " autowrap tables.
  if vimroam#vars#get_global('table_auto_fmt')
    exe 'autocmd InsertLeave '.pat.' call vimroam#tbl#format(line("."), 2)'
  endif
  if vimroam#vars#get_global('folding') =~? ':quick$'
    " from http://vim.wikia.com/wiki/Keep_folds_closed_while_inserting_text
    " Don't screw up folds when inserting text that might affect them, until
    " leaving insert mode. Foldmethod is local to the window. Protect against
    " screwing up folding when switching between windows.
    exe 'autocmd InsertEnter '.pat.' if !exists("w:last_fdm") | let w:last_fdm=&foldmethod'.
          \ ' | setlocal foldmethod=manual | endif'
    exe 'autocmd InsertLeave,WinLeave '.pat.' if exists("w:last_fdm") |'.
          \ 'let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif'
  endif
augroup END


" Declare global commands
command! VimRoamUISelect call vimroam#base#ui_select()

" these commands take a count e.g. :VimRoamIndex 2
" the default behavior is to open the index, journal etc.
" for the CURRENT wiki if no count is given
command! -count=0 VimRoamIndex
      \ call vimroam#base#goto_index(<count>)

command! -count=0 VimRoamTabIndex
      \ call vimroam#base#goto_index(<count>, 1)

command! -count=0 VimRoamJournalIndex
      \ call vimroam#journal#goto_journal_index(<count>)

command! -count=0 VimRoamMakeJournalNote
      \ call vimroam#journal#make_note(<count>)

command! -count=0 VimRoamTabMakeJournalNote
      \ call vimroam#journal#make_note(<count>, 1)

command! -count=0 VimRoamMakeYesterdayJournalNote
      \ call vimroam#journal#make_note(<count>, 0,
      \ vimroam#journal#journal_date_link(localtime(), -1))

command! -count=0 VimRoamMakeTomorrowJournalNote
      \ call vimroam#journal#make_note(<count>, 0,
      \ vimroam#journal#journal_date_link(localtime(), 1))

command! VimRoamJournalGenerateLinks
      \ call vimroam#journal#generate_journal_section()

command! VimRoamShowVersion call s:get_version()

command! -nargs=* -complete=customlist,vimroam#vars#complete
      \ VimRoamVar call vimroam#vars#cmd(<q-args>)
" Search for note that link to current note
command! -nargs=* -bang VimRoamRgBacklinks 
      \ call vimroam#base#rg_text_files(<bang>0, '('.expand("%:t").')',
      \ s:get_default('path'))
" Search note tags, which is any word surrounded by colons (vimroam style tags)
command! -nargs=* -bang VimRoamRgTags 
      \ call vimroam#base#rg_text(<bang>0, ':[a-zA-Z0-9]+:', s:get_default('path'))
" Search for text in wiki files
command! -nargs=* -bang VimRoamRgText 
      \ call vimroam#base#rg_text(<bang>0, '[a-zA-Z0-9]+', fnameescape(s:get_default('path')))
" Search for filenames in wiki
command! -nargs=* -bang VimRoamRgFiles 
      \ call vimroam#base#rg_files(<bang>0, s:get_default('path'), 
      \ "*" . s:get_default('ext'))
" Create a new note
command! -nargs=* -bang VimRoamNewNote call s:vimroam_new_note()

function! s:get_default(val)
  let idx = vimroam#vars#get_bufferlocal('wiki_nr')
  if idx > 0
    return vimroam#vars#get_wikilocal(a:val, idx)
  endif
  return vimroam#vars#get_wikilocal(a:val, 0)
endfunction
" Declare global maps
" <Plug> global definitions
nnoremap <silent><script> <Plug>VimRoamIndex
    \ :<C-U>call vimroam#base#goto_index(v:count)<CR>
nnoremap <silent><script> <Plug>VimRoamTabIndex
    \ :<C-U>call vimroam#base#goto_index(v:count, 1)<CR>
nnoremap <silent><script> <Plug>VimRoamUISelect
    \ :VimRoamUISelect<CR>
nnoremap <silent><script> <Plug>VimRoamJournalIndex
    \ :<C-U>call vimroam#journal#goto_journal_index(v:count)<CR>
nnoremap <silent><script> <Plug>VimRoamJournalGenerateLinks
    \ :VimRoamJournalGenerateLinks<CR>
nnoremap <silent><script> <Plug>VimRoamMakeJournalNote
    \ :<C-U>call vimroam#journal#make_note(v:count)<CR>
nnoremap <silent><script> <Plug>VimRoamTabMakeJournalNote
    \ :<C-U>call vimroam#journal#make_note(v:count, 1)<CR>
nnoremap <silent><script> <Plug>VimRoamMakeYesterdayJournalNote
    \ :<C-U>call vimroam#journal#make_note(v:count, 0,
    \ vimroam#journal#journal_date_link(localtime(), -1))<CR>
nnoremap <silent><script> <Plug>VimRoamMakeTomorrowJournalNote
    \ :<C-U>call vimroam#journal#make_note(v:count, 0,
    \ vimroam#journal#journal_date_link(localtime(), 1))<CR>

" Set default global key mappings
if str2nr(vimroam#vars#get_global('key_mappings').global)
  " Get the user defined prefix (default <leader>w)
  let s:map_prefix = vimroam#vars#get_global('map_prefix')

  call vimroam#u#map_key('n', s:map_prefix . 'w', '<Plug>VimRoamIndex', 2)
  call vimroam#u#map_key('n', s:map_prefix . 'J', '<Plug>VimRoamJournalIndex', 2)
  call vimroam#u#map_key('n', s:map_prefix . 'j', '<Plug>VimRoamMakeJournalNote', 2)
  call vimroam#u#map_key('n', s:map_prefix . 's', '<Plug>VimRoamRgText', 2)
  call vimroam#u#map_key('n', s:map_prefix . 't', '<Plug>VimRoamRgTags', 2)
  call vimroam#u#map_key('n', s:map_prefix . 'f', '<Plug>VimRoamRgFiles', 2)
  call vimroam#u#map_key('n', s:map_prefix . 'n', '<Plug>VimRoamNewNote', 2)

endif

" format of a new zettel filename
function! s:strip_extension(param)
    return split(a:param, "\\.md")[0]
endfunction
if !exists("g:zettel_format")
    let g:zettel_format = s:strip_extension("%title")
endif

" Restore peace in the galaxy
let &cpoptions = s:old_cpo
