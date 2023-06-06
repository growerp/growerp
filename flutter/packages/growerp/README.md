
GrowERP utilities

A command line utility to easy install and maintain the system

commands available:

- growerp install [full | backend | frontend] 

    full: flutter frontend and Moqui Backend
    frontend: Just flutter frontend using our test backend
    backend: Just the Moqui and chat backend.

    flags: (default: both environments)
        -rel    : only the release environment
        -dev    : only the development environment
        -start  : start the process in a separate window (only development)

    growerp install 
        -start start in separate window
        -noBuild: do not compile and not db initial load

    default: just flutter frontend rel+dev using our test backend

- growerp switchPackage
    dependent on the 'admin' package growerp_core dependency status
    will switch using packages locally or from pub.dev


