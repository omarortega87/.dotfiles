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

"" inoremap ' ''<esc>i
"" inoremap " ""<esc>i
"" inoremap ( ()<esc>i
"" inoremap { {}<esc>i
"" inoremap [ []<esc>i

 let mapleader = ' '   " Map the leader key to a comma.

" Plugins will be downloaded under the specified directory.
 call plug#begin('~/.vim/plugged')
" Declare the list of plugins.
Plug 'neovim/nvim-lspconfig'
"Plug 'nvim-lua/completion-nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'
Plug 'sainnhe/sonokai'
Plug 'lukas-reineke/indent-blankline.nvim'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" For vsnip users.
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
 " List ends here. Plugins become visible to Vim after this call.

 call plug#end()

" colorscheme gruvbox
"Vim-Script:
"let g:material_style = 'oceanic'
" Important!!
        if has('termguicolors')
          set termguicolors
        endif
        " The configuration options should be placed before `colorscheme sonokai`.
        let g:sonokai_style = 'andromeda'
        let g:sonokai_enable_italic = 1
        let g:sonokai_disable_italic_comment = 1
        colorscheme sonokai

 let g:airline_theme = 'sonokai'
 
        let g:lightline = {}
        let g:lightline.colorscheme = 'sonokai'
        " Or this line:
        let g:lightline = {'colorscheme' : 'sonokai'}

        "identation
let g:indent_blankline_char_list = ['|', '¦', '┆', '┊']
let g:indent_blankline_use_treesitter = v:true
let g:indent_blankline_show_current_context = v:true
let g:indent_blankline_space_char_blankline = ' '
"set background=dark
"Lightline setup
"let g:lightline = {
"      \ 'colorscheme': 'wombat',
"      \ 'active': {
"      \   'left': [ [ 'mode', 'paste' ],
"      \             [ 'readonly', 'filename', 'modified', 'helloworld' ] ]
"      \ },
"      \ }

"NerdTree
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

" if hidden is not set, TextEdit might fail.
set hidden

"" AutoCompletion setup
"autocmd FileType java set omnifunc=v:lua.vim.lsp.omnifunc
"autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
"autocmd InsertLeave * if pumvisible() == 0|pclose|endif

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

lua << EOF
require'lspconfig'.pyright.setup{}
EOF

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

" LSP config (the mappings used in the default file don't quite work right)

nnoremap <silent> ef <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> <C-n> <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> <C-p> <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

" auto-format
autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 100)
"autocmd BufWritePre *.java lua vim.lsp.buf.formatting_sync(nil, 100)
"autocmd BufWritePre *.java lua vim.lsp.buf.formatting_seq_sync(nil, 100)


" Treesitter installation
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ignore_install = { "javascript" }, -- List of parsers to ignore installing
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = { "c", "rust" },  -- list of language that will be disabled
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
EOF

set completeopt=menu,menuone,noselect

lua <<EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
      end,
    },
    mapping = {
      ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
      ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
      ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
      ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ['<C-e>'] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  require('lspconfig')['pyright'].setup {
    capabilities = capabilities
  }
EOF
