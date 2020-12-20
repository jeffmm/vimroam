" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" VimRoam autoload plugin file
" Description: Link functions for markdown syntax
" Home: https://github.com/jeffmm/vimroam/


function! s:safesubstitute(text, search, replace, mode) abort
  " Substitute regexp but do not interpret replace
  let escaped = escape(a:replace, '\&')
  return substitute(a:text, a:search, escaped, a:mode)
endfunction


function! vimroam#markdown_base#scan_reflinks() abort
  let mkd_refs = {}
  " construct list of references using vimgrep
  try
    " Why noautocmd? Because https://github.com/jeffmm/vimroam/issues/121
    noautocmd execute 'vimgrep #'.vimroam#vars#get_syntaxlocal('rxMkdRef').'#j %'
  catch /^Vim\%((\a\+)\)\=:E480/   " No Match
    "Ignore it, and move on to the next file
  endtry

  for d in getqflist()
    let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
    let descr = matchstr(matchline, vimroam#vars#get_syntaxlocal('rxMkdRefMatchDescr'))
    let url = matchstr(matchline, vimroam#vars#get_syntaxlocal('rxMkdRefMatchUrl'))
    if descr !=? '' && url !=? ''
      let mkd_refs[descr] = url
    endif
  endfor
  call vimroam#vars#set_bufferlocal('markdown_refs', mkd_refs)
  return mkd_refs
endfunction


" try markdown reference links
function! vimroam#markdown_base#open_reflink(link) abort
  let link = a:link
  let mkd_refs = vimroam#vars#get_bufferlocal('markdown_refs')
  if has_key(mkd_refs, link)
    let url = mkd_refs[link]
    call vimroam#base#system_open_link(url)
    return 1
  else
    return 0
  endif
endfunction


function! s:normalize_link_syntax_n() abort
  let lnum = line('.')

  " try WikiIncl
  let lnk = vimroam#base#matchstr_at_cursor(vimroam#vars#get_global('rxWikiIncl'))
  if !empty(lnk)
    " NO-OP !!
    return
  endif

  " try WikiLink0: replace with WikiLink1
  let lnk = vimroam#base#matchstr_at_cursor(vimroam#vars#get_syntaxlocal('rxWikiLink0'))
  if !empty(lnk)
    let sub = vimroam#base#normalize_link_helper(lnk,
          \ vimroam#vars#get_syntaxlocal('rxWikiLinkMatchUrl'),
          \ vimroam#vars#get_syntaxlocal('rxWikiLinkMatchDescr'),
          \ vimroam#vars#get_syntaxlocal('WikiLink1Template2'))
    call vimroam#base#replacestr_at_cursor(vimroam#vars#get_syntaxlocal('rxWikiLink0'), sub)
    return
  endif

  " try WikiLink1: replace with WikiLink0
  let lnk = vimroam#base#matchstr_at_cursor(vimroam#vars#get_syntaxlocal('rxWikiLink1'))
  if !empty(lnk)
    let sub = vimroam#base#normalize_link_helper(lnk,
          \ vimroam#vars#get_syntaxlocal('rxWikiLinkMatchUrl'),
          \ vimroam#vars#get_syntaxlocal('rxWikiLinkMatchDescr'),
          \ vimroam#vars#get_global('WikiLinkTemplate2'))
    call vimroam#base#replacestr_at_cursor(vimroam#vars#get_syntaxlocal('rxWikiLink1'), sub)
    return
  endif

  " try Weblink
  let lnk = vimroam#base#matchstr_at_cursor(vimroam#vars#get_syntaxlocal('rxWeblink'))
  if !empty(lnk)
    let sub = vimroam#base#normalize_link_helper(lnk,
          \ vimroam#vars#get_syntaxlocal('rxWeblinkMatchUrl'),
          \ vimroam#vars#get_syntaxlocal('rxWeblinkMatchDescr'),
          \ vimroam#vars#get_syntaxlocal('Weblink1Template'))
    call vimroam#base#replacestr_at_cursor(vimroam#vars#get_syntaxlocal('rxWeblink'), sub)
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = vimroam#base#matchstr_at_cursor(vimroam#vars#get_global('rxWord'))
  if !empty(lnk)
    if vimroam#base#is_diary_file(expand('%:p'))
      let sub = vimroam#base#normalize_link_in_diary(lnk)
    else
      let sub = vimroam#base#normalize_link_helper(lnk,
            \ vimroam#vars#get_global('rxWord'), '',
            \ vimroam#vars#get_syntaxlocal('Link1'))
    endif
    call vimroam#base#replacestr_at_cursor('\V'.lnk, sub)
    return
  endif

endfunction


function! vimroam#markdown_base#normalize_link() abort
  " TODO mutualize with base
  call s:normalize_link_syntax_n()
endfunction
