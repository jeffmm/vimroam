" Transparent editing of gpg encrypted files.
augroup auto_encrypt
    au!
    " First make sure nothing is written to ~/.viminfo while editing
    " an encrypted file.
    autocmd BufReadPre,FileReadPre      *.gpg,*.asc set viminfo=
    " We don't want a swap file, as it writes unencrypted data to disk
    autocmd BufReadPre,FileReadPre      *.gpg,*.asc set noswapfile
    " Switch to binary mode to read the encrypted file
    autocmd BufReadPre,FileReadPre      *.gpg set bin
    autocmd BufReadPre,FileReadPre      *.gpg,*.asc let ch_save = &ch|set ch=2
    autocmd BufReadPre,FileReadPre      *.gpg,*.asc let shsave=&sh
    autocmd BufReadPre,FileReadPre      *.gpg,*.asc let &sh='sh'
    autocmd BufReadPre,FileReadPre      *.gpg,*.asc let ch_save = &ch|set ch=2
    autocmd BufReadPost,FileReadPost    *.gpg,*.asc '[,']!gpg --decrypt --default-recipient-self 2> /dev/null
    autocmd BufReadPost,FileReadPost    *.gpg,*.asc let &sh=shsave
    " Switch to normal mode for editing
    autocmd BufReadPost,FileReadPost    *.gpg,*.asc set nobin
    autocmd BufReadPost,FileReadPost    *.gpg,*.asc let &ch = ch_save|unlet ch_save
    autocmd BufReadPost,FileReadPost    *.gpg,*.asc execute ":doautocmd BufReadPost " . expand("%:r")
    " Options for encrypted markdown files  (wiki)
    autocmd BufReadPost,FileReadPost *.md.asc setlocal spell wrap linebreak
    autocmd BufReadPost,FileReadPost *.md.asc :CocDisable
    " autocmd BufReadPost,FileReadPost *.md.asc :Goyo
    autocmd BufReadPost,FileReadPost *.md.asc nmap j gj
    autocmd BufReadPost,FileReadPost *.md.asc nmap k gk
    autocmd BufReadPost,FileReadPost *.md.asc xmap j gj
    autocmd BufReadPost,FileReadPost *.md.asc xmap k gk
    " Convert all text to encrypted text before writing
    autocmd BufWritePre,FileWritePre    *.gpg,*.asc let a:view=winsaveview()
    autocmd BufWritePre,FileWritePre    *.gpg,*.asc set bin
    autocmd BufWritePre,FileWritePre    *.gpg,*.asc let shsave=&sh
    autocmd BufWritePre,FileWritePre    *.gpg,*.asc let &sh='sh'
    autocmd BufWritePre,FileWritePre    *.gpg '[,']!gpg --encrypt --default-recipient-self 2>/dev/null
    autocmd BufWritePre,FileWritePre    *.asc '[,']!gpg --encrypt --armor --default-recipient-self 2>/dev/null
    autocmd BufWritePre,FileWritePre    *.gpg,*.asc let &sh=shsave
    " Undo the encryption so we are back in the normal text, directly
    " after the file has been written.
    autocmd BufWritePost,FileWritePost  *.gpg,*.asc silent u
    autocmd BufWritePost,FileWritePost  *.gpg set nobin
    autocmd BufWritePost,FileWritePost  *.gpg,*.asc :call winrestview(a:view)
augroup END
