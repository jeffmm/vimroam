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

" Set default user options if they are not defined
if !exists('g:vimroam_zettel_options')
    let g:vimroam_zettel_options = [{"front_matter" : [["tags", ""]],
       \ "template" :  expand("<sfile>:p:h:h:h") . "/templates/zettel-template.tpl"}, {}]
endif

" get user option for the current wiki
" it seems that it is not possible to set custom options in g:vimroam_list
" so we need to use our own options
function! vimroam#zettel#get_option(name)
  if !exists('g:vimroam_zettel_options')
    return ""
  endif
  " the options for particular wikis must be in the same order as wiki
  " definitions in g:vimroam_list
  let idx = vimroam#vars#get_bufferlocal('wiki_nr')
  let option_number = "g:vimroam_zettel_options[" . idx . "]"
  if exists(option_number)
    if exists(option_number . "." . a:name)
      return g:vimroam_zettel_options[idx][a:name]
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
" add file extension when g:vimroam_markdown_link_ext is set
if exists("g:vimroam_markdown_link_ext") && g:vimroam_markdown_link_ext == 1
    let s:link_format = "[%title](%link.md)"
else
    let s:link_format = "[%title](%link)"
endif

let s:header_format = "%s: %s"
let s:header_delimiter = "---"
let s:insert_mode_title_format = "``l"
let s:grep_link_pattern = '/\(%s\.\{-}m\{-}d\{-}\)/' " match filename in  parens. including optional .md extension
let s:section_pattern = "# %s"

" enable overriding of 
if exists("g:zettel_link_format")
  let s:link_format = g:zettel_link_format
endif

let s:tag_pattern = '^!_TAG'
function! vimroam#zettel#update_listing(lines, title, links_rx)
  let generator = { 'data': a:lines }
  function generator.f() dict
        return self.data
  endfunction
  call vimroam#base#update_listing_in_buffer(generator, a:title, a:links_rx, line('$')+1, 1, 1)
endfunction

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

" default date format used in front matter for new zettel
if !exists('g:zettel_date_format')
  let g:zettel_date_format = "%Y%m%d"
endif

if !exists("g:zettel_template")
    let g:zettel_template = expand("<sfile>:p:h:h:h") . "/templates/zettel-template.tpl"
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
function! s:get_link(filename)
  let title =vimroam#zettel#get_title(a:filename)
  let wikiname = fnamemodify(a:filename, ":t:r")
  if title == ""
    " use the Zettel filename as title if it is empty
    let title = wikiname
  endif
  let link= vimroam#zettel#format_link(wikiname, title)
  return link
endfunction

function! vimroam#zettel#wiki_yank_name()
  let filename = expand("%")
  let link = s:get_link(filename)
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
  return vimroam#zettel#format_file_title(s:link_format, a:file, a:title)
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

" front_matter can be list or dict. if it is a dict, then convert it to list
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
  " g:vimroam_zettel_options for the current wiki
  let template = vimroam#zettel#get_option("template")
  if !empty(template)
    let variables = get(a:, 2, 0)
    if empty(variables)
      " save file, in order to prevent errors in variable reading
      execute "w"
      let variables = vimroam#zettel#prepare_template_variables(expand("%"), a:1)
      " backlink contains link to new note itself, so we will just disable it
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
  let variables.backlink = s:get_link(a:filename)
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
