TODO
====

- Mark expanded areas, with a name (maybe uuid)

- collapse a running request, may mean kill the underlying process.

- Introduce a new keyboard shortcut family `alt-x`:

  - `alt-x,s` send expanded area containing the cursor to hosting path.  Same
    like gooing up to hosting path and hitting `ctrl-shift-enter`

  - `alt-x,c` collapse expanded area contain the cursor and put cursor on
    hosting path.  Same like going up to hosting path and hitting `ctrl-enter`

  - `alt-x,a` take current path, internally append a '*' for *all* aka *attribute*
    context and commit (`ctrl-enter`)

  - `alt-x,h`, `alt-x,?` take current path, internally appenda  '?' for *help*
    context and commit (`ctrl-enter`)

  - `alt-x,x` xikij mode, here shall work great other shortcuts, hit `esc` to
    escape xikij mode

  - `alt-x,j` jump to next button or next path (after expanded area)

  - `alt-x,k` jump to previous button or previous path (after expanded area)

- Completion

- Fix issue with svn commit (the dots are printed in a strange way)
