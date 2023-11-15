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
"   Add "set viminfo+=!" on your .vimrc to preserve tabs names across sessions.
"
" Version:      0.0.1
" Changes:
" 0.0.1 	Fri, 08 Jul 22.     JPuigdevall
"   - Initial realease.

if exists('g:loaded_tabs')
    finish
endif

let g:loaded_tabs = 1
let s:save_cpo = &cpo
set cpo&vim

let g:tabs_version = "0.0.1"


"- configuration --------------------------------------------------------------

let g:tabs_mode =  get(g:, 'tabs_mode', 3) " Display menu on gvim

let g:Tabs_switch_SelectedTabColor  = get(g:, 'Tabs_switch_SelectedTabColor', "PmenuSel")
"let g:Tabs_switch_SelectedTabColor = get(g:, 'Tabs_switch_SelectedTabColor', "DiffAdd")

let g:Tabs_manager_TabNamePadding    = get(g:, 'Tabs_manager_TabNamePadding', 15)
let g:Tabs_manager_MaxLines          = get(g:, 'Tabs_manager_MaxLines',       21)

" Use hi.vim plugin if available to colorize the menus:
" Config 1:
"let g:Tabs_manager_infoHighlightColor             = get(g:, 'Tabs_manager_infoHighlightColor',         "w8")
"let g:Tabs_manager_tabNameHighlightColor         = get(g:, 'Tabs_manager_tabNameHighlightColor',         "w")
"let g:Tabs_manager_selectedTabLineHighlightColor = get(g:, 'Tabs_manager_selectedTabLineHighlightColor', "y_*")
"let g:Tabs_manager_buffersOnTabHighlightColor    = get(g:, 'Tabs_manager_buffersOnTabHighlightColor',    "")
" Config 2:
"let g:Tabs_manager_infoHighlightColor             = get(g:, 'Tabs_manager_infoHighlightColor',         "w8")
"let g:Tabs_manager_tabNameHighlightColor         = get(g:, 'Tabs_manager_tabNameHighlightColor',         "w@")
"let g:Tabs_manager_selectedTabLineHighlightColor = get(g:, 'Tabs_manager_selectedTabLineHighlightColor', "y@*")
"let g:Tabs_manager_buffersOnTabHighlightColor    = get(g:, 'Tabs_manager_buffersOnTabHighlightColor',    "")
" Config 3:
"let g:Tabs_manager_infoHighlightColor             = get(g:, 'Tabs_manager_infoHighlightColor',         "w8")
"let g:Tabs_manager_tabNameHighlightColor         = get(g:, 'Tabs_manager_tabNameHighlightColor',         "w!")
"let g:Tabs_manager_selectedTabLineHighlightColor = get(g:, 'Tabs_manager_selectedTabLineHighlightColor', "y8!*")
"let g:Tabs_manager_buffersOnTabHighlightColor    = get(g:, 'Tabs_manager_buffersOnTabHighlightColor',    "w7")
" Config 4:
let g:Tabs_manager_infoHighlightColor             = get(g:, 'Tabs_manager_infoHighlightColor',         "w8*")
let g:Tabs_manager_tabNameHighlightColor          = get(g:, 'Tabs_manager_tabNameHighlightColor',         "o")
let g:Tabs_manager_selectedTabLineHighlightColor  = get(g:, 'Tabs_manager_selectedTabLineHighlightColor', "y8*")
let g:Tabs_manager_buffersOnTabHighlightColor     = get(g:, 'Tabs_manager_buffersOnTabHighlightColor',    "")

let g:Tabs_trimTabNameLen = get(g:, 'Tabs_trimTabNameLen', 25)

let g:Tabs_useDefaultMappings     = get(g:, 'Tabs_useDefaultMappings', 1)
let g:Tabs_useDefaultMoveMappings = get(g:, 'Tabs_useDefaultMoveMappings', 1)
let g:Tabs_useDefaultGotoMappings = get(g:, 'Tabs_useDefaultGotoMappings', 1)

let g:Tabs_message_active        = get(g:, 'Tabs_message_active', 1)
let g:Tabs_message_firstTabColor = get(g:, 'Tabs_message_firstTabColor', "DiffAdd")
let g:Tabs_message_lastTabColor  = get(g:, 'Tabs_message_lastTabColor',  "WarningMsg")
let g:Tabs_message_tabColor      = get(g:, 'Tabs_message_tabColor',      "")

let g:Tabs_move_number_of_tabs   = get(g:, 'Tabs_move_number_of_tabs',   0)

"let g:TabsNamesList            = get(g:, 'TabsNamesList',      [])
let g:Tabs_names                = get(g:, 'Tabs_names', "")



