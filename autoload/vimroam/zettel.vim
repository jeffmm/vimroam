" source: https://stackoverflow.com/a/6271254/2467963
" get text of the visual selection
function! s:get_visual_selection()
  " Why is this not a built-in Vim script function?!
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if len(lines) == 0
    return ''
  endif
  let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction

" this function is useful for comands in plugin/zettel.vim
" set number of the active wiki
function! vimroam#zettel#set_active_wiki(number)
  " this buffer value is used by vimroam#vars#get_wikilocal to retrieve
  " the current wiki number
  call setbufvar("%","vimroam_wiki_nr", a:number)
endfunction

" set default wiki number. it is set to -1 when no wiki is initialized
" we will set it to first wiki in wiki list, with number 0
function! vimroam#zettel#initialize_wiki_number()
  if getbufvar("%", "vimroam_wiki_nr") == -1
    call vimroam#zettel#set_active_wiki(0)
  endif
endfunction
call vimroam#zettel#initialize_wiki_number()

" get user option for the current wiki
" it seems that it is not possible to set custom options in g:vimroam_list
" so we need to use our own options
function! vimroam#zettel#get_option(name)
  if !exists('g:zettel_options')
    return ""
  end
  " the options for particular wikis must be in the same order as wiki
  " definitions in g:vimroam_list
  let idx = vimroam#vars#get_bufferlocal('wiki_nr')
  let option_number = "g:zettel_options[" . idx . "]"
  if exists(option_number)
    if exists(option_number . "." . a:name)
      return g:zettel_options[idx][a:name]
    endif
  endif
  return ""
endfunction

" markdown test for front matter end
function! s:test_header_end_md(line, i)
  if a:i > 0 
    let pos = matchstrpos(a:line, "^\s*---")
    return pos[1]
  endif
  return -1
endfunction

" vimroam test fot front matter end
function! s:test_header_end_wiki(line, i)
  " return false for all lines that start with % character
  let pos = matchstrpos(a:line,"^\s*%")
  if pos[1] > -1 
    return -1
  endif
  " first line which is not tag should be selected
  return 0
endfunction

