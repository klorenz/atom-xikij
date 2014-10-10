# xikij package

Xikij is a xiki clone for atom under very development.


## working features

- file browsing with absolute paths.  E.g. hit `ctrl-enter` on following line:
  ```
  /home
  ```

  Open a file inline by pressing ctrl-enter.  Save expanded file by going to
  filename and press `ctrl-shift-enter`.

  If you have installed package [open-plus](https://github.com/klorenz/open-plus),
  you can open a file or directory by pressing `ctrl-o`.

- program execution works.  E.g. hit `ctrl-enter` on following line:
  ```
  $ ps -ef
  ```

- nested contexts work.  Hit `ctrl-enter` on `$ ls` line:
  ```
  /home
    $ ls
  ```

- menus work, there are some now:
  + `hostname` -- print host's name
  + `ip` -- print host's ip to internet
  + `pwd` -- print current working directory


- syntax highlighting of inline opened files


## Changelog

... many more changes not yet listed here

0.4.0
  - fix collapsing, keep last empty line
  - xikij enabled per default

0.3.0
  - directory browsing

0.2.0
  - add program execution
  - indentation fixed

0.1.0
  - this is an "internal" release, not ready for use, only for experimenting
