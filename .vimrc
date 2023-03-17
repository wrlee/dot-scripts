" See http://amix.dk/vim/vimrc.html, http://nvie.com/posts/how-i-boosted-my-vim/

" 'hidden' hides buffers instead of closing them, allowing unwritten changes to a file and open a new file using :e, without being forced to write or undo your changes first. Also, undo buffers and marks are preserved while the buffer is open.
set hidden
"set verbose=9

if has('syntax')
	syntax enable
	colorscheme evening
	"hi Comment ctermfg=cyan
endif
if has('filetype')
	filetype plugin indent on
	filetype indent on
endif
set autoindent

if has('autocmd')
"	autocmd!
	autocmd BufNewFile,BufRead *.json set filetype=json
endif

" Show row,column at the bottom
set ruler
" Highlight search results
set hlsearch
" Makes search act like search in modern browsers
set incsearch
" Don't redraw while executing macros (good performance config)
set lazyredraw
" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4
" Return to last edit position when opening files (You want this!)
if has('autocmd')
	autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \    exe "normal! g`\"" |
     \ endif
endif
" Remember info about open buffers on close
set viminfo^=%
