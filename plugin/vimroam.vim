" Vim global plugin for correcting typing mistakes
" Last Change:	2000 Oct 15
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" License:	This file is placed in the public domain.

if exists("g:loaded_vimroam")
  finish
endif
let g:loaded_vimroam = 1

let s:save_cpo = &cpo
set cpo&vim

" Script variables, only to be used locally
" let s:count = 4

if !hasmapto('<Plug>VimRoamExample')
  map <unique> <Leader>a  <Plug>VimRoamExample
endif
noremap <unique> <script> <Plug>VimRoamExample  <SID>Example

noremenu <script> Plugin.Example\ VRExample      <SID>Example

noremap <SID>Example  :call <SID>Example(expand("<cword>"), 1)<CR>

" Script function only to be used locally
function s:Example(from, correct)
  let to = input("type the correction for " . a:from . ": ")
  exe ":iabbrev " . a:from . " " . to
  if a:correct | exe "normal viws\<C-R>\" \b\e" | endif
  let s:count = s:count + 1
  echo s:count . " corrections now"
endfunction

if !exists(":VRExample")
  command -nargs=1  VRExample  :call s:Example(<q-args>, 0)
endif
"
" VimWiki
  " let g:vimwiki_key_mappings =
    " \ {
    " \   'all_maps': 1,
    " \   'global': 0,
    " \   'headers': 0,
    " \   'text_objs': 0,
    " \   'table_format': 0,
    " \   'table_mappings': 0,
    " \   'lists': 0,
    " \   'links': 1,
    " \   'html': 0,
    " \   'mouse': 0,
    " \ }


" let s:vimwiki_notebook_dir = "~/.vim/wiki/notebook"
" let s:vimwiki_journal_dir = "~/.vim/wiki/journal"

" nmap <Plug>NoVimwikiPrevLink <Plug>VimwikiPrevLink 
" nmap <Plug>NoVimwikiNextLink <Plug>VimwikiNextLink 
" vmap <Plug>NoVimwikiNormalizeLinkVisualCR <Plug>VimwikiNormalizeLinkVisualCR
" Filetypes enabled for
" let g:vimwiki_filetypes = ['markdown']
" let g:vimwiki_markdown_link_ext = 1
" let g:vimwiki_global_ext = 0
" let g:vimwiki_list = [{'path': s:vimwiki_notebook_dir, 
            " \ 'links_space_char': '-',
            " \ 'template_path': s:vimwiki_notebook_dir . "/templates/",
            " \ 'template_default': 'default',
            " \ 'path_html': s:vimwiki_notebook_dir . "site_html",
            " \ 'html_filename_parameterization': 1,
            " \ 'custom_wiki2html': 'vimwiki_markdown',
            " \ 'template_ext': '.tpl',
            " \ 'syntax': 'markdown',
            " \ 'ext': '.md',
            " \ 'markdown_link_ext': 1,
            " \ 'auto_generate_links': 1,
            " \ 'exclude_files': ['**/*.md.asc'],
            " \ },
            " \ {'path': s:vimwiki_journal_dir,
            " \ 'links_space_char': '_',
            " \ 'syntax': 'markdown',
            " \ 'exclude_files': ['**/*.md.asc'],
            " \ 'ext': '.md.asc'}]

" let g:zettel_default_mappings = 0

" let g:zettel_options = [{"front_matter" : [["tags", ""]],
   " \ "template" :  "~/.config/nvim/zk-template.tpl"}, {}]
"
" let g:zettel_date_format = "%Y%m%d"

" function s:strip_extension(param)
    " return split(a:param, "\\.md")[0]
" endfunction
" let g:zettel_format = s:strip_extension("%title")

" let g:zettel_link_format="[%title](%link.md)"

" For quickly searching old notes / creating a new note
" let g:nv_search_paths = ['~/.vim/wiki/notebook']


" function! zettel#vimwiki#escape_filename(name)
  " let name = substitute(a:name, "[%.%,%?%!%:]", "", "g") " remove unwanted characters
  " let schar = vimwiki#vars#get_wikilocal('links_space_char') " ' ' by default
  " let name = substitute(name, " ", schar, "g") " change spaces to link_space_char

  " let name = tolower(name)
  " return fnameescape(name)
" endfunction


" function! VimwikiLinkHandler(link)
    " if vimwiki#vars#get_wikilocal('ext') ==# '.md.asc'
        " return 0
    " endif
    " let filename = a:link
    " let link_info = vimwiki#base#resolve_link(filename)
    " First check that the scheme is an inter-wiki file
    " if link_info.scheme ==# 'wiki0'
        " if empty(glob(link_info.filename)) 
            " let title = s:strip_extension(filename)
            " let name = zettel#vimwiki#new_zettel_name(title)
            " prepare_template_variables needs the file saved on disk
            " execute "w"
            " make variables that will be available in the new page template
            " let variables = zettel#vimwiki#prepare_template_variables(expand("%"), title)
            " replace the visually selected text with a link to the new zettel
            " call zettel#vimwiki#zettel_new(title, variables)
            " return 1
        " endif
    " endif
    " return 0
" endfunction

" function! VimwikiNewNote()
    " execute "VimwikiIndex 1"
    " let title = input("New note name: ", "" . strftime("%Y%m%d%H%M"))
    " execute "ZettelNew " . title
" endfunction

" command! ZettelCreateNew call VimwikiNewNote()

