# xikij package

Xikij is a xiki clone for atom under very development.


## working features

- file browsing with absolute paths.  E.g. hit `ctrl-enter` on following line:
  ```
  /home
  ```

- program execution works.  E.g. hit `ctrl-enter` on following line:
  ```
  $ ps -ef
  ```

- nested contexts work.  Hit `ctrl-enter` on `$ ls` line:
  ```
  /home
    $ ls
  ```

- menus work, for now only this implemented completly:
  ```
  hostname
  ```

## Changelog

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


A short description of your package.

![A screenshot of your spankin' package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)


## Use Cases

### Changelog

1. open CHANGELOG.md
2. type your project folder
3. go one line below and indented you type `$ git log --oneline` hit `ctrl-enter`


TODO

- if changed indentation of marked block of running command, future indentation
  of command must be correct.
