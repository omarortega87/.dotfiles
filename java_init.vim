syntax on                  " Enable syntax highlighting.
filetype plugin indent on  " Enable file type based indentation.
"set directory=$HOME/.vim/swap//
set t_Co=256
set laststatus=2

let g:currentmode={
       \ 'n'  : 'NORMAL ',
       \ 'v'  : 'VISUAL ',
       \ 'V'  : 'V·Line ',
       \ '' : 'V·Block ',
       \ 'i'  : 'INSERT ',
       \ 'R'  : 'R ',
       \ 'Rv' : 'V·Replace ',
       \ 'c'  : 'Command ',
       \}

set statusline=
set statusline+=\ %{toupper(g:currentmode[mode()])}
set statusline+=%{&modified?'[+]':''}
"" use highlight group User2

set autoindent             " Respect indentation when starting a new line.
set expandtab              " Expand tabs to spaces. Essential in Python.
set tabstop=4              " Number of spaces tab is counted for.
set shiftwidth=4           " Number of spaces to use for autoindent.
silent! helptags ALL       " Load help files for all plugins"
set backspace=2            " Fix backspace behavior on most terminals.

" Navigate windows with <Ctrl-hjkl> instead of <Ctrl-w> followed by hjkl.
 noremap <c-h> <c-w><c-h>
 noremap <c-j> <c-w><c-j>
 noremap <c-k> <c-w><c-k>
 noremap <c-l> <c-w><c-l>

 set wildmenu                    " Enable enhanced tab autocomplete.
 set wildmode=list:longest,full  " Complete till longest string, then open

 set number                      " Display column numbers.
 set relativenumber              " Display relative column numbers.
"
 set hlsearch                    " Highlight search results.
 set incsearch                   " Search as you type.
"set clipboard=unnnamed,unnamedplus "Copy into system (*, +)registers"
"
" " Map arrow keys nothing so I can get used to hjkl-style movement.
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

 nmap <left>  :3wincmd <<cr>
 nmap <right> :3wincmd ><cr>
 nmap <up>    :3wincmd +<cr>
 nmap <down>  :3wincmd -<cr>

 inoremap ' ''<esc>i
 inoremap " ""<esc>i
 inoremap ( ()<esc>i
 inoremap { {}<esc>i
 inoremap [ []<esc>i

 let mapleader = ' '   " Map the leader key to a comma.

" Plugins will be downloaded under the specified directory.
 call plug#begin('~/.vim/plugged')
" Declare the list of plugins.
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'mfussenegger/nvim-jdtls'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'morhetz/gruvbox'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'itchyny/lightline.vim'
 " List ends here. Plugins become visible to Vim after this call.

 call plug#end()

 colorscheme gruvbox
set background=dark
":CocInstall coc-java', ':CocInstall coc-omnisharp', ':CocInstall coc-tsserver', ':CocInstall coc-python', ':CocInstall coc-eslint']}  " code completion based on lang server
"Lightline setup
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified', 'helloworld' ] ]
      \ },
      \ }

" if hidden is not set, TextEdit might fail.
set hidden

" AutoCompletion setup
autocmd FileType java set omnifunc=v:lua.vim.lsp.omnifunc
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

"Setting up Java JDTLS on neovim 5
if has('nvim-0.5')
  augroup lsp
    au!
    au FileType java lua require('jdtls').start_or_attach({cmd = {'java-lsp.sh'}})
  augroup end
endif

"-- `code_action` is a superset of vim.lsp.buf.code_action and you'll be able to -- use this mapping also with other language servers
nnoremap <A-CR> <Cmd>lua require('jdtls').code_action()<CR>
vnoremap <A-CR> <Esc><Cmd>lua require('jdtls').code_action(true)<CR>
nnoremap <leader>r <Cmd>lua require('jdtls').code_action(false, 'refactor')<CR>

nnoremap <A-o> <Cmd>lua require'jdtls'.organize_imports()<CR>
nnoremap crv <Cmd>lua require('jdtls').extract_variable()<CR>
vnoremap crv <Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>
nnoremap crc <Cmd>lua require('jdtls').extract_constant()<CR>
vnoremap crc <Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>
vnoremap crm <Esc><Cmd>lua require('jdtls').extract_method(true)<CR>

" Tresitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
  },
}
EOF
"-- If using nvim-dap -- This requires java-debug and vscode-java-test bundles, see install steps in this README further below.
nnoremap <leader>df <Cmd>lua require'jdtls'.test_class()<CR>
nnoremap <leader>dn <Cmd>lua require'jdtls'.test_nearest_method()<CR>

"fzz"
" Empty value to disable preview window altogether
let g:fzf_preview_window = ''

" Always enable preview window on the right with 60% width
let g:fzf_preview_window = 'right:60%'

"FZF customazing "
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

" [[B]Commits] Customize the options used by 'git log':
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

" [Tags] Command to generate tags file
let g:fzf_tags_command = 'ctags -R'

" [Commands] --expect expression for directly executing the command
let g:fzf_commands_expect = 'alt-enter,ctrl-x'
nnoremap <silent> <leader>o :Files<CR>
nnoremap <silent> <leader>0 :Files!<CR>
nnoremap <silent> <leader>h :History<CR>
nnoremap <silent> <leader>b :Buffers<CR>

"JDT commands
command! -buffer JdtCompile lua require('jdtls').compile()
command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()
command! -buffer JdtJol lua require('jdtls').jol()
command! -buffer JdtBytecode lua require('jdtls').javap()
command! -buffer JdtJshell lua require('jdtls').jshell()


" Mappings for JDT
nnoremap <silent> <leader>d :lua vim.lsp.buf.definition()<CR> 
