"""
" Required:  this script requires Vim 7.0 (or later) 
" * Plug 'LucHermitte/lh-vim-lib'
"
" Recommended: 
" * Plug 'junegunn/fzf'
" * Plug 'junegunn/fzf.vim' 
" * Plug 'tpope/vim-dispatch'
"
" g:bake_make_cmd contains executable command (:make or :Make)
" g:bake_custom_args: additional arguments for bake that will always concatenate with Bake command
" let s:bake_current_project = " "
"""
if exists('g:loaded_bake')
    finish
endif
let g:loaded_bake = 1

" custom bake arguments that would be concatenated to every Bake command whene executed
let g:bake_custom_args = get(g:, 'bake_custom_args', "")

" bake history command buffer size (count of elements, by deafault: 10)
let g:bake_cmd_buffer_size = get(g:, 'bake_cmd_buffer_size', 10)

" path where bake history commands is stored
let s:bake_default_config_path = lh#path#join([expand('<sfile>:p:h:h'), "bake_cfg", "last_cmd.txt"])
let g:bake_config_path = get(g:, 'bake_config_path', s:bake_default_config_path)

" Detect if Dispatch plugin installed to use :Make
autocmd VimEnter *
            \  if exists(':Make')
            \|     let g:bake_make_cmd = get(g:, 'bake_make_cmd', "Make ")
            \| else
            \|     let g:bake_make_cmd = get(g:, 'bake_make_cmd', "make ")
            \| endif

let g:bake_arguments = ['-m', '-b',
            \'-f',
            \'-c',
            \'-a',
            \'-v',
            \'-r',
            \'-w',
            \'--list',
            \'--rebuild',
            \'--clobber',
            \'--prepro',
            \'--link-only',
            \'--compile-only',
            \'--no-case-check',
            \'--generate-doc',
            \'--ignore-cache',
            \'-j',
            \'-O',
            \'-D',
            \'--socket',
            \'--toolchain-info',
            \'--toolchain-names',
            \'--dot',
            \'--dotc',
            \'--dot-project-level',
            \'--do',
            \'--omit',
            \'--abs-paths',
            \'--abs-paths-in',
            \'--abs-paths-out',
            \'--Wparse',
            \'--no-autodir',
            \'--set',
            \'--adapt',
            \'--incs-and-defs=json',
            \'--incs-and-defs=bake',
            \'--conversion-info',
            \'--roots',
            \'--file-list'
            \'--prebuild',
            \'--compilation-db [<fn>]',
            \'--create exe|lib|custom',
            \'--nb',
            \'--crc32',
            \'--diab-case-check',
            \'--file-cmd',
            \'--link-beta',
            \'--version',
            \'--time',
            \'--doc',
            \'--dry',
            \]

set makeprg=bake


command -nargs=1 -complete=customlist,bake#list_arguments Bake call bake#execute(<f-args>)

" Build with last used arguments
nnoremap  <expr> <plug>(BakeBuildLast) bake#build_last()
nnoremap  <expr> <plug>(BakeBuildThis) bake#build_this()

fun! s:bake_load_fzf_functions()
    command! -bang -nargs=* BakeProjects call fzf#run(
                \fzf#wrap(fzf#vim#with_preview({'source': bake#get_list_of_projects(',')[1]})), <bang>0)

    nnoremap <silent> <plug>(BakeShowTargets) :call bake#show_project_targets()<CR>


    command! -bang -nargs=* BakeHist call fzf#vim#command_history({'source': extend([' :: Press CTRL-E to edit'],
                \map(range(1, len(bake#get_cmd_buffer())), 'v:val."  ".bake#get_cmd_buffer()[v:key]'))})
endfun

autocmd VimEnter * if exists('g:loaded_fzf_vim') | call s:bake_load_fzf_functions()  | endif
