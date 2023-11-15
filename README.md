# tabs.vim
Tabs manager, handy when you open 10+ tabs.

## Description

Just a tool to help you manage a heavy amount of tabs on your vim editor.

Use command :Tabsm or map tm to display the tab manager window.

Use command :Tabsh to show the abridged command help.

## Default mappings:
- Esc+1 to Esc+0 (Win+1, Win+0): move to window number 1 to 10.
- Esc+l and Esc+h (Win+l, Win+h): move to next or previous tab.
- Esc+, and Esc+. (Win+l, Win+h): move tab a spot right or left.

## Configuration:
- Deactivate default mappings (tm, ts, tr)
```vimscript
let g:Tabs_useDefaultMappings=0
```

- Deactivate default tab movement mappings:
```vimscript
let g:Tabs_useDefaultMoveMappings=0
```

- Deactivate default move to tab number mappings:
```vimscript
let g:g:Tabs_useDefaultGotoMappings=0
```
 
## Install details
Minimum version: Vim 7.0+

Recomended version: Vim 8.0+