let s:test_header_end = function(vimroam#vars#get_wikilocal('syntax') ==? 'markdown' ? '<sid>test_header_end_md' : '<sid>test_header_end_wiki')


" variables that depend on the wiki syntax
if vimroam#vars#get_wikilocal('syntax') ==? 'markdown'
  " add file extension when g:vimroam_markdown_link_ext is set
  if exists("g:vimroam_markdown_link_ext") && g:vimroam_markdown_link_ext == 1
    let s:link_format = "[%title](%link.md)"
    " TODO: s:link_stub used to be different than s:link_format, but it is no longer
    " the case. maybe we can get rid of it?
    let s:link_stub =  "[%title](%link.md)"
  else
    let s:link_format = "[%title](%link)"
    let s:link_stub =  "[%title](%link)"
  endif
  let s:header_format = "%s: %s"
  let s:header_delimiter = "---"
  let s:insert_mode_title_format = "``l"
  let s:grep_link_pattern = '/\(%s\.\{-}m\{-}d\{-}\)/' " match filename in  parens. including optional .md extension
  let s:section_pattern = "# %s"
else
  let s:link_format = "[[%link|%title]]"
  let s:link_stub = "[[%link|%title]]"
  let s:header_format = "%%%s %s"
  let s:header_delimiter = ""
  let s:insert_mode_title_format = "h"
  let s:grep_link_pattern = '/\[%s[|#\]]/'
  let s:section_pattern = "= %s ="
end

" enable overriding of 
if exists("g:zettel_link_format")
  let s:link_format = g:zettel_link_format
  let s:link_stub =  g:zettel_link_format
endif

let s:tag_pattern = '^!_TAG'
function! vimroam#zettel#update_listing(lines, title, links_rx)
  let generator = { 'data': a:lines }
  function generator.f() dict
        return self.data
  endfunction
  call vimroam#base#update_listing_in_buffer(generator, a:title, a:links_rx, line('$')+1, 1, 1)
endfunction

" user configurable fields that should be inserted to a front matter of a new
" Zettel
if !exists('g:zettel_front_matter')
  let g:zettel_front_matter = {}
endif

" front matter can be disabled using disable_front_matter local wiki option
let g:zettel_disable_front_matter = vimroam#zettel#get_option("disable_front_matter")
if empty(g:zettel_disable_front_matter)
  let g:zettel_disable_front_matter=0
end

if !exists('g:zettel_backlinks_title')
  let g:zettel_backlinks_title = "Backlinks"
endif

" default title used for %title placeholder in g:zettel_format if the title is
" empty
if !exists('g:zettel_default_title')
  let g:zettel_default_title="untitled"
endif

" Fixes for Neovim
if has('nvim')

" make string filled with random characters
function! vimroam#zettel#make_random_chars()
  call luaeval("math.randomseed( os.time() )")
  let char_no = range(g:zettel_random_chars)
  let str_list = []
  for x in char_no
    call add(str_list, nr2char(luaeval("math.random(97,122)")))
  endfor
  return join(str_list, "")
endfunction

else

" make string filled with random characters
function! vimroam#zettel#make_random_chars()
  let seed = srand()
  return range(g:zettel_random_chars)->map({-> (97+rand(seed) % 26)->nr2char()})->join('')
endfunction
endif

" number of random characters used in %random placehoder in new zettel name
if !exists('g:zettel_random_chars')
  let g:zettel_random_chars=8
endif
let s:randomchars = vimroam#zettel#make_random_chars()

" default date format used in front matter for new zettel
if !exists('g:zettel_date_format')
  let g:zettel_date_format = "%Y-%m-%d %H:%M"
endif

" initialize new zettel date. it should be overwritten in vimroam#zettel#create()
let s:zettel_date = strftime(g:zettel_date_format)


" find end of the front matter variables
function! vimroam#zettel#find_header_end(filename)
  let lines = readfile(a:filename)
  " Markdown and VimRoam use different formats for metadata header, select the
  " right one according to the file type
  let ext = fnamemodify(a:filename, ":e")
  let Header_test = function(ext ==? 'md' ? '<sid>test_header_end_md' : '<sid>test_header_end_wiki')
  let i = 0
  for line in lines
    " let res = s:test_header_end(line, i)
    let res = Header_test(line, i)
    if res > -1 
      return i
    endif
    let i = i + 1
  endfor
  return 0
endfunction

" helper function to insert a text line to a new zettel
function! s:add_line(text)
  " don't append anything if the argument is empty string
  if len(a:text) > 0
    call append(line("1"), a:text)
  endif
endfunction

" enable functions to be passed as front_matter values
" this can be useful to dynamic value setting 
function! s:expand_front_matter_value(value)
  " enable execution of functions that expands to the correct value
  if type(a:value) == v:t_func
    return a:value()
  else
    return a:value
  endif
endfunction

function! s:make_header_item(key, value)
  let val = <sid>expand_front_matter_value(a:value)
  return printf(s:header_format, a:key, val)
endfunction

" add a variable to the zettel header
function! s:add_to_header(key, value)
  call <sid>add_line(s:make_header_item(a:key, a:value))
endfunction

let s:letters = "abcdefghijklmnopqrstuvwxyz"

" convert number to str (1 -> a, 27 -> aa)
function! s:numtoletter(num)
  let numletter = strlen(s:letters)
  let charindex = a:num % numletter
  let quotient = a:num / numletter
  if (charindex-1 == -1)
    let charindex = numletter
    let quotient = quotient - 1
  endif

  let result =  strpart(s:letters, charindex - 1, 1)
  if (quotient>=1)
    return <sid>numtoletter(float2nr(quotient)) . result
  endif 
  return result
endfunction

" title and date to a new zettel note
function! vimroam#zettel#template(title, date)
  if g:zettel_disable_front_matter == 0 
    call <sid>add_line(s:header_delimiter)
    call <sid>add_to_header("date", a:date)
    call <sid>add_to_header("title", a:title)
    call <sid>add_line(s:header_delimiter)
  endif
endfunction


" sanitize title for filename
function! vimroam#zettel#escape_filename(name)
  let name = substitute(a:name, "[%.%,%?%!%:]", "", "g") " remove unwanted characters
  let schar = vimroam#vars#get_wikilocal('links_space_char') " ' ' by default
  let name = substitute(name, " ", schar, "g") " change spaces to link_space_char

  " JMM - Removing to match with VimRoam
  " let name = tolower(name)
  return fnameescape(name)
endfunction

" count files that match pattern in the current wiki
function! vimroam#zettel#count_files(pattern)
  let cwd = vimroam#vars#get_wikilocal('path')
  let filelist = split(globpath(cwd, a:pattern), '\n')
  return len(filelist)
endfunction

function! vimroam#zettel#next_counted_file()
  " count notes in the current wiki and return 
  let ext = vimroam#vars#get_wikilocal('ext')
  let next_file = vimroam#zettel#count_files("*" . ext) + 1
  return next_file
endfunction

function! vimroam#zettel#new_zettel_name(...)
  let newformat = g:zettel_format
  if a:0 > 0 && a:1 != "" 
    " title contains safe version of the original title
    " raw_title is exact title
    let title = vimroam#zettel#escape_filename(a:1)
    let raw_title = a:1 
  else
    let title = vimroam#zettel#escape_filename(g:zettel_default_title)
    let raw_title = g:zettel_default_title
  endif
  " expand title in the zettel_format
  let newformat = substitute(g:zettel_format, "%title", title, "")
  let newformat = substitute(newformat, "%raw_title", raw_title, "")
  if matchstr(newformat, "%file_no") != ""
    " file_no counts files in the current wiki and adds 1
    let next_file = vimroam#zettel#next_counted_file()
    let newformat = substitute(newformat,"%file_no", next_file, "")
  endif
  if matchstr(newformat, "%file_alpha") != ""
    " same as file_no, but convert numbers to letters
    let next_file = s:numtoletter(vimroam#zettel#next_counted_file())
    let newformat = substitute(newformat,"%file_alpha", next_file, "")
  endif
  if matchstr(newformat, "%random") != ""
    " generate random characters, their number is set by g:zettel_random_chars
    " random characters are set using vimroam#zettel#make_random_chars()
    " this function is set at the startup and then each time
    " vimroam#zettel#create() is called. we don't call it here because we
    " would get wrong links in zettel_new_selected(). It calls new_zettel_name
    " twice.
    let newformat = substitute(newformat, "%random", s:randomchars, "")
  endif
  let final_format =  strftime(newformat)
  if !s:wiki_file_not_exists(final_format)
    " if the current file name is used, increase counter and add it as a
    " letter to the file name. this ensures that we don't reuse the filename
    let file_count = vimroam#zettel#count_files(final_format . "*")
    let final_format = final_format . s:numtoletter(file_count)
  endif
  let g:zettel_current_id = final_format
  return final_format
endfunction

" the optional argument is the wiki number
function! vimroam#zettel#save_wiki_page(format, ...)
  let defaultidx = vimroam#vars#get_bufferlocal('wiki_nr')
  let idx = get(a:, 1, defaultidx)
  let newfile = vimroam#vars#get_wikilocal('path',idx ) . a:format . vimroam#vars#get_wikilocal('ext',idx )
  " copy the captured file to a new zettel
  execute "w! " . newfile
  return newfile
endfunction

" find title in the zettel file and return correct link to it
function! vimroam#zettel#get_link(filename)
  let title =vimroam#zettel#get_title(a:filename)
  let wikiname = fnamemodify(a:filename, ":t:r")
  if title == ""
    " use the Zettel filename as title if it is empty
    let title = wikiname
  endif
  let link= vimroam#zettel#format_link(wikiname, title)
  return link
endfunction

" copy of function from VimRoam
" Params: full path to a wiki file and its wiki number
" Returns: a list of all links inside the wiki file
" Every list item has the form
" [target file, anchor, line number of the link in source file, column number]
function! s:get_links(wikifile, idx)
  if !filereadable(a:wikifile)
    return []
  endif

  let syntax = vimroam#vars#get_wikilocal('syntax', a:idx)
  let rx_link = vimroam#vars#get_syntaxlocal('wikilink', syntax)
  let links = []
  let lnum = 0

  for line in readfile(a:wikifile)
    let lnum += 1

    let link_count = 1
    while 1
      let col = match(line, rx_link, 0, link_count)+1
      let link_text = matchstr(line, rx_link, 0, link_count)
      echomsg("link text " . line . " - " . link_text)
      if link_text == ''
        break
      endif
      let link_count += 1
      let target = vimroam#base#resolve_link(link_text, a:wikifile)
      if target.filename != '' && target.scheme =~# '\mwiki\d\+\|diary\|file\|local'
        call add(links, [target.filename, target.anchor, lnum, col])
      endif
    endwhile
  endfor

  return links
endfunction

" return list of files that match a pattern
function! vimroam#zettel#wikigrep(pattern)
  let paths = []
  let idx = vimroam#vars#get_bufferlocal('wiki_nr')
  let path = fnameescape(vimroam#vars#get_wikilocal('path', idx))
  let ext = vimroam#vars#get_wikilocal('ext', idx)
  try
    let command = 'vimgrep ' . a:pattern . 'j ' . path . "*" . ext
    noautocmd  execute  command
  catch /^Vim\%((\a\+)\)\=:E480/   " No Match
    "Ignore it, and move on to the next file
  endtry
  for d in getqflist()
    let filename = fnamemodify(bufname(d.bufnr), ":p")
    call add(paths, filename)
  endfor
  call uniq(paths)
  return paths
endfunction

function! vimroam#zettel#format_file_title(format, file, title)
  let link = substitute(a:format, "%title", a:title, "")
  let link = substitute(link, "%link", a:file, "")
  return link
endfunction

" use different link style for wiki and markdown syntaxes
function! vimroam#zettel#format_link(file, title)
  return vimroam#zettel#format_file_title(s:link_format, a:file, a:title)
endfunction

function! vimroam#zettel#format_search_link(file, title)
  return vimroam#zettel#format_file_title(s:link_stub, a:file, a:title)
endfunction

" This function is executed when the page referenced by the inserted link
" doesn't contain  title. The cursor is placed at the position where title 
" should start, and insert mode is started
function! vimroam#zettel#insert_mode_in_title()
  execute "normal! " .s:insert_mode_title_format | :startinsert
endfunction

function! vimroam#zettel#get_title(filename)
  let filename = a:filename
  let title = ""
  let lsource = readfile(filename)
  " this code comes from vimroam's html export plugin
  for line in lsource 
    if line =~# '^\s*%\=title'
      let title = matchstr(line, '^\s*%\=title:\=\s\zs.*')
      return title
    endif
  endfor 
  return ""
endfunction


" check if the file with the current filename exits in wiki
function! s:wiki_file_not_exists(filename)
  let link_info = vimroam#base#resolve_link(a:filename)
  return empty(glob(link_info.filename)) 
endfunction

" create new zettel note
" there is one optional argument, the zettel title
function! vimroam#zettel#create(...)
  " name of the new note
  let format = vimroam#zettel#new_zettel_name(a:1)
  let date_format = g:zettel_date_format
  let date = strftime(date_format)
  echomsg("new zettel: ". format)
  " update random chars used in %random name format 
  let s:randomchars = vimroam#zettel#make_random_chars()
  let s:zettel_date = date " save zettel date
  " detect if the wiki file exists
  let wiki_not_exists = s:wiki_file_not_exists(format)
  " let vimroam to open the wiki file. this is necessary  
  " to support the vimroam navigation commands.
  call vimroam#base#open_link(':e ', format)
  " add basic template to the new file
  if wiki_not_exists
    call vimroam#zettel#template(a:1, date)
    return format
  endif
  return -1
endfunction

" front_matter can be either list or dict. if it is a dict, then convert it to
" list
function! s:front_matter_list(front_matter)
  if type(a:front_matter) ==? v:t_list
    return a:front_matter
  endif
  " it is prefered to use a list for front_matter, as it keeps the order of
  " keys. but it is possible to use dict, to keep the backwards compatibility
  let newlist = []
  for key in keys(a:front_matter)
    call add(newlist, [key, a:front_matter[key]])
  endfor
  return newlist
endfunction

function! vimroam#zettel#zettel_new(...)
  let filename = vimroam#zettel#create(a:1)
  " the wiki file already exists
  if filename ==? -1
    return 0
  endif
  let front_matter = vimroam#zettel#get_option("front_matter")
  if g:zettel_disable_front_matter == 0
    if !empty(front_matter)
      let newfile = vimroam#zettel#save_wiki_page(filename)
      let last_header_line = vimroam#zettel#find_header_end(newfile)
      " ensure that front_matter is a list
      let front_list = s:front_matter_list(front_matter)
      " we must reverse the list, because each line is inserted before the
      " ones inserted earlier
      for values in reverse(copy(front_list))
        call append(last_header_line, <sid>make_header_item(values[0], values[1]))
      endfor
    endif
  endif

  " insert the template text from a template file if it is configured in
  " g:zettel_options for the current wiki
  let template = vimroam#zettel#get_option("template")
  if !empty(template)
    let variables = get(a:, 2, 0)
    if empty(variables)
      " save file, in order to prevent errors in variable reading
      execute "w"
      let variables = vimroam#zettel#prepare_template_variables(expand("%"), a:1)
      " backlink contains link to the new note itself, so we will just disable
      " it. backlinks are available only when the new note is created using
      " ZettelNewSelectedMap (`z` letter in visual mode by default).
      let variables.backlink = ""
    endif
    " we may reuse varaibles from the parent zettel. date would be wrong in this case,
    " so we will overwrite it with the current zettel date
    let variables.date = s:zettel_date 
    call vimroam#zettel#expand_template(template, variables)
  endif
  " save the new wiki file
  execute "w"

endfunction
"
" crate zettel link from a selected text
command! ZettelImage call vimroam#zettel#zettel_make_image_link()<CR>
function! vimroam#zettel#zettel_make_image_link()
  let title = <sid>get_visual_selection()
  let name = "figs/" . split(title, "/")[-1]
  execute "!mv " . title . " " . expand("%:p:h") . "/" . name
  " replace the visually selected text with a link to the new zettel
  let name2 = shellescape("[" . name . "](" . name . ")")
  echo name2
  " \\%V.*\\%V. should select the whole visual selection
  execute "normal! :'<,'>s/\\%V.*\\%V./" . vimroam#zettel#format_link(name2) . "\<cr>\<C-o>"
endfunction


" crate zettel link from a selected text
function! vimroam#zettel#zettel_new_selected()
  let title = <sid>get_visual_selection()
  let name = vimroam#zettel#new_zettel_name(title)
  " prepare_template_variables needs the file saved on disk
  execute "w"
  " make variables that will be available in the new page template
  let variables = vimroam#zettel#prepare_template_variables(expand("%"), title)
  " replace the visually selected text with a link to the new zettel
  " \\%V.*\\%V. should select the whole visual selection
  execute "normal! :'<,'>s/\\%V.*\\%V./" . vimroam#zettel#format_link( name, "\\\\0") ."\<cr>\<C-o>"
  call vimroam#zettel#zettel_new(title, variables)
endfunction

" prepare variables that will be available to expand in the new note template
function! vimroam#zettel#prepare_template_variables(filename, title)
  let variables = {}
  let variables.title = a:title
  let variables.date = s:zettel_date
  " add variables from front_matter, to make them available in the template
  let front_matter = vimroam#zettel#get_option("front_matter")
  if !empty(front_matter)
    let front_list = s:front_matter_list(front_matter)
    for entry in copy(front_list)
      let variables[entry[0]] = <sid>expand_front_matter_value(entry[1])
    endfor
  endif
  let variables.backlink = vimroam#zettel#get_link(a:filename)
  " we want to save footer of the parent note. It can contain stuff that can
  " be useful in the child note, like citations,  etc. Footer is everything
  " below last horizontal rule (----)
  let variables.footer = s:read_footer(a:filename)
  return variables
endfunction

" find and return footer in the file
" footer is content below last horizontal rule (----)
function! s:read_footer(filename)
  let lines = readfile(a:filename)
  let footer_lines = []
  let found_footer = -1
  " return empty footer if we couldn't find the footer
  let footer = "" 
  " process lines from the last one and try to find the rule
  for line in reverse(lines) 
    if match(line, "^ \*----") == 0
      let found_footer = 0
      break
    endif
    call add(footer_lines, line)
  endfor
  if found_footer == 0
    let footer = join(reverse(footer_lines), "\n")
  endif
  return footer
endfunction

" populate new note using template
function! vimroam#zettel#expand_template(template, variables)
  " readfile returns list, we need to convert it to string 
  " in order to do global replace
  let template_file = expand(a:template)
  if !filereadable(template_file) 
    return 
  endif
  let content = readfile(template_file)
  let text = join(content, "\n")
  for key in keys(a:variables)
    let text = substitute(text, "%" . key, a:variables[key], "g")
  endfor
  " when front_matter is disabled, there is an empty line before 
  " start of the inserted template. we need to ignore it.
  let correction = 0
  if line('$') == 1 
    let correction = 1
  endif
  " add template at the end
  " we must split it, 
  for xline in split(text, "\n")
    call append(line('$') - correction, xline)
  endfor
endfunction

" make new zettel from a file. the file contents will be copied to a new
" zettel, the original file contents will be replaced with the zettel filename
" use temporary file if you want to keep the original file
function! vimroam#zettel#zettel_capture(wnum,...)
  let origfile = expand("%")
  execute "set ft=vimroam"
  " This probably doesn't work with current vimroam code
  if a:wnum > vimroam#vars#number_of_wikis()
    echomsg 'VimRoam Error: Wiki '.a:wnum.' is not registered in g:vimroam_list!'
    return
  endif
  if a:wnum > 0
    let idx = a:wnum
  else
    let idx = 0
  endif
  let title = vimroam#zettel#get_title(origfile)
  let format = vimroam#zettel#new_zettel_name(title)
  " let link_info = vimroam#base#resolve_link(format)
  let newfile = vimroam#zettel#save_wiki_page(format, idx)
  " delete contents of the captured file
  execute "normal! ggdG"
  " replace it with a address of the zettel file
  execute "normal! i" . newfile 
  execute "w"
  " open the new zettel
  execute "e " . newfile
endfunction

" based on vimroams "get wiki links", not stripping file extension
function! vimroam#zettel#get_wikilinks(wiki_nr, also_absolute_links)
  let files = vimroam#base#find_files(a:wiki_nr, 0)
  if a:wiki_nr == vimroam#vars#get_bufferlocal('wiki_nr')
    let cwd = vimroam#path#wikify_path(expand('%:p:h'))
  elseif a:wiki_nr < 0
    let cwd = vimroam#vars#get_wikilocal('path') . vimroam#vars#get_wikilocal('diary_rel_path')
  else
    let cwd = vimroam#vars#get_wikilocal('path', a:wiki_nr)
  endif
  let result = []
  for wikifile in files
    let wikifile = vimroam#path#relpath(cwd, wikifile)
    call add(result, wikifile)
  endfor
  if a:also_absolute_links
    for wikifile in files
      if a:wiki_nr == vimroam#vars#get_bufferlocal('wiki_nr')
        let cwd = vimroam#vars#get_wikilocal('path')
      elseif a:wiki_nr < 0
        let cwd = vimroam#vars#get_wikilocal('path') . vimroam#vars#get_wikilocal('diary_rel_path')
      endif
      let wikifile = '/'.vimroam#path#relpath(cwd, wikifile)
      call add(result, wikifile)
    endfor
  endif
  return result
endfunction

" add link with title of the file referenced in the second argument to the
" array in the first argument
function! s:add_bulleted_link(lines, abs_filepath)
  let bullet = repeat(' ', vimroam#lst#get_list_margin()) . vimroam#lst#default_symbol().' '
  call add(a:lines, bullet.
        \ vimroam#zettel#get_link(a:abs_filepath))
  return a:lines
endfunction

  

" insert list of links to the current page
function! s:insert_link_array(title, lines)
  let links_rx = '\m^\s*'.vimroam#u#escape(vimroam#lst#default_symbol()).' '
  call vimroam#zettel#update_listing(a:lines, a:title, links_rx)
endfunction


" based on vimroams "generate links", adding the %title to the link
function! vimroam#zettel#generate_links()
  let lines = []

  let links = vimroam#zettel#get_wikilinks(vimroam#vars#get_bufferlocal('wiki_nr'), 0)
  call reverse(sort(links))

  let bullet = repeat(' ', vimroam#lst#get_list_margin()) . vimroam#lst#default_symbol().' '
  for link in links
    let abs_filepath = vimroam#path#abs_path_of_link(link)
    "let abs_filepath = link
    "if !s:is_diary_file(abs_filepath)
      call add(lines, bullet.
            \ vimroam#zettel#get_link(abs_filepath))
    "endif
  endfor
  call s:insert_link_array('Generated Index', lines)
endfunction


" test if link in the Backlinks section
function! s:is_in_backlinks(file, filenamepattern)
  let f = readfile(a:file)
  let content = join(f, "\n")
  " search for backlinks section
  let backlinks_pattern = printf(s:section_pattern, g:zettel_backlinks_title)
  let backlinks_pos = matchstrpos(content, backlinks_pattern)
  " if we cannot find backlinks in the page return false
  if backlinks_pos[1] == -1 
    return -1
  endif
  let file_pos = matchstrpos(content, a:filenamepattern)
  " link is in backlinks when it is placed after the Backlinks section title
  return backlinks_pos[1] < file_pos[1]
endfunction


" based on vimroams "backlinks"
" insert backlinks of the current page in a section
function! vimroam#zettel#backlinks()
  let current_filename = expand("%:t:r")
  " find [filename| or [filename] to support both wiki and md syntax
  let filenamepattern = printf(s:grep_link_pattern, current_filename)
  let locations = []
  let backfiles = vimroam#zettel#wikigrep(filenamepattern)
  for file in backfiles
    " only add backlink if it is not already backlink
    let is_backlink = s:is_in_backlinks(file, current_filename)
    if is_backlink < 1
      " Make sure we don't add ourselves
      if !(file ==# expand("%:p"))
        call s:add_bulleted_link(locations, file)
      endif
    endif
  endfor

  if empty(locations)
    echomsg 'Vimzettel: No other file links to this file'
  else
    call uniq(locations)
    " Insert back links section
    call s:insert_link_array(g:zettel_backlinks_title, locations)
  endif
endfunction

function! vimroam#zettel#inbox()
  call vimroam#base#check_links()
  let linklist = getqflist()
  cclose
  let paths = []
  " normalize the current wiki path
  let cwd = fnamemodify(vimroam#vars#get_wikilocal('path'), ":p:h")
  let bullet = repeat(' ', vimroam#lst#get_list_margin()) . vimroam#lst#default_symbol().' '
  for d in linklist
    " detect files that are not reachable from the wiki index
    let filenamematch = matchstr(d.text,'\zs.*\ze is not reachable')
    if filenamematch != "" && filereadable(filenamematch)
      " use only files from the current wiki, we get files from all registered
      " wikis here
      let filepath = fnamemodify(filenamematch, ":p:h")
      if filepath ==# cwd
        call add(paths, bullet.
              \ vimroam#zettel#get_link(filenamematch))
      endif
    endif
  endfor
  if empty(paths)
  else
    " remove duplicates and insert inbox section
    call uniq(paths)
    call s:insert_link_array('Unlinked Notes', paths)
  endif

endfunction

" based on vimroam
"   Loads tags metadata from file, returns a dictionary
function! s:load_tags_metadata() abort
  let metadata_path = vimroam#tags#metadata_file_path()
  if !filereadable(metadata_path)
    return {}
  endif
  let metadata = {}
  for line in readfile(metadata_path)
    if line =~ s:tag_pattern
      continue
    endif
    let parts = matchlist(line, '^\(.\{-}\);"\(.*\)$')
    if parts[0] == '' || parts[1] == '' || parts[2] == ''
      throw 'VimRoamTags1: Metadata file corrupted'
    endif
    let std_fields = split(parts[1], '\t')
    if len(std_fields) != 3
      throw 'VimRoamTags2: Metadata file corrupted'
    endif
    let vw_part = parts[2]
    if vw_part[0] != "\t"
      throw 'VimRoamTags3: Metadata file corrupted'
    endif
    let vw_fields = split(vw_part[1:], "\t")
    if len(vw_fields) != 1 || vw_fields[0] !~ '^vimroam:'
      throw 'VimRoamTags4: Metadata file corrupted'
    endif
    let vw_data = substitute(vw_fields[0], '^vimroam:', '', '')
    let vw_data = substitute(vw_data, '\\n', "\n", 'g')
    let vw_data = substitute(vw_data, '\\r', "\r", 'g')
    let vw_data = substitute(vw_data, '\\t', "\t", 'g')
    let vw_data = substitute(vw_data, '\\\\', "\\", 'g')
    let vw_fields = split(vw_data, "\t")
    if len(vw_fields) != 2
      throw 'VimRoamTags5: Metadata file corrupted'
    endif
    let pagename = vw_fields[0]
    let entry = {}
    let entry.tagname  = std_fields[0]
    let entry.filename  = std_fields[1]
    let entry.lineno   = std_fields[2]
    let entry.link     = vw_fields[1]
    if has_key(metadata, pagename)
      call add(metadata[pagename], entry)
    else
      let metadata[pagename] = [entry]
    endif
  endfor
  return metadata
endfunction

" based on vimroam
function! vimroam#zettel#generate_tags(...) abort
  let need_all_tags = (a:0 == 0)
  let specific_tags = a:000

  let metadata = s:load_tags_metadata()

  " make a dictionary { tag_name: [tag_links, ...] }
  let tags_entries = {}
  for entries in values(metadata)
    for entry in entries
      if has_key(tags_entries, entry.tagname)
        call add(tags_entries[entry.tagname], entry.filename)
      else
        let tags_entries[entry.tagname] = [entry.filename]
      endif
    endfor
  endfor

  let lines = []
  let bullet = repeat(' ', vimroam#lst#get_list_margin()).vimroam#lst#default_symbol().' '
  for tagname in sort(keys(tags_entries))
    if need_all_tags || index(specific_tags, tagname) != -1
      call extend(lines, [
            \ '',
            \ substitute(vimroam#vars#get_syntaxlocal('rxH2_Template'), '__Header__', tagname, ''),
            \ '' ])
      for taglink in reverse(sort(tags_entries[tagname]))
        let filepath = vimroam#path#abs_path_of_link(taglink)
        if filereadable(filepath)
          call add(lines, bullet . vimroam#zettel#get_link(filepath))
        endif
      endfor
    endif
  endfor

  let links_rx = '\m\%(^\s*$\)\|\%('.vimroam#vars#get_syntaxlocal('rxH2').'\)\|\%(^\s*'
        \ .vimroam#u#escape(vimroam#lst#default_symbol()).' '
        \ .vimroam#vars#get_syntaxlocal('rxWikiLink').'$\)'

  call vimroam#zettel#update_listing(lines, 'Generated Tags', links_rx)
endfunction
xmap M <Plug>ZettelImage
