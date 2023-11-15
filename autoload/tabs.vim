
" Script Name: tabs.vim
" Description: Change tab label and manage tabs (rename, move, switch, show tabs).
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies:
"
" NOTES:
"

"- functions -------------------------------------------------------------------

" Get the plugin reload command
" Cmd: _tabsrl
function! tabs#Reload()
    let l:pluginPath = substitute(s:plugin_path, "autoload", "plugin", "")
    let s:initialized = 0
    let l:cmd  = ""
    let l:cmd .= "unlet g:loaded_tabs "
    let l:cmd .= " | so ".s:plugin_path."/tabs.vim"
    let l:cmd .= " | so ".l:pluginPath."/tabs.vim"
    let l:cmd .= " | let g:loaded_tabs = 1"
    return l:cmd
endfunction


function! tabs#TablineRefresh()
    let l:pluginPath = substitute(s:plugin_path, "autoload", "plugin", "")
    unlet g:loaded_tabs "
    silent! exec("source ".s:plugin_path."/tabs.vim")
    silent! exec("source ".l:pluginPath."/tabs.vim")
    let g:loaded_tabs = 1"
endfunction


" Edit plugin files
" Cmd: Tabsedit
function! tabs#Edit()
    let l:plugin = substitute(s:plugin_path, "autoload", "plugin", "")
    silent exec("tabnew ".s:plugin)
    silent exec("vnew   ".l:plugin."/".s:plugin_name)
endfunction


function! s:TabsBarUpdate()
    if exists("+showtabline")
        redrawtabline
    endif
endfunction


function! tabs#LoadSavedTabNames()
    if exists("g:Tabs_names") && g:Tabs_names != ""
        let s:TabsNamesList = split(g:Tabs_names)
        redrawtabline
    else
        let s:TabsNamesList = []
    endif
endfunction