"Config for markdown files
" function! s:link_file_handler(lines) abort
    " if a:lines == [] || a:lines == [''] || a:lines == ['', '']
        " call feedkeys('a', 'n')
        " return
    " endif
    " let filename = split(a:lines[1], "\\.md")[0]
    " let link = "[" . filename . "](" . a:lines[1] . ")"
    " let @* = link
    " silent! let @* = link
    " silent! let @+ = link
    " call feedkeys('pa', 'n')
" endfunction

" command! -bang -nargs=? -complete=dir NoteFiles
    " \ call fzf#vim#files(s:vimwiki_notebook_dir, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

" function! s:vimwiki_sync_pull(path) abort
    " if expand("%:p:h") ==# fnamemodify(a:path, ":p:h")
        " let l:git_pull_update = system("!git -C " . fnamemodify(a:path, ":p:h") . " pull origin master 2> /dev/null | wc -l")
        " :echo l:git_pull_update
        " if l:git_pull_update > 1
            " :edit
        " endif
    " endif
" endfunction

" autocmd BufNewFile,BufRead *.md inoremap <buffer> [] <ESC>:NVInsertLink!<CR>
" autocmd BufNewFile,BufRead *.md vnoremap <C-m> :call ConvertToImageLink()<cr>
" autocmd BufReadPre *.md call s:vimwiki_sync_pull(s:vimwiki_notebook_dir)"
" autocmd BufWritePost *.md :call s:vimwiki_sync_push(s:vimwiki_notebook_dir)
" autocmd BufReadPre *.md.asc :call s:vimwiki_sync_pull(s:vimwiki_journal_dir)
" autocmd BufWritePost *.md.asc :call s:vimwiki_sync_push(s:vimwiki_journal_dir)

" function! s:vimwiki_sync_push(path) abort
    " if expand("%:p:h") ==# fnamemodify(a:path, ":p:h")
        " silent! execute "!git -C " . a:path . " add ."
        " silent! execute "!git -C " . a:path . " commit -m 'vimwiki autocommit' > /dev/null"
        " silent! execute "!git -C " . a:path . " push origin master > /dev/null &"
    " endif
" endfunction

" function! s:get_visual_selection()
    " "See https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
    " "Why is this not a built-in Vim script function?!
    " let [line_start, column_start] = getpos("'<")[1:2]
    " let [line_end, column_end] = getpos("'>")[1:2]
    " let lines = getline(line_start, line_end)
    " if len(lines) == 0
        " return ''
    " endif
    " let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    " let lines[0] = lines[0][column_start - 1:]
    " return join(lines, "\n")
" endfunction


"Convert GitHub-Flavored Markdown syntax-highlighting to Liquid syntax-highlighting.
" function! ConvertToImageLink() range
    " let l:text = <sid>get_visual_selection()
    " let l:text = trim(l:text)
    " if empty(glob(expand(l:text)))
        " return
    " endif
    " let l:extension = fnamemodify(l:text, ":e")
    " let l:name = fnamemodify(l:text, ":t:r")
    " if l:extension !=? "png" && l:extension[:2] !=? "tif" && l:extension !=? "bmp" && l:extension !=? "jpg" && l:extension !=? "jpeg"
        " return
    " endif
    " let l:directory = expand("%:p:h") . "/figs/"
    " if empty(glob(l:directory))
        " silent! execute "!mkdir " . l:directory
    " endif
    " let l:name = substitute(l:name, " ", "_", "g")
    " let l:output = l:directory . l:name . ".jpg"
    " if l:extension !=? "png" && l:extension[:2] !=? "tif" && l:extension !=? "bmp"
        " silent! execute "!convert " . l:text . " " . l:output
    " else
        " silent! execute "!cp " . l:text . " " . l:output
    " endif
    " " Reduce file size if ImageMagick is installed
    " if executable("mogrify")
        " let width = system("identify -format '%w' " . l:output)
        " silent! execute '!mogrify -filter Triangle -define filter:support=2 
                    " \ -thumbnail ' . float2nr(round(width/2))
                    " \ . ' -unsharp 0.25x0.25+8.3+0.065
                    " \ -dither None -posterize 136 -quality 82 -define
                    " \ jpeg:fancy-upsampling=off -interlace none 
                    " \ -colorspace sRGB ' . l:output
    " endif
    " execute ":'<,'>s#" . fnameescape(l:text) . "#![" . l:name . "](figs/" . l:name . ".jpg)#"
" endfunction

" w is for wiki
" let g:which_key_map.w = {
      " \ 'name' : '+wiki' ,
      " \ 'w' : [':VimwikiIndex', 'notebook index'],
      " \ 'J' : [':VimwikiIndex 2', 'journal index'],
      " \ 'b' : [':NVBacklinks' , 'find backlinks'],
      " \ 's' : [':NVSearchText', 'search notes'],
      " \ 'n' : [':ZettelCreateNew', 'new note'],
      " \ 'p' : [':MarkdownPreview', 'markdown preview'],
      " \ 't' : [':NVTags', 'search tags'],
      " \ 'i' : [':VimwikiCheckLinks', 'unlinked note inbox'],
      " \ 'y' : [':ZettelYankName', 'yank note link'],
      " \ 'I' : [':ZettelInsertNote', 'insert note'],
      " \ 'R' : [':VimwikiRenameFile', 'rename note'],
      " \ 'D' : [':VimwikiDeleteFile', 'delete note'],
      " \ }

let &cpo = s:save_cpo
unlet s:save_cpo
