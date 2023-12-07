
GrowERP utilities

A command line utility to easy install and maintain the system

commands available:

The Basic global dart GrowERP command.
Activate local version:
  dart pub global activate --source path ~/growerp/flutter/packages/growerp
Activate public version:
  dart pub global activate growerp.

Sub commands:
install:
  1. clone the repository from github into the local ~/growerp directory
  2. start the backend and chat server
  3. activate the dart melos global command.
  4. build the flutter system
  5. package 'admin' can now be started with flutter run.
  use the -dev switch to use the Github development branch
Import:
  will upload data like ledger, customers products etc from the terminal
  Also has a helper program csvToCsv to convert your csv files to the
    GrowERP format.
  Parameters:
    -i input file or directory
    -u -p user/password optional, will remember from last time
    -url the base url of the backend, local host is default
Export:
  will create CSV files for growerp entities in the current 'growerp'
  directory, if not exist will create it.
  Parameters:
    1. optional file type

flags:
  -dev if present uses development branch by installation
  -i filename : input file
  -u user : email address, with password create new company otherwise use last one
  -p password : required for new company
  -o outputDirectory : directory used for exported csv output files,default: growerp
  -url for import/export backend url
  -t receive timeout: default 60 seconds


