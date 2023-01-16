" autocmd VimEnter * if exists(':Make') == 2 | let s:bake_make_cmd = "Bake " | else | let s:bake_make_cmd = "Bake " | endif

if !exists('*lh#path#join()')
    echoerr("Bake plugin requires Plug 'LucHermitte/lh-vim-lib'")
    finish
endif

let s:ProjectTarget = ""
let s:list_of_projects = {}
let s:list_of_projects_paths = {}
let s:bake_cmd_buffer = {}


fun! bake#get_cmd_buffer() abort
    let key = getcwd()
    return get(s:bake_cmd_buffer, key, [])
endfun

fun! s:bake_find_current_project_meta() abort
    let cur_folder = eval('expand("%:h")')
    if filereadable(cur_folder . "/Project.meta")
        let g:bake_cur_prj = cur_folder 
        return g:bake_cur_prj
    else 
        let depth = lh#path#depth(cur_folder)
        let folder_list = lh#path#split(cur_folder)
        while depth > 0
            let depth = depth - 1
            let folder_list = folder_list[:-2]

            let cur_folder = lh#path#join(folder_list)
            if filereadable(cur_folder . "/Project.meta")
                let g:bake_cur_prj = cur_folder 
                return g:bake_cur_prj
            endif
        endwhile 
    endif

    let g:bake_cur_prj = ""
    return g:bake_cur_prj
endfun

fun! s:bake_get_current_lib(libConfig, options)
    unlet! s:bake_args
    let PM = s:bake_find_current_project_meta()
    if PM == ""
        return 1
    endif

    let cmd = "-m " . PM
    if a:libConfig != ""
        let cmd = cmd . " -b " . a:libConfig
    endif 
    if a:options != ""
        let cmd = cmd . " " . a:options
    endif 

    let s:bake_args = cmd
    return cmd
endfun

fun! s:bake_get_args()
    return "Bake " . s:bake_args 
endfun

fun! bake#build_this()
    call s:bake_get_current_lib(eval('expand("<cword>")'), "")
    let cmd = s:bake_get_args()
    return ':'.cmd
endfun

fun! bake#build_last() abort
    if !exists('s:bake_args')
        return ":Bake " . g:bake_custom_args 
    endif
    let cmd = s:bake_get_args()
    return ':'.cmd
endfun