"- commands -------------------------------------------------------------------

command! -nargs=0  Tabss                               call tabs#SwitchMenu()

let s:TabsNamesList = []
command! -nargs=0  Tabsm                               call tabs#WindowManager("", "")

command! -nargs=?  Tabsrn                              call tabs#Rename(0, <q-args>)

" Show current tab number and name.
command! -nargs=0 Tabs                                  call tabs#Move("")

" Switch to the next/previous tab
command! -nargs=0 Tabsn                                 call tabs#Move("switch-next")
command! -nargs=0 Tabsp                                 call tabs#Move("switch-prev")

" Move current tab to left/right.
command! -nargs=0 Tabsl                                 call tabs#Move("move-left")
command! -nargs=0 Tabsr                                 call tabs#Move("move-right")

" Plugin help window.
command! -nargs=0  Tabsh                               call tabs#Help()

" Release functions:
command! -nargs=0  Tabsvba                              call tabs#NewVimballRelease()

" Edit plugin files:
command! -nargs=0  Tabsedit                             call tabs#Edit()

command! -nargs=0  TabsR                                call tabs#TablineRefresh()



"- mappings -------------------------------------------------------------------

if exists("g:Tabs_useDefaultMappings")
    if g:Tabs_useDefaultMappings == 1
        if !hasmapto('Tabsm', 'n')
            nnoremap tm           :Tabsm<CR>
        endif

        if !hasmapto('Tabsrn', 'n')
            nnoremap tr           :Tabsrn<CR>
        endif

        if !hasmapto('Tabss', 'n')
            nnoremap ts           :Tabss<CR>
        endif
    endif
endif

if exists("g:Tabs_useDefaultMoveMappings")
    if g:Tabs_useDefaultMoveMappings == 1
        if !hasmapto('Tabsn', 'n')
            nnoremap <Esc>l :Tabsn<CR>
            nnoremap <M-l>  :Tabsn<CR>
            "nnoremap <Esc>f :Tabsn<CR>
            "nnoremap <M-f>  :Tabsn<CR>
        endif

        if !hasmapto('Tabsp', 'n')
            nnoremap <Esc>h :Tabsp<CR> 
            nnoremap <M-h>  :Tabsp<CR> 
            "nnoremap <Esc>a :Tabsp<CR> 
            "nnoremap <M-a>  :Tabsp<CR> 
        endif

        if !hasmapto('Tabsr', 'n')
            nnoremap <Esc>. :Tabsr<CR>
            nnoremap <Esc>/ :Tabsr<CR>
            nnoremap <M-.>  :Tabsr<CR>
            nnoremap <M-/>  :Tabsr<CR>
        endif

        if !hasmapto('Tabsl', 'n')
            nnoremap <Esc>, :Tabsl<CR>
            nnoremap <M-,>  :Tabsl<CR>
        endif
    endif
endif

if exists("g:Tabs_useDefaultGotoMappings")
    nnoremap <Esc>1 :normal 1gt<CR>
    nnoremap <M-1>  :normal 1gt<CR>
    nnoremap <Esc>2 :normal 2gt<CR>
    nnoremap <M-2>  :normal 2gt<CR>
    nnoremap <Esc>3 :normal 3gt<CR>
    nnoremap <M-3>  :normal 3gt<CR>
    nnoremap <Esc>4 :normal 4gt<CR>
    nnoremap <M-4>  :normal 4gt<CR>
    nnoremap <Esc>5 :normal 5gt<CR>
    nnoremap <M-5>  :normal 5gt<CR>
    nnoremap <Esc>6 :normal 6gt<CR>
    nnoremap <M-6>  :normal 6gt<CR>
    nnoremap <Esc>7 :normal 7gt<CR>
    nnoremap <M-7>  :normal 7gt<CR>
    nnoremap <Esc>8 :normal 8gt<CR>
    nnoremap <M-8>  :normal 8gt<CR>
    nnoremap <Esc>9 :normal 9gt<CR>
    nnoremap <M-9>  :normal 9gt<CR>
    nnoremap <Esc>0 :normal 10gt<CR>
    nnoremap <M-0>  :normal 10gt<CR>

    nnoremap <Leader>t1  :normal 1gt<CR>
    nnoremap <Leader>t2  :normal 2gt<CR>
    nnoremap <Leader>t3  :normal 3gt<CR>
    nnoremap <Leader>t4  :normal 4gt<CR>
    nnoremap <Leader>t5  :normal 5gt<CR>
    nnoremap <Leader>t6  :normal 6gt<CR>
    nnoremap <Leader>t7  :normal 7gt<CR>
    nnoremap <Leader>t8  :normal 8gt<CR>
    nnoremap <Leader>t9  :normal 9gt<CR>
    nnoremap <Leader>t10 :normal 10gt<CR>
    nnoremap <Leader>t11 :normal 11gt<CR>
    nnoremap <Leader>t12 :normal 12gt<CR>
    nnoremap <Leader>t13 :normal 13gt<CR>
    nnoremap <Leader>t14 :normal 14gt<CR>
    nnoremap <Leader>t15 :normal 15gt<CR>
    nnoremap <Leader>t16 :normal 16gt<CR>
    nnoremap <Leader>t17 :normal 17gt<CR>
    nnoremap <Leader>t18 :normal 18gt<CR>
    nnoremap <Leader>t19 :normal 19gt<CR>
    nnoremap <Leader>t20 :normal 20gt<CR>
    nnoremap <Leader>t21 :normal 21gt<CR>
    nnoremap <Leader>t22 :normal 22gt<CR>
    nnoremap <Leader>t23 :normal 23gt<CR>
    nnoremap <Leader>t24 :normal 24gt<CR>
    nnoremap <Leader>t25 :normal 25gt<CR>
    nnoremap <Leader>t26 :normal 26gt<CR>
    nnoremap <Leader>t27 :normal 27gt<CR>
    nnoremap <Leader>t28 :normal 28gt<CR>
    nnoremap <Leader>t29 :normal 29gt<CR>
    nnoremap <Leader>t30 :normal 30gt<CR>
