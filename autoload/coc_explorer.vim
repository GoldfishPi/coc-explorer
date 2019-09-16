function! coc_explorer#create(bufnr, position, width, toggle, name)
  let status = coc_explorer#create_buffer(a:bufnr, a:position, a:width, a:toggle, a:name)

  if status ==# 'quit'
    return [-1, v:true]
  elseif status ==# 'create'
    let inited = exists('b:coc_explorer_inited')
    if ! inited
      let b:coc_explorer_inited = v:true
    endif

    call coc_explorer#init_buf()

    return [bufnr('%'), inited]
  else
    return [bufnr('%'), v:true]
  endif
endfunction

" returns is 'quit' or 'resume' or 'create'
function! coc_explorer#create_buffer(bufnr, position, width, toggle, name)
  let name = '['.a:name.']'
  if a:position ==# 'tab'
    execute 'silent keepalt tabnew '.name
    call coc_explorer#init_win(a:position, a:width)
    return 'create'
  else
    if a:bufnr != v:null
      " explorer in visible window
      let winnr = bufwinnr(a:bufnr)
      if winnr > 0
        if a:toggle
          execute winnr.'wincmd q'
          return 'quit'
        else
          execute winnr.'wincmd w'
          return 'resume'
        endif
      endif
    endif
    if a:position ==# 'left'
      wincmd t
      if a:bufnr == v:null
        execute 'silent keepalt leftabove vsplit '.name
      else
        execute 'silent keepalt leftabove vertical sb '.a:bufnr
      endif
      call coc_explorer#init_win(a:position, a:width)
      return 'create'
    elseif a:position ==# 'right'
      wincmd b
      if a:bufnr == v:null
        execute 'silent keepalt rightbelow vsplit '.name
      else
        execute 'silent keepalt rightbelow vertical sb '.a:bufnr
      endif
      call coc_explorer#init_win(a:position, a:width)
      return 'create'
    else
      throw 'No support position '.a:position
    endif
  endif
endfunction

function! coc_explorer#init_win(position, width)
  if a:position !=# 'tab'
    silent setlocal winfixwidth
    silent execute 'vertical resize '.a:width
  endif

  silent setlocal colorcolumn=
        \ conceallevel=0 concealcursor=nc nocursorcolumn
        \ nofoldenable foldcolumn=0
        \ nolist
        \ nonumber norelativenumber
        \ nospell
        \ nowrap
endfunction

function! coc_explorer#init_buf()
  silent setlocal buftype=nofile bufhidden=hide
        \ noswapfile nomodeline
        \ filetype=coc-explorer
        \ cursorline
        \ nomodifiable
        \ nomodified
        \ signcolumn=no
        \ nobuflisted
endfunction

function! coc_explorer#is_float_window(winnr)
  if has('nvim')
    let winid = win_getid(a:winnr)
    return nvim_win_get_config(winid)['relative'] != ''
  else
    return 0
  endif
endfunction


let s:select_wins_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

function! coc_explorer#select_wins_restore(store)
  for winnr in keys(a:store)
    call setwinvar(winnr, '&statusline', a:store[winnr])
  endfor
endfunction

" returns
"   -1  - User cancelled
"   0   - No window selected
"   > 0 - Selected winnr
function! coc_explorer#select_wins(explrer_bufname, filterFloatWindows)
  let store = {}
  let char_idx_mapto_winnr = {}
  let char_idx = 0
  let explorer_name = '['.a:explrer_bufname.']'
  for winnr in range(1, winnr('$'))
    if a:filterFloatWindows && coc_explorer#is_float_window(winnr)
      continue
    endif
    if bufname(winbufnr(winnr)) == explorer_name
      continue
    endif
    let store[winnr] = getwinvar(winnr, '&statusline')
    let char_idx_mapto_winnr[char_idx] = winnr
    let char = s:select_wins_chars[char_idx]
    let statusline = printf('%%#CocExplorerSelectUI#%s %s', repeat(' ', winwidth(winnr)/2-1), char)
    call setwinvar(winnr, '&statusline', statusline)
    let char_idx += 1
  endfor
  if len(char_idx_mapto_winnr) == 0
    call coc_explorer#select_wins_restore(store)
    return 0
  elseif len(char_idx_mapto_winnr) == 1
    call coc_explorer#select_wins_restore(store)
    return char_idx_mapto_winnr[0]
  else
    redraw!
    let select_winnr = -1
    while 1
      let nr = getchar()
      if nr == 27
        break
      else
        let select_winnr = get(char_idx_mapto_winnr, string(nr - char2nr('a')), -1)
        if select_winnr != -1
          break
        endif
      endif
    endwhile
    call coc_explorer#select_wins_restore(store)
    return select_winnr
  endif
endfunction

function! coc_explorer#add_matchids(ids)
  let w:coc_matchids = get(w:, 'coc_explorer_matchids', []) + a:ids
endfunction

function! coc_explorer#clearmatches(ids, ...)
  let winid = get(a:, 1, 0)
  if winid != 0 && win_getid() != winid
    return
  endif
  for id in a:ids
    try
      call matchdelete(id)
    catch /.*/
      " matches have been cleared in other ways,
    endtry
  endfor
  let exists = get(w:, 'coc_explorer_matchids', [])
  if !empty(exists)
    call filter(w:coc_matchids, 'index(a:ids, v:val) == -1')
  endif
endfunction

function! coc_explorer#register_mappings(mappings)
  let s:coc_explorer_mappings = a:mappings
  augroup coc_explorer_mappings
    au!
    autocmd FileType coc-explorer call coc_explorer#execute_mappings(s:coc_explorer_mappings)
  augroup END
endfunction

function! coc_explorer#execute_mappings(mappings)
  if &filetype == 'coc-explorer'
    for [key, target] in items(a:mappings)
      execute 'vmap <buffer> ' . key . ' ' . target
      execute 'nmap <buffer> ' . key . ' ' . target
    endfor
  endif
endfunction

function! coc_explorer#clear_mappings(mappings)
  if &filetype == 'coc-explorer'
    for [key, target] in items(a:mappings)
      execute 'vunmap <buffer> ' . key
      execute 'nunmap <buffer> ' . key
    endfor
  endif
endfunction
