# Vim Bake

This VIM pluging provices some support for bake.

Fork from https://github.com/flxo/bake.vim

Bake.vim will add:
* Project.meta syntax style
* Bake command
    * plugin overwrites makeprg = bake
    * parses parameters:
        * -m
        * -b (will call bake --list on the specified project),
        * -p (shows list of sub-projects),
        * -f
* BakeHistory to navigate quickly through Bake commands that were used previously (uses FZF to render list)
* BakeProjects to find all Project.meta in the repository (uses FZF to render list)

Additionally you can specify key mapping in your vim.rc
```
nmap <C-b> <plug>(BakeShowTargets)  " will show possible targets for current file, uses FZF to render 
nmap <F9> <plug>(BakeBuildLast)     " paste last `Bake` command to command line `:Bake ...` 
nmap <F8> <plug>(BakeBuildThis)     " if you open Project.meta a set cursor on a target word (ex: UnitTest), it will paste `Bake -m myProject -b UnitTest

" arguments that will be concatenated with every :Bake command 
let g:bake_custom_args = "--time -O -r -j16 --abs-paths-out --compilation-db"  
```

<img src="https://raw.githubusercontent.com/maslovw/files/main/bake.vim.demo.gif" width=800>

## Installation 

### As Vim plugin

If you use [vim-plug](https://github.com/junegunn/vim-plug), add this to your Vim config file: 

```
Plug 'maslovw/bake.vim'
Plug 'LucHermitte/lh-vim-lib'  " provides some functions for bake plugin to work with path
```

#### Nice to have

##### Dispatch 
```
Plug 'tpope/vim-dispatch'
```

##### FZF

Read https://github.com/junegunn/fzf#installation

```
Plug 'junegunn/fzf'
```