function! s:Initialize()
    if !exists("s:TabsNamesList")
        let s:TabsNamesList = []
    endif

    if exists("+showtabline")
        set stal=2
        set tabline=%!tabs#TabLine()
        set guitablabel=%{tabs#GuiTabLabel()}
      
        augroup TabsAutoCmd
            silent autocmd! TabNew    * call tabs#NewTab()
            silent autocmd! TabClosed * call tabs#CloseTab()
        augroup END
    endif
endfunction


function! s:Error(mssg)
    echohl errormsg | echom "[tabs.vim] ".a:mssg | echohl none
endfunction


function! s:Warn(mssg)
    echohl warningmsg | echom a:mssg | echohl none
endfunction


function! s:WindowSplitMenu(default)
    let w:winSize = winheight(0)
    "echo "w:winSize:".w:winSize | call input("continue")
    let text =  "split hor&izontal\n&split vertical\nnew &tab\ncurrent &window"
    let w:split = confirm("", l:text, a:default)
    redraw
endfunction


function! s:WindowSplit()
    if !exists('w:split')
        return
    endif

    let l:split = w:split
    let l:winSize = w:winSize

    if w:split == 1
        silent exec("sp! | enew")
    elseif w:split == 2
        silent exec("vnew")
    elseif w:split == 3
        silent exec("tabnew")
    elseif w:split == 4
        silent exec("enew")
    endif

    let w:split = l:split
    let w:winSize = l:winSize
endfunction


function! s:WindowSplitEnd()
    if exists('w:split')
        if w:split == 1
            if exists('w:winSize')
                "echo "w:winSize:".w:winSize | call input("continue")
                let lines = line('$') + 2
                if l:lines <= w:winSize
                    "echo "resize:".l:lines | call input("continue")
                    exe "resize ".l:lines
                else
                    "echo "resize:".w:winSize | call input("continue")
                    exe "resize ".w:winSize
                endif
            endif
            exe "normal! gg"
        endif
    endif
    silent! unlet w:winSize
    silent! unlet w:split
endfunction


" Open menu to manage the tabs.
" Arg1: refresh, launch as refresh.
" Arg1: refresh, launch as refresh.
" Arg3: pos, cursor position line.
" Commands: Tabsm, Tm
function! tabs#WindowManager(refresh, pos)
    "echom "tabs#WindowManager(".a:refresh.", ".a:pos.")"

    if expand("%") == "_tabs_manager_"
        if a:refresh == 0
            let s:tabsManagerMoveMode = 0
            silent! quit!
        "endif
        else
            normal ggVGd
        endif
    endif

    let l:tabinfolist = ["Tabs manager:" ]
    let l:tab = tabpagenr()
    let l:cursor = 2
    let l:tabsNum = tabpagenr('$')
    let l:buffNum = 0

    let i = 1
    while i <= tabpagenr('$')
        if l:i == l:tab
            let l:tabinfo = "> ".l:i.") "
            let l:cursor = l:i+1
        else
            let l:tabinfo = '  '.l:i.") "
        endif

        if exists("s:TabsNamesList")
            if len(s:TabsNamesList) >= l:i
                if s:TabsNamesList[l:i-1] != "" && s:TabsNamesList[l:i-1] != "."
                    let l:tabname = "[".s:TabsNamesList[l:i-1]."]"

                    if g:Tabs_manager_TabNamePadding != ""
                        let l:tabstr = l:tabname . repeat(' ', g:Tabs_manager_TabNamePadding - len(l:tabname))
                        let l:tabname = l:tabstr
                    endif
                    
                    let l:tabinfo .= l:tabname
                endif
            endif
        endif

        let l:buffinfo = ""
        let l:n = 1
        for l:bufnr in tabpagebuflist(i)
            let l:buffname = bufname(l:bufnr)
            if l:buffname != ""
                if l:n != 1
                    let l:buffinfo .= ", " 
                endif
                let l:buffinfo .= l:n.":".fnamemodify(l:buffname, ":t")
                let l:buffNum += 1
            endif
            let l:n += 1
        endfor

        if l:buffinfo != ""
            let l:tabinfo .= "(".l:buffinfo.")" 
        else
            let l:tabinfo .= "(empty)" 
        endif

        let l:tabinfolist += [l:tabinfo]
        let i += 1
    endwhile

    let l:tabinfolist += ["Commands: <enter>:switch to tab, c:close tab, M:move tab, r:rename tab, t:switch to tab and open tab manager, [0-9]:open window number."]
    let i += 1

    " Modify first line, add tabs number and buffer number.
    let l:tmp = l:tabinfolist[0]
    let l:tabinfolist[0] = l:tmp." found ".l:tabsNum." tabs and ".l:buffNum." buffers."

    if a:refresh == 0
        silent new
        silent wincmd J
    endif

    setl modifiable

    for l:line in l:tabinfolist
        silent put = l:line
    endfor
    silent normal ggdd

    if a:refresh == 0
        setl nowrap
        set buflisted
        set bufhidden=delete
        set buftype=nofile
        setl noswapfile
        set cursorline
    endif
    setl nomodifiable

    silent! exec '0file | file _tabs_manager_'

    if exists("g:Tabs_manager_MaxLines")
        if l:i < g:Tabs_manager_MaxLines
            silent exe "resize ".l:i
        else
            silent exe "resize ".g:Tabs_manager_MaxLines
        endif
    endif

    silent! exec("normal ".l:cursor."g")

    if exists('g:HiLoaded') && a:refresh == 0
        let g:HiCheckPatternAvailable = 0

        "if exists('g:Tabs_manager_infoHighlightColor') && g:Tabs_manager_infoHighlightColor != ""
            "silent! call hi#config#PatternColorize('Tabs manager: found', g:Tabs_manager_infoHighlightColor)
            "silent! call hi#config#PatternColorize('Commands:', g:Tabs_manager_infoHighlightColor)
        "endif

        if exists('g:Tabs_manager_tabNameHighlightColor') && g:Tabs_manager_tabNameHighlightColor != ""
            silent! call hi#config#PatternColorize('\[.*]', g:Tabs_manager_tabNameHighlightColor)
        endif

        if exists('g:Tabs_manager_selectedTabLineHighlightColor') && g:Tabs_manager_selectedTabLineHighlightColor != ""
            silent! call hi#config#PatternColorize('> ', g:Tabs_manager_selectedTabLineHighlightColor)
        endif

        if exists('g:Tabs_manager_buffersOnTabHighlightColor') && g:Tabs_manager_buffersOnTabHighlightColor != ""
            "silent! call hi#config#patterncolorize('(.*)', g:Tabs_manager_buffersOnTabHighlightColor)
            silent! call hi#config#PatternColorize(':.*\ ', g:Tabs_manager_buffersOnTabHighlightColor)
            silent! call hi#config#PatternColorize(':.\{-}, ', g:Tabs_manager_buffersOnTabHighlightColor)
        endif

        let g:HiCheckPatternAvailable = 1
    endif

    if a:refresh == ""
        redraw
        echo "[".s:plugin_name."] Use commands: <enter>: switch to tab, c: to close tab, M: to move tab, r: to rename tab, q: quit, t: switch to tab and open tab manager, [0-9]: open window number."
    endif

    if a:pos != ""
        let l:pos = a:pos
    else
        let l:pos = l:tab+1
    endif

    call s:TabsManagerUnmapKeys()
    silent exe "normal ".l:pos."G"
    call s:TabsManagerMapKeys()

    if a:refresh == 0
        augroup TabsManagerAutoCmd
            silent autocmd!
            "silent exec "silent autocmd! winenter _tabs_manager_ call tabs#TabsManagerMapKeys()"
            silent exec "silent autocmd! winleave _tabs_manager_ call tabs#UnmapKeysAndQuit()"
        augroup END
        "call s:TabsManagerMapKeys()
    endif
endfunction


" Tab switch.
" Select tab on current window manager line.
function tabs#WindowManagerSelectTab()
    "echom "tabs#WindowManagerSelectTab()"

    if s:tabsManagerMoveMode != 0
        call tabs#WindowManagerAction("move_end", "")
        redraw
        return
    endif

    " Check selected menu line number.
    let l:tabn = line(".") -1
    if l:tabn <= 0 || l:tabn > tabpagenr('$') 
        "call s:Warn("Position not selectable.")
        redraw
        return 0
    endif 

    if expand("%") == "_tabs_manager_"
        let s:tabsManagerMoveMode = 0
        silent! quit!
    endif

    silent! exec("normal ".l:tabn."gt")
    call tabs#Move("")
    return 1
endfunction


" Tab switch.
" Select tab on current window manager line and keep window 
" manager open
function tabs#WindowManagerSelectTabAndOpenTabManager()
    let l:line = line(".")

    if tabs#WindowManagerSelectTab() == 0
        return
    endif

    call tabs#WindowManager("refresh", "")
    redraw
endfunction


" Tab switch.
" Select tab on current window manager line and go to an
" specific window number.
function tabs#WindowManagerSelectTabAndWindow(winnr)
    if tabs#WindowManagerSelectTab() == 0
        return
    endif

    let l:winlast = len(tabpagebuflist(tabpagenr()))

    if a:winnr > l:winlast
        silent! exec(l:winlast."wincmd w")
    else
        silent! exec(a:winnr."wincmd w")
    endif
endfunction



let s:tabsManagerMoveModeOriginalTabNr = 0
let s:tabsManagerMoveMode = 0

" Manage user actions different than tab switch.
" Arg1: action: move, close or rename
function tabs#WindowManagerAction(action, option)
    "echom "tabs#WindowManagerAction(".a:action.", ".a:option.")"
    " Constants
    let l:headLines = 1
    let l:tailLines = 1

    " save current tab and line
    let l:tab = tabpagenr()
    let l:winnr = win_getid()
    let l:line = line(".")

    let l:doTabListRefresh = 0
    let l:doTabMenuRefresh = 0

    " Check selected menu line number.
    let l:tabSelPos = line(".") - l:headLines
    if l:tabSelPos <= 0 || l:tabSelPos > tabpagenr('$') 
        redraw
        call s:Warn("Line not selectable (out of list).")
        return
    endif 

    " get current tab name
    let l:tabname = ""
    if exists("s:TabsNamesList")
        if len(s:TabsNamesList) >= l:tabSelPos
            if s:TabsNamesList[l:tabSelPos-1] != "" && s:TabsNamesList[l:tabSelPos-1] != "."
                let l:tabname = " [".s:TabsNamesList[l:tabSelPos-1]."]"
            endif
        endif
    endif

    if a:action == "rename"
        if s:tabsManagerMoveMode != 0
            call s:Warn("[MOVE MODE] Select new postion and press enter.")
            return
        endif

        " rename the selected tab
        let l:name = input("Rename tab ".l:tabSelPos.l:tabname." as: ")
        call tabs#Rename(l:tabSelPos, l:name)

        let l:doTabListRefresh = 1
        let l:doTabMenuRefresh = 1

        redraw
        echo "[".s:plugin_name."] tab ".l:tabSelPos." name changed: ".l:name

    elseif a:action == "move_init"
        if s:tabsManagerMoveMode == 1
            return
        endif
        echom "================== move_init =================="
        let s:tabsManagerMoveMode = l:tabSelPos
        call s:TabsManagerMoveModeMapKeys()
        redraw
        call s:Warn("[MOVE MODE] Select new postion and press enter.")

    elseif a:action == "move_end"
        echom "================== move_end =================="
        if s:tabsManagerMoveMode == 0
            return
        endif
        let s:tabsManagerMoveMode = 0
        call s:TabsManagerMoveModeUnmapKeys()

    elseif a:action == "move"
        echom "================== move ".a:option." =================="
        if s:tabsManagerMoveMode == 0
            call s:TabsManagerMoveModeUnmapKeys()
            return
        endif

        " Move selection to next/previous line.
        if a:option == "up"
            let l:moveTab = -1
        elseif a:option == "down"
            let l:moveTab = 1
        else
            call s:Error("Tabs move ASSERT0 tab move option error ".a:option)
            return
        endif

        call s:TabsListMove(l:moveTab, l:tab)
        let s:tabsManagerMoveMode = l:moveTab

        "let l:doTabListRefresh = 1
        let l:doTabMenuRefresh = 1

    elseif a:action == "close"
        if s:tabsManagerMoveMode != 0
            call s:Warn("[MOVE MODE] Select new postion and press enter.")
            return
        endif

        " Close the selected tab
        call confirm("Confirm to close tab ".l:tabSelPos.l:tabname."?")
        silent exec("tabclose ".l:tabSelPos)

        redraw
        echo "[".s:plugin_name."] Tab ".l:tabSelPos.l:tabname." closed."

        let l:doTabListRefresh = 1
        let l:doTabMenuRefresh = 1

    else
        call s:Error( "Unknown option: ".l:action)
    endif

    " Refresh tab line.
    if l:doTabListRefresh == 1
        cal s:TabsBarUpdate()
    endif

    " Restore tab and line
    if l:doTabMenuRefresh == 1
        call tabs#WindowManager("refresh", l:line)
    endif
endfunction


" On tab manager move mode. Move tabs manager list up/down when moving the cursor.
" Arg1: direction, up or down.
function! tabs#TabsManagerMoveMode(direction)
    if !exists("s:tabsManagerMoveMode") || s:tabsManagerMoveMode == 0
        call s:TabsManagerMoveModeUnmapKeys()
        return
    endif

    if !exists("s:TabsMoveModeNamesList") || len(s:TabsMoveModeNamesList) == 0
        call s:TabsManagerMoveModeUnmapKeys()
        return
    endif

    if a:direction == "up"
        let l:steps = 1
        let l:tab = line(".")
    else
        let l:steps = -1
        let l:tab = line(".") - 2
    endif

    call s:TabsListMove(l:steps, l:tab)
    call tabs#WindowManager("refresh", "")
endfunction


function! s:TabsManagerMoveModeMapKeys()
    "echom "s:TabsManagerMoveModeMapKeys()"
    silent! nmap k      :call tabs#WindowManagerAction("move", "up")<CR>
    silent! nmap j      :call tabs#WindowManagerAction("move", "down")<CR>
    silent! nmap <UP>   :call tabs#WindowManagerAction("move", "up")<CR>
    silent! nmap <DOWN> :call tabs#WindowManagerAction("move", "down")<CR>
    "silent! nmap k      :call tabs#TabsManagerMoveMode("up")<CR>
    "silent! nmap j      :call tabs#TabsManagerMoveMode("down")<CR>
    "silent! nmap <UP>   :call tabs#TabsManagerMoveMode("up")<CR>
    "silent! nmap <DOWN> :call tabs#TabsManagerMoveMode("down")<CR>
endfunction


function! s:TabsManagerMoveModeUnmapKeys()
    "echom "s:TabsManagerMoveModeUnmapKeys()"
    silent! nunmap j
    silent! nunmap k
    silent! nunmap <UP>
    silent! nunmap <DOWN>
endfunction


function! s:TabsManagerMapKeys()
    "echom "s:TabsManagerMapKeys()"
    silent! nmap <ENTER> :call tabs#WindowManagerSelectTab()<CR>
    silent! nmap c       :call tabs#WindowManagerAction("close", "")<CR>
    silent! nmap q       :call tabs#UnmapKeysAndQuit()<CR>
    silent! nmap M       :call tabs#WindowManagerAction("move_init", "")<CR>
    silent! nmap r       :call tabs#WindowManagerAction("rename", "")<CR>
    silent! nmap t       :call tabs#WindowManagerSelectTabAndOpenTabManager()<CR>
    silent! nmap 1       :call tabs#WindowManagerSelectTabAndWindow(1)<CR>
    silent! nmap 2       :call tabs#WindowManagerSelectTabAndWindow(2)<CR>
    silent! nmap 3       :call tabs#WindowManagerSelectTabAndWindow(3)<CR>
    silent! nmap 4       :call tabs#WindowManagerSelectTabAndWindow(4)<CR>
    silent! nmap 5       :call tabs#WindowManagerSelectTabAndWindow(5)<CR>
    silent! nmap 6       :call tabs#WindowManagerSelectTabAndWindow(6)<CR>
    silent! nmap 7       :call tabs#WindowManagerSelectTabAndWindow(7)<CR>
    silent! nmap 8       :call tabs#WindowManagerSelectTabAndWindow(8)<CR>
    silent! nmap 9       :call tabs#WindowManagerSelectTabAndWindow(9)<CR>
    silent! nmap 0       :call tabs#WindowManagerSelectTabAndWindow(10)<CR>

    " Make t mapping go fastter by removing other mappings using t as first
    " letter.
    silent! nunmap tm
    silent! nunmap tr
    silent! nunmap ts

    if !exists("s:tabsManagerMoveMode") || s:tabsManagerMoveMode != 0
        call s:TabsManagerMoveModeMapKeys()
    endif
endfunction


function! s:TabsManagerUnmapKeys()
    "echom "s:TabsManagerUnmapKeys()"
    silent! nunmap <ENTER>
    silent! nunmap c
    silent! nunmap q
    silent! nunmap M
    silent! nunmap r
    silent! nunmap t
    silent! nunmap 1
    silent! nunmap 2
    silent! nunmap 3
    silent! nunmap 4
    silent! nunmap 5
    silent! nunmap 6
    silent! nunmap 7
    silent! nunmap 8
    silent! nunmap 9
    silent! nunmap 0

    silent! nmap tm   :Tabsm<CR>
    silent! nmap tr   :Tabsrn<CR>
    silent! nmap ts   :Tabss<CR>

    call s:TabsManagerMoveModeUnmapKeys()
endfunction


function! tabs#UnmapKeysAndQuit()
    "echom "tabs#UnmapKeysAndQuit()"
    if exists("s:TabsManagerMoveModeTabSwitch")
        "echom "skip tabs#UnmapKeysAndQuit() TabsManagerMoveModeTabSwitch==1"
        return
    endif
    if expand("%") == "_tabs_manager_"
        "echom "tabs#UnmapKeysAndQuit() quit"
        call s:TabsManagerUnmapKeys()
        let s:tabsManagerMoveMode = 0
        silent! quit!
    endif
    redraw
endfunction


" Open cmd menu to choose the tab we want to move into.
" Commands: Tabs, Ts
function! tabs#SwitchMenu()
    echo "[".s:plugin_name."] Tabs info:" 
    let tab = tabpagenr()
    let i = 1
    while i <= tabpagenr('$')
        echo " " 
        let l:tabInfo = (i == l:tab ? "> ".l:i.") " : '  '.l:i.") ")
        echon l:tabInfo 

        if exists("s:TabsNamesList")
            if len(s:TabsNamesList) >= l:i
                if s:TabsNamesList[l:i-1] != "" && s:TabsNamesList[l:i-1] != "."
                    if g:Tabs_switch_SelectedTabColor != ""
                        silent exec("echohl ".g:Tabs_switch_SelectedTabColor)
                    endif
                    if g:Tabs_manager_TabNamePadding != ""
                        echon printf("%-".g:Tabs_manager_TabNamePadding."s", s:TabsNamesList[l:i-1])
                    else
                        echon s:TabsNamesList[l:i-1]
                    endif
                    echohl None 
                    echon " " 
                endif
            endif
        endif

        let l:buffInfo = ""
        let l:n = 1
        for l:bufnr in tabpagebuflist(i)
            let l:buffname = bufname(l:bufnr)
            if l:buffname != ""
                if l:n != 1
                    let l:buffInfo .= ", " 
                endif
                let l:buffInfo .= l:n.":".fnamemodify(l:buffname, ":t")
            endif
            let l:n += 1
        endfor

        if l:buffInfo != ""
            echon "[".l:buffInfo."]" 
        else
            echon "[empty]" 
        endif

        "echo l:tabInfo
        let i += 1
    endwhile

    let l:tabn = input("Go to tab number: ") 
    if l:tabn != "" 
        let l:tabn = str2nr(l:tabn) 
        if l:tabn > 0 && l:tabn < l:i 
            silent! exec("normal ".l:tabn."gt")
        endif 
    endif 
endfunction


" Ensure tabs match tabs names list.
function! s:TabsListUpdate()
    if !exists('s:TabsNamesList')
        let s:TabsNamesList = ['.']
    endif

    if len(s:TabsNamesList) >= tabpagenr('$')
        return
    endif

    " Insert empty name for each missing tab on list
    let i = len(s:TabsNamesList)
    while i <= tabpagenr('$')-1
        "echom "TabsListUpdate add: ".l:i
        let s:TabsNamesList += ['.']
        let i = i + 1
    endwhile
    "echom "TabsListUpdate final list: "s:TabsNamesList
endfunction


function! s:TabsListMove(steps, pos)
    echom "TabsListMove steps:".a:steps." pos:".a:pos

    if a:pos <= 0 || a:pos > len(s:TabsNamesList)
        call s:Error("TabsListMove ASSERT Wrong tab pos: ".a:pos)
        return
    endif

    call s:TabsListUpdate()
    "echom "TabsListMove init list: "s:TabsNamesList

    let l:tabname = s:TabsNamesList[a:pos-1]
    let l:newpos = a:pos + a:steps

    if l:newpos <= 0 || l:newpos > len(s:TabsNamesList)
        call s:Error("TabsListMove ASSERT Wrong tab new pos: ".l:newpos." (".a:steps.")")
        return
    endif
    "echom "TabsListMove steps:".a:steps." pos:".a:pos." newpos:".l:newpos." name:".l:tabname

    call remove(s:TabsNamesList, a:pos-1)
    call extend(s:TabsNamesList, [l:tabname], l:newpos-1)

    let g:Tabs_names = join(s:TabsNamesList)
    "echom "TabsListMove final list: "s:TabsNamesList
endfunction


function! tabs#NewTab()
    call s:TabsListUpdate()
    call extend(s:TabsNamesList, ['.'], tabpagenr()-1)
    call s:TabsBarUpdate()
    let g:Tabs_names = join(s:TabsNamesList)
endfunction


function! tabs#CloseTab()
    call s:TabsListUpdate()
    if tabpagenr() == tabpagenr('$')
        call remove(s:TabsNamesList, tabpagenr())
    else
        call remove(s:TabsNamesList, tabpagenr()-1)
    endif
    call s:TabsBarUpdate()
    let g:Tabs_names = join(s:TabsNamesList)
endfunction


function! tabs#Rename(tabNum, tabName)
    let l:newTabName = a:tabName
    let l:tabName = ""

    if a:tabNum <= 0 || a:tabNum == ""
        let t = tabpagenr()
    else
        let t = a:tabNum
    endif

    " Get the tab name
    if exists('s:TabsNamesList') && len(s:TabsNamesList) >= l:t
        if s:TabsNamesList[l:t-1] != "."
            let l:tabName = s:TabsNamesList[l:t-1]
        endif
    endif

    if l:newTabName == "" 
        if l:tabName != "" 
            let l:newTabName = input("Rename tab '".l:tabName."' with: ")
        else
            let l:newTabName = input("Enter tab name: ")
        endif
    endif

    if l:newTabName == "" 
        if l:tabName != ""
            call confirm("[".s:plugin_name."] Remove tab name '".l:tabName."'?")
        else
            return
        endif
    endif 

    call s:TabsListUpdate()

    let s:TabsNamesList[l:t-1] = l:newTabName
    "let n = l:t-1
    "echom "Set tab ".l:n." as ".l:newTabName
    cal s:TabsBarUpdate()
    let g:Tabs_names = join(s:TabsNamesList)
endfunction


function! s:MoveTab(direction)
    call s:TabsListUpdate()

    let t = tabpagenr()

    if a:direction == "left"
        if l:t <= 1
            return
        endif

        let l:tmp = s:TabsNamesList[l:t-2]
        let s:TabsNamesList[l:t-2] = s:TabsNamesList[l:t-1]
        let s:TabsNamesList[l:t-1] = l:tmp
        silent tabmove -1
    else
        if l:t >= tabpagenr('$')
            return
        endif

        let l:tmp = s:TabsNamesList[l:t-1]
        let s:TabsNamesList[l:t-1] = s:TabsNamesList[l:t]
        let s:TabsNamesList[l:t] = l:tmp
        silent tabmove +1
    endif

    call s:TabsBarUpdate()
    let g:Tabs_names = join(s:TabsNamesList)
endfunction


" Get tab name if set, otherwhise use current buffer as tab name.
" Limit the tab name lenght as specified on variable: g:Tabs_trimTabNameLen.
" Arg1: tab number.
function! s:GetTabName(tabn)
    let l:name = ''

    if exists("s:TabsNamesList") && len(s:TabsNamesList) >= a:tabn
        if s:TabsNamesList[a:tabn-1] != "."
            let l:name = s:TabsNamesList[a:tabn-1]
        endif
    endif
    "echom "tabn: ".a:tabn." name: ".l:name 

    if l:name == ''
        let buflist = tabpagebuflist(a:tabn)
        let winnr = tabpagewinnr(a:tabn)
        let l:name = bufname(buflist[winnr - 1])
        let l:name = fnamemodify(l:name, ':p:t')

        "Set the maximum tab label lentgh
        if exists("g:Tabs_trimTabNameLen")
            if g:Tabs_trimTabNameLen != ""
                if g:Tabs_trimTabNameLen > 0
                    let l:name = l:name[0:g:Tabs_trimTabNameLen]
                endif
                if g:Tabs_trimTabNameLen < 0
                    let l:name = l:name[g:Tabs_trimTabNameLen:100]
                endif
            endif
        endif
    endif

    if l:name == ''
        let l:name = '[No Name]'
    endif
    "echom "s:GetTabName() ".a:tabn." name :".l:name
    return l:name
endfunction


" Set the tabline content.
" :help tabline
" The 'tabline' option specifies what the line with tab pages labels looks like.
" It is only used when there is no GUI tab line.
function! tabs#TabLine()
    let s = ''
    let t = tabpagenr()
    let i = 1
    while i <= tabpagenr('$')
        let s .= '%' . i . 'T'
        let s .= (i == t ? '%1*' : '%2*')
        let s .= ' '
        let s .= i . ':'
        let s .= '%*'
        let s .= (i == t ? '%#TabLineSel#' : '%#TabLine#')
        let s .= s:GetTabName(l:i)
        let i = i + 1
    endwhile

    let s .= '%T%#TabLineFill#%='
    let s .= (tabpagenr('$') > 1 ? '%999XX' : 'X')
    "echom ""
    "echom "tabs#TabLine() tabline: ".l:s 
    return s
endfunction


" :help guitablabel
" When the GUI tab pages line is displayed, 'guitablabel' can be used to
" specify the label to display for each tab page.  Unlike 'tabline', which
" specifies the whole tab pages line at once, 'guitablabel' is used for each
" label separately.
function! tabs#GuiTabLabel()
    return
    let label = ''
    let bufnrlist = tabpagebuflist(v:lnum)

    " Add '+' if one of the buffers in the tab page is modified
    for bufnr in bufnrlist
        if getbufvar(bufnr, "&modified")
            let label = '+'
            break
        endif
    endfor

    " Append the number of windows in the tab page if more than one
    let wincount = tabpagewinnr(v:lnum, '$')
    if wincount > 1
        let label .= wincount
    endif
    if label != ''
        let label .= ' '
    endif

    " Append the buffer name
    "return label . bufname(bufnrlist[tabpagewinnr(v:lnum) - 1])
    return label . s:GetTabName(tabpagenr())
endfunction


" Return: " [tab_name]", or "" if there's no name assigned.
function! s:TabMoveGetTabName()
    " Get tab name
    let l:tabstr = ""
    let t = tabpagenr()

    if exists('s:TabsNamesList') && len(s:TabsNamesList) >= l:t
        if s:TabsNamesList[l:t-1] != "."

            if g:Tabs_move_number_of_tabs > 0
                let l:i = l:t - g:Tabs_move_number_of_tabs
                while l:i < l:t-1
                    if l:t-l:i >= 0
                        if s:TabsNamesList[l:t-l:i] != "."
                            let l:tabstr .= s:TabsNamesList[l:t-l:i]."|"
                        else
                            let l:tabstr .= "|"
                        endif
                    endif
                    let l:i += 1
                endwhile
            endif

            let l:tabname = s:TabsNamesList[l:t-1]
            if l:tabname != ""
                let l:tabstr .= "[".l:tabname."]"
            endif

            if g:Tabs_move_number_of_tabs > 0
                let l:i = l:t
                while l:i < l:t + g:Tabs_move_number_of_tabs
                    if l:t+l:i < len(s:TabsNamesList)
                        if s:TabsNamesList[l:t+l:i] != "."
                            let l:tabstr .= "|".s:TabsNamesList[l:t+l:i]
                        else
                            let l:tabstr .= "|"
                        endif
                    endif
                    let l:i += 1
                endwhile
            endif
            "if len(s:TabsNamesList) > l:t
                "if s:TabsNamesList[l:t] != "."
                    "let l:tabstr .= ":".s:TabsNamesList[l:t]
                "endif
            "endif
        endif
    endif

    if l:tabstr != ""
        let l:tabstr = " ".l:tabstr
    endif

    return l:tabstr
endfunction


" Move to next/prev tab or move tab to the left/right. 
" Commands: Tabsn, Tabsp, Tabsr, Tabsl, Tab
function! tabs#Move(action)
    " Get tab name
    let l:tabname = ""

    if tabpagenr('$') == 1
        if a:action == ""
            let l:tabname = s:TabMoveGetTabName()
            echo "Tab ".tabpagenr()."/".tabpagenr('$')." ".l:tabname
        endif
        return
    endif

    if tabpagenr() == 1 && (a:action =~ "prev" || a:action =~ "left")
        let l:type = "last-tab"
    elseif tabpagenr() == tabpagenr('$')-1 && (a:action =~ "next" || a:action =~ "right")
        let l:type = "last-tab"
    elseif tabpagenr() == 2 && (a:action =~ "prev" || a:action =~ "left")
        let l:type = "first-tab"
    elseif tabpagenr() == tabpagenr('$') && (a:action =~ "next" || a:action =~ "right")
        let l:type = "first-tab"
    else
        let l:type = "other-tab"
    endif

    if a:action =~ "next"
        silent tabnext
    elseif a:action =~ "prev"
        silent tabprev
    elseif a:action =~ "left"
        call s:MoveTab("left")
    elseif a:action =~ "right"
        call s:MoveTab("right")
    endif

    if a:action =~ "left" || a:action =~ "right"
        call s:TabsBarUpdate()
    endif

    if exists('g:Tabs_message_active') && g:Tabs_message_active == 1
        let l:tabname = s:TabMoveGetTabName()

        if l:type == "first-tab"
            if exists('g:Tabs_message_firstTabColor') && g:Tabs_message_firstTabColor != ""
                silent exec("echohl ".g:Tabs_message_firstTabColor)
            endif
        elseif l:type == "last-tab"
            if exists('g:Tabs_message_lastTabColor') && g:Tabs_message_lastTabColor != ""
                silent exec("echohl ".g:Tabs_message_lastTabColor)
            endif
        else
            if exists('g:Tabs_message_tabColor') && g:Tabs_message_tabColor != ""
                silent exec("echohl ".g:Tabs_message_tabColor)
            endif
        endif

        echo "Tabs ".tabpagenr()."/".tabpagenr('$')." ".l:tabname
        echohl None
    endif

    let g:Tabs_names = join(s:TabsNamesList)
endfunction


" Show pluging commands help.
" Commands: Tabsh
function! tabs#Help()
    let l:text =  "[".s:plugin_name."] help (v".g:tabs_version."):\n"
    let l:text .= "\n"
    let l:text .= "Abridged command help:\n"
    let l:text .= "\n"
    let l:text .= "Tabs manager:\n"
    let l:text .= "   Tabsm       : open tabs manager window.\n"
    let l:text .= "\n"
    let l:text .= "Tabs switch menu:\n"
    let l:text .= "   Tabss       : open tabs switch menu.\n"
    let l:text .= "\n"
    let l:text .= "Tabs rename:\n"
    let l:text .= "   Tabsr [NAME] : change tab name. Leafe empty to remove tab name.\n"
    let l:text .= "\n"
    let l:text .= "Tabs move:\n"
    let l:text .= "   Tabs        : show tab name and number.\n"
    let l:text .= "   Tabsn       : switch to next tab.\n"
    let l:text .= "   Tabsp       : switch to previous tab.\n"
    let l:text .= "   Tabsr       : move tab right.\n"
    let l:text .= "   Tabsl       : move tab left.\n"
    let l:text .= "\n"
    let l:text .= "TabsR          : refresh tabs line.\n"
    let l:text .= "\n"
    let l:text .= "Tabsh          : show this help.\n"
    let l:text .= "\n"

    call s:WindowSplitMenu(4)
    call s:WindowSplit()
    call s:WindowSplitEnd()
    setl nowrap
    set buflisted
    set bufhidden=delete
    set buftype=nofile
    setl noswapfile
    silent put = l:text
    silent! exec '0file | file tabs_plugin_help'
    normal ggdd
endfunction





"- GUI menu  ------------------------------------------------------------

" Create menu items for the specified modes.
function! tabs#CreateMenus(modes, submenu, target, desc, cmd)
    " Build up a map command like
    let plug = a:target
    let plug_start = 'noremap <silent> ' . ' :call Tabs("'
    let plug_end = '", "' . a:target . '")<cr>'

    " Build up a menu command like
    let menuRoot = get(['', 'Tabs', '&Tabs', "&Plugin.&Tabs".a:submenu], 3, '')
    let menu_command = 'menu ' . l:menuRoot . '.' . escape(a:desc, ' ')

    if strlen(a:cmd)
        let menu_command .= '<Tab>' . a:cmd
    endif

    let menu_command .= ' ' . (strlen(a:cmd) ? plug : a:target)

    "call tabs#tools#LogLevel(1, expand('<sfile>'), l:menu_command)

    " Execute the commands built above for each requested mode.
    for mode in (a:modes == '') ? [''] : split(a:modes, '\zs')
        if strlen(a:cmd)
            execute mode . plug_start . mode . plug_end
            "call tabs#tools#LogLevel(1, expand('<sfile>'), "execute ". mode . plug_start . mode . plug_end)
        endif
        " Check if the user wants the menu to be displayed.
        if g:tabs_mode != 0
            "call tabs#tools#LogLevel(1, expand('<sfile>'), "execute " . mode . menu_command)
            execute mode . menu_command
        endif
    endfor
endfunction


"- Release tools ------------------------------------------------------------
"

" Create a vimball release with the plugin files.
" Commands: Tabsvba
function! tabs#NewVimballRelease()
    let text  = ""
    let l:text .= "plugin/tabs.vim\n"
    let l:text .= "autoload/tabs.vim\n"

    silent tabedit
    silent put = l:text
    silent! exec '0file | file vimball_files'
    silent normal ggdd

    let l:plugin_name = substitute(s:plugin_name, ".vim", "", "g")
    let l:releaseName = l:plugin_name."_".g:tabs_version.".vmb"

    let l:workingDir = getcwd()
    silent cd ~/.vim
    silent exec "1,$MkVimball! ".l:releaseName." ./"
    silent exec "vertical new ".l:releaseName
    silent exec "cd ".l:workingDir
    call s:WindowSplitEnd()
endfunction


"- initializations ------------------------------------------------------------
"
let  s:plugin = expand('<sfile>')
let  s:plugin_path = expand('<sfile>:p:h')
let  s:plugin_name = expand('<sfile>:t')

call s:Initialize()

