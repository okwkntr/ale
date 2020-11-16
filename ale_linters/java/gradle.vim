" Author: okawa
" Description: Lints java files using gradle

let s:classpath_sep = has('unix') ? ':' : ';'

call ale#Set('java_gradle_executable', 'gradle')
call ale#Set('java_gradle_options', '')

function! ale_linters#java#gradle#BuildProject(buffer) abort
    let l:project_root = ale#gradle#FindProjectRoot(a:buffer)
    let l:command = ale#path#CdString(l:project_root)
    let l:command = l:command . ' %e gradle build'
    let b:ale_filename_mappings = {
    \    'gradle': [
    \        [l:project_root, '/data'],
    \    ],
    \}
    return l:command
endfunction

function! s:BuildClassPathOption(buffer, import_paths) abort
    " Filter out lines like [INFO], etc.
    let l:class_paths = filter(a:import_paths[:], 'v:val !~# ''[''')
    let l:cls_path = ale#Var(a:buffer, 'java_javac_classpath')

    if !empty(l:cls_path) && type(l:cls_path) is v:t_string
        call extend(l:class_paths, split(l:cls_path, s:classpath_sep))
    endif

    if !empty(l:cls_path) && type(l:cls_path) is v:t_list
        call extend(l:class_paths, l:cls_path)
    endif

    return !empty(l:class_paths)
    \   ? '-cp ' . ale#Escape(join(l:class_paths, s:classpath_sep))
    \   : ''
endfunction

function! ale_linters#java#gradle#GetCommand(buffer, import_paths, meta) abort
    let l:executable = ale#gradle#FindExecutable(a:buffer)
    let l:project_root = ale#gradle#FindProjectRoot(a:buffer)
    if !empty(l:executable) && !empty(l:project_root)
        return ale#path#CdString(l:project_root)
    endif
    return ''
endfunction

function! ale_linters#java#gradle#Handle(buffer, lines) abort
    " Look for lines like the following.
    "
    "> Task :compileJava FAILED
    "/data/app/src/main/java/app/App.java:8: error: ';' expected
    "       return "Hello world."
    "                            ^
    "1 error

    " Main.java:13: warning: [deprecation] donaught() in Testclass has been deprecated
    " Main.java:16: error: ';' expected
    let l:directory = expand('#' . a:buffer . ':p:h')
    let l:pattern = '\v^(.*):(\d+): (.{-1,}):(.+)$'
    let l:col_pattern = '\v^(\s*\^)$'
    let l:symbol_pattern = '\v^ +symbol: *(class|method) +([^ ]+)'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, [l:pattern, l:col_pattern, l:symbol_pattern])
        if empty(l:match[2]) && empty(l:match[3])
            let l:output[-1].col = len(l:match[1])
        elseif empty(l:match[3])
            " Add symbols to 'cannot find symbol' errors.
            if l:output[-1].text is# 'error: cannot find symbol'
                let l:output[-1].text .= ': ' . l:match[2]
            endif
        else
            call add(l:output, {
            \   'filename': ale#path#GetAbsPath(l:directory, l:match[1]),
            \   'lnum': l:match[2] + 0,
            \   'text': l:match[3] . ':' . l:match[4],
            \   'type': l:match[3] is# 'error' ? 'E' : 'W',
            \})
        endif
    endfor

    let g:output_saved = l:output
    return l:output
endfunction

call ale#linter#Define('java', {
\   'name': 'gradle',
\   'executable': {b -> ale#Var(b, 'java_gradle_executable')},
\   'command': function('ale_linters#java#gradle#BuildProject'),
\   'output_stream': 'stderr',
\   'callback': 'ale_linters#java#gradle#Handle',
\})
