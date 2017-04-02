" ######################################################################################################################
" ### Author : Martin Toma <martin.toma.svk@gmail.com>                                                               ###
" ######################################################################################################################
" ### Neovim Configuration focused on Web development                                                                ###
" ### Neovimmer since : Tue Oct 14 2014                                                                              ###
" ### Vimmer since    : Tue Nov 12 2013                                                                              ###
" ######################################################################################################################

" ======================================================================================================================
" 1.0 Plugin manager (Plug) settings
" ======================================================================================================================

"{{{

" Autoinstall {{{
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif
" }}}
call plug#begin('~/.config/nvim/plugged')

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" 1.1 Plugin list
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" ---------------------------------------------------------------------------------------------------------------------
" Language agnostic plugins {{{
" ---------------------------------------------------------------------------------------------------------------------

" Asynchronous maker and linter (needs linters to work)
Plug 'benekastah/neomake', { 'on': ['Neomake'] }
" Autocomplete
Plug 'Shougo/deoplete.nvim'
" Automatically closing pair stuff
Plug 'cohama/lexima.vim'
" Snippet support (C-j)
Plug 'SirVer/ultisnips'
" Commenting support (gc)
Plug 'tpope/vim-commentary'
" CamelCase and snake_case motions
Plug 'bkad/CamelCaseMotion'
" Heuristically set indent settings
Plug 'tpope/vim-sleuth'
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Ruby/Rails {{{
" ---------------------------------------------------------------------------------------------------------------------

" Ruby support (plays nicely with tpope/rbenv-ctags)
Plug 'vim-ruby/vim-ruby'
" Slim syntax
Plug 'slim-template/vim-slim'
" Haml syntax
Plug 'tpope/vim-haml'
" Minitest syntax
Plug 'sunaku/vim-ruby-minitest'
" Rails support (:A, :R, :Rmigration, :Rextract)
Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }
" Bundler support (plays nicely with tpope/gem-ctags)
Plug 'tpope/vim-bundler', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" JS (ES6, React) {{{
" ---------------------------------------------------------------------------------------------------------------------

" Moder JS support (indent, syntax, etc)
Plug 'pangloss/vim-javascript'
" JSX syntax
Plug 'mxw/vim-jsx'
" Typescript syntax
Plug 'leafgarland/typescript-vim'
" JSON syntax
Plug 'sheerun/vim-json'
" Autocomplete (npm install -g tern)
Plug 'carlitux/deoplete-ternjs'
" Autocomplete using flow (npm install -g flow-bin)
Plug 'steelsojka/deoplete-flow'
" JS Documentation comments
Plug 'heavenshell/vim-jsdoc', { 'on': ['JsDoc'] }
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" HTML/CSS {{{
" ---------------------------------------------------------------------------------------------------------------------

" HTML5 syntax
Plug 'othree/html5.vim'
" SCSS syntax
Plug 'cakebaker/scss-syntax.vim'
" Color highlighter
Plug 'lilydjwg/colorizer', { 'for': ['css', 'sass', 'scss', 'less', 'html', 'xdefaults', 'javascript', 'javascript.jsx'] }
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Other languages {{{
" ---------------------------------------------------------------------------------------------------------------------

" Elixir syntax
Plug 'elixir-lang/vim-elixir'
" Elm support
Plug 'ElmCast/elm-vim'
" Yaml indentation
Plug 'martin-svk/vim-yaml'
" Markdown syntax
Plug 'tpope/vim-markdown'
" Git syntax
Plug 'tpope/vim-git'
" Tmux syntax
Plug 'keith/tmux.vim'
" Dockerfile
Plug 'honza/dockerfile.vim'
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Unite fuzzy searcher {{{
" ---------------------------------------------------------------------------------------------------------------------

" Unite files, buffers, etc. sources
Plug 'Shougo/unite.vim'
" Outline source
Plug 'Shougo/unite-outline'
" History/yank source
Plug 'Shougo/neoyank.vim'
" Tag source
Plug 'tsukkee/unite-tag'
" Ag wrapper (Unite grep alternative) search and edit
Plug 'dyng/ctrlsf.vim', { 'on': ['CtrlSF', 'CtrlSFToggle'] }
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Interface improving {{{
" ---------------------------------------------------------------------------------------------------------------------

" Nerdtree file browser
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeFind', 'NERDTreeToggle'] }
" Lightline (simple status line)
Plug 'itchyny/lightline.vim'
" Buffers tabline
Plug 'ap/vim-buftabline'
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" External tools integration plugins {{{
" ---------------------------------------------------------------------------------------------------------------------

" Fugitive
Plug 'tpope/vim-fugitive'
" Git log viewer (Gitv! for file mode)
Plug 'gregsexton/gitv', { 'on': 'Gitv' }
" Git changes showed on line numbers
Plug 'airblade/vim-gitgutter'
" REST Console
Plug 'diepm/vim-rest-console', { 'for': 'rest' }
" Color picker
Plug 'KabbAmine/vCoolor.vim', { 'on': ['VCoolor', 'VCase'] }
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Text insertion/manipulation {{{
" ---------------------------------------------------------------------------------------------------------------------

" Surround (cs"')
Plug 'tpope/vim-surround'
" Easy alignment
Plug 'godlygeek/tabular', { 'on':  'Tabularize' }
" Safely editing in isolation
Plug 'ferranpm/vim-isolate', { 'on':  ['Isolate', 'UnIsolate'] }
" Cycling related words via C-a C-x (i.e. true/false)
Plug 'zef/vim-cycle'
" Titlecase motion (gt)
Plug 'christoomey/vim-titlecase'
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Extra text objects {{{
" ---------------------------------------------------------------------------------------------------------------------

" Custom text objects creation (dependency for the latter)
Plug 'kana/vim-textobj-user'
" Argument text object (via, >a)
Plug 'PeterRincker/vim-argumentative'
" Indent text object (vii)
Plug 'kana/vim-textobj-indent'
" Line text object (vil)
Plug 'kana/vim-textobj-line'
" Entire buffer text object (vae)
Plug 'kana/vim-textobj-entire'
" Ruby block text object (vir)
Plug 'nelstrom/vim-textobj-rubyblock'
" Comment text object (vac)
Plug 'glts/vim-textobj-comment'
" XML attribute
Plug 'whatyouhide/vim-textobj-xmlattr'
" Improved targets line cin) next parens
Plug 'wellle/targets.vim'
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Colorschemes {{{
" ---------------------------------------------------------------------------------------------------------------------

" Hybrid
Plug 'w0ng/vim-hybrid'
" Badwolf
Plug 'sjl/badwolf'
" Molokai
Plug 'tomasr/molokai'
" Iceberg
Plug 'cocopon/iceberg.vim'
" Tender
Plug 'jacoborus/tender.vim'
"}}}

" ---------------------------------------------------------------------------------------------------------------------
" Other {{{
" ---------------------------------------------------------------------------------------------------------------------

" Easily expand selected region
Plug 'terryma/vim-expand-region'
" Search for highlighted word with *
Plug 'thinca/vim-visualstar'
" Improve star by not jumping immediately
Plug 'ironhouzi/vim-stim'
" Intelligent buffer closing
Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }
" Iabbrev auto-correction library
Plug 'chip/vim-fat-finger'
" Matchit enhances jump motions
Plug 'tmhedberg/matchit'
" More . repeat functionality
Plug 'tpope/vim-repeat'
" Delete all but current buffer
Plug 'vim-scripts/BufOnly.vim', { 'on': 'Bonly' }
" Populate arglist with buffers in quickfix list
Plug 'nelstrom/vim-qargs', { 'on': 'Qargs' }
" Asks if you wanted to open existing file
Plug 'EinfachToll/DidYouMean'
" Codi interactive REPL like editing
Plug 'metakirby5/codi.vim', { 'on': 'Codi' }
"}}}

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" 1.2 End of plugin declaration
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
call plug#end()
"}}}


