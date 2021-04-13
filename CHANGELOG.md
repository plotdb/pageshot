# Change Logs

## v1.0.0

 - upgrade modules to resolve vulnerabilities
 - use `lderror` instead of `ldError`


## v0.1.1

 - make bin file executable.
 - require pageshot module correctly by calculating correct path to it.
 - generate dist files without livescript header.


## v0.1.0

 - kill browser process on exit with node-cleanup.
 - add print and merge functionality
 - add dev server for building `web` src yet still accept api request to screenshot and print.
 - upgrade modules
 - rename package.
 - add dockerfile for running server in container.
 - add security note about potential SSRF exploit.
 - add information about PDF merge feature
 - show error message when api requests fail.