endif


"- abbreviations -------------------------------------------------------------------


" DEBUG functions: reload plugin
cnoreabbrev _tabsrl    <C-R>=tabs#Reload()<CR>


"- menus -------------------------------------------------------------------

if has("gui_running")
    call tabs#CreateMenus('cn' , '', ':Tabsm'         , 'Open tabs manager'         , ':Tabsm')
    call tabs#CreateMenus('cn' , '', ':Tabss'         , 'Open tabs switch menu'     , ':Tabss')
    call tabs#CreateMenus('cn' , '', ':Tabsrn [NAME]' , 'Change current tab name'   , ':Tabsrn')
    call tabs#CreateMenus('cn' , '', ':'              , '-Sep-'                     , '')
    call tabs#CreateMenus('cn' , '', ':Tabs'          , 'Show current tab number and name' , ':Tabs')
    call tabs#CreateMenus('cn' , '', ':Tabsn'         , 'Switch to next tab'        , ':Tabsn')
    call tabs#CreateMenus('cn' , '', ':Tabsp'         , 'Switch to previous tab'    , ':Tabsp')
    call tabs#CreateMenus('cn' , '', ':'              , '-Sep2-'                    , '')
    call tabs#CreateMenus('cn' , '', ':Tabsr'         , 'Move tab right'            , ':Tabsr')
    call tabs#CreateMenus('cn' , '', ':Tabsl'         , 'Move tab left'             , ':Tabsp')
    call tabs#CreateMenus('cn' , '', ':'              , '-Sep3-'                    , '')
    call tabs#CreateMenus('cn' , '', ':TabsR'         , 'Refresh tabs'              , ':TabsR')
    call tabs#CreateMenus('cn' , '', ':Tabh'          , 'Show plugin help'          , ':Tabsh')

    if exists("g:Tabs_useDefaultMappings")
        if g:Tabs_useDefaultMappings == 1
            call tabs#CreateMenus('n'  , '.&mappings', 'tm', 'Open tabs manager'        , 'tm')
            call tabs#CreateMenus('n'  , '.&mappings', 'ts', 'Open tabs switch menu'    , 'ts')
            call tabs#CreateMenus('n'  , '.&mappings', 'tr', 'Change current tab name'  , 'tr')
        endif
    endif

    call tabs#CreateMenus('cn' , 'mappings', ':'       , '-Sep4-'                    , '')

    if exists("g:Tabs_useDefaultMoveMappings")
        if g:Tabs_useDefaultMoveMappings == 1
            call tabs#CreateMenus('n'  , '.&mappings', 'tm', 'Open tabs manager'        , 'tm')
            call tabs#CreateMenus('n'  , '.&mappings', 'ts', 'Open tabs switch menu'    , 'ts')
            call tabs#CreateMenus('n'  , '.&mappings', 'tr', 'Change current tab name'  , 'tr')
        endif
    endif
endif


autocmd SessionLoadPost * call tabs#LoadSavedTabNames()



let &cpo = s:save_cpo
unlet s:save_cpo


