let s:dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source ' . s:dir . '/plugins.vim'
execute 'source ' . s:dir . '/opts.vim'
execute 'source ' . s:dir . '/keys.vim'
execute 'source ' . s:dir . '/misc.vim'
execute 'source ' . s:dir . '/local.vim'

if !exists('g:vscode')
    execute 'source ' . s:dir . '/coc.vim'
    execute 'source ' . s:dir . '/colors.vim'
end

lua require('treesitter')
