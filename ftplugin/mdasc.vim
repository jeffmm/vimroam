" Don't save backups of *.gpg files
set backupskip+=*.gpg,*.asc

augroup encrypted
  au!
  " Disable swap files, viminfo, and set binary file format before reading the file
  autocmd BufReadPre,FileReadPre *.gpg,*.asc
              \ set viminfo= |
              \ setlocal noswapfile
  autocmd BufReadPre,FileReadPre *.gpg setlocal bin
  " Decrypt the contents after reading the file, reset binary file format
  " and run any BufReadPost autocmds matching the file name without the .gpg
  " extension
  autocmd BufReadPost,FileReadPost *.gpg,*.asc
              \ execute "'[,']!gpg --decrypt --default-recipient-self 2> /dev/null" |
              \ setlocal nobin |
              \ execute "doautocmd BufReadPost " . expand("%:r")
  " Set binary file format and encrypt the contents before writing the file
  autocmd BufWritePre,FileWritePre *.gpg,*.asc
              \ let window_view=winsaveview()
  autocmd BufWritePre,FileWritePre *.gpg
              \ setlocal bin |
              \ execute "'[,']!gpg --encrypt --default-recipient-self 2> /dev/null"
  autocmd BufWritePre,FileWritePre *.asc
              \ execute "'[,']!gpg --encrypt --armor --default-recipient-self 2> /dev/null"
  " After writing the file, do an :undo to revert the encryption in the
  " buffer, and reset binary file format
  autocmd BufWritePost,FileWritePost *.gpg,*.asc
              \ silent u |
              \ setlocal nobin |
              \ call winrestview(window_view) |
              \ let window_view=""
augroup END