fun! s:Bake_load_hist() abort

    if filereadable(g:bake_config_path)
        "deserialize
        let buff = readfile(g:bake_config_path)[0]
        execute "let s:bake_cmd_buffer = ".buff

        let s:bake_cmd_buffer[getcwd()] = get(s:bake_cmd_buffer, getcwd(), [])

        let s:bake_args = get(s:bake_cmd_buffer[getcwd()],0, "")
        let s:bake_args = substitute(s:bake_args, "Bake ", "","")
    else
        let s:bake_cmd_buffer = {getcwd(): []}
        call mkdir(lh#path#join(lh#path#split(g:bake_config_path)[:-2]), 'p')
        call s:Bake_write_hist()
    endif
endfun

fun! s:Bake_write_hist() abort
    if writefile([string(s:bake_cmd_buffer)], g:bake_config_path)
        echoerr 'Bake: write ' . g:bake_config_path . ' error'
    endif
endfun

fun! s:Bake_add_hist(bake_cmd)
    let bake_cmd_e = escape(copy(a:bake_cmd), '\')

    " remove current command from the list 
    let s:bake_cmd_buffer[getcwd()] = filter(s:bake_cmd_buffer[getcwd()], 'v:val != "'.bake_cmd_e.'"')
    " paste current command to the biginning of the list
    let s:bake_cmd_buffer[getcwd()] = [a:bake_cmd] + s:bake_cmd_buffer[getcwd()][:g:bake_cmd_buffer_size]
    call s:Bake_write_hist()

endfun


fun! s:getModule(CmdLine)
    let tokens = split(a:CmdLine) 
    let pos = len(tokens)-1 
    while pos > 0
        if tokens[pos] == '-m' && len(tokens) > (pos+1)
            return tokens[pos+1]
        endif
        let pos = pos -1 
    endwhile 
    " didn't find -m -> return current folder 
    return "." 
endfun


fun! bake#execute(args)
    let s:bake_args = trim(substitute(trim(a:args), g:bake_custom_args, "", ""))

    let bake_cmd = "Bake " . s:bake_args
    call s:Bake_add_hist(bake_cmd)

    let cmd = g:bake_make_cmd . g:bake_custom_args . " " . s:bake_args  
    execute(cmd)
endfun

fun! s:list_of_files(path, expr)
    if executable('rg')
        return split(system('rg --files --no-ignore-vcs -g "'.a:expr.'"'))
    elseif executable('git')
        return split(system('git ls-files "**/'.a:expr.'"'))
    else
        return globpath(a:path, "**/".a:expr, 0,1)
    endif
endfun

" returns [[list of project names], [list of project paths]]
fun! bake#get_list_of_projects(path)
    let key = fnamemodify(a:path, ':p')
    if !has_key(s:list_of_projects, key) 
        let list_of_files = s:list_of_files(a:path, "Project.meta")
        let s:list_of_projects_paths[key] = copy(list_of_files)
        let s:list_of_projects[key] = map(list_of_files, "lh#path#split(v:val)[-2]")
    endif
    return [copy(s:list_of_projects[key]), copy(s:list_of_projects_paths[key])]
endfun

fun bake#list_arguments(ArgLead, CmdLine, CursorPos)
    let tokens = split(a:CmdLine[:a:CursorPos]) 
    let lead_char = a:CmdLine[a:CursorPos-1]
    let pos = len(tokens) 

    " filter wat's already in the arguments
    let ignore_patterns = '\v^(' . join(split(g:bake_custom_args), '|') . ')$'

    let params = copy(g:bake_arguments)

    if 1 == pos
        let res = filter(params, "v:val !~ '" . ignore_patterns . "'") 
    elseif tokens[pos-1] ==  "-b" 
        let res = system('bake -m ' . s:getModule(a:CmdLine) . ' --list | grep "*"')
        let res = substitute(res, '\*', '', '')
        let res = substitute(res, '(.*)', '', '')
        let res = filter(split(res), 'v:val != "*"') 

    elseif (tokens[pos-2] ==  "-b" && lead_char != " ") 
        let res = system('bake -m ' . s:getModule(a:CmdLine) . ' --list | grep *')
        let res = substitute(res, '\*', '', '')
        let res = substitute(res, '(.*)', '', '')
        let res = filter(split(res), 'v:val =~ "' . tokens[pos-1] . '"') 

    elseif tokens[pos-1] == '-m'
        let res = getcompletion('./', "dir")
    elseif ((tokens[pos-2] == '-m') && (lead_char != " "))
        let s:current_param = tokens[-1]
        let res = getcompletion(s:current_param, "dir")

    elseif tokens[pos-1] == '-p'
        let prj_path = s:bake_find_current_project_meta()
        if prj_path == ""
            let res = get(bake#get_list_of_projects(','), 0, [])
        else
            let prj_path = lh#path#split(prj_path)[-1]
            let res = [prj_path] + get(bake#get_list_of_projects(','), 0, [])
        endif
    elseif tokens[pos-2] == '-p'
        let s:current_param = tokens[-1]
        let res = filter(bake#get_list_of_projects(',')[0], 'v:val =~ "^' . tokens[pos-1] . '"')

    elseif tokens[pos-1] == '-f'
        let prj_path = lh#path#fix(s:bake_find_current_project_meta(), 1) . '/'
        if prj_path == "/"
            let res = getcompletion('./', "dir")
        else
            let cur_file = lh#path#fix(eval('expand("%")'), 1)
            "let file = lh#path#fix(substitute(cur_file, prj_path, '', ''))
            let file = cur_file[len(prj_path):]
            let all_src_files = map(globpath(prj_path, "**/*.cpp", 0,1), 'v:val[' . len(prj_path) . ':]')
            let res = [file] + all_src_files
        endif

    elseif lead_char == " "
        let res = filter(params, "v:val !~ '" . ignore_patterns . "'") 
    else
        let res = filter(params, 'v:val =~ "' . tokens[pos-1] . '"') 
        let res = filter(res, "v:val !~ '" . ignore_patterns . "'") 
    endif

    return res
endfun

function! s:bake_set_project_target(line)
    let s:ProjectTarget = trim(substitute(trim(substitute(a:line, '.*\*', '','')), '\s.*', '',''))
    call s:bake_get_current_lib(eval('s:ProjectTarget'), "")
    let cmd = s:bake_get_args()
    "execute cmd
    "paste command into commannd line for edit
    call histadd(':', cmd)
    redraw
    call feedkeys(':'."\<up>", 'n')
endfunction


function! bake#show_project_targets() abort
    call s:bake_find_current_project_meta()
    call fzf#run(fzf#wrap({'source': 'bake -m ' . g:bake_cur_prj . ' --list | grep -e "\*"', 'sink': function('<SID>bake_set_project_target')})) 
endfunction


" load command history with first load of the script
call s:Bake_load_hist()
