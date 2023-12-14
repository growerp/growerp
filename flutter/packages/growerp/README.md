
# GrowERP utilities

A command line utility to easy install and maintain the system

Activate local version:
  dart pub global activate --source path ~/growerp/flutter/packages/growerp
Activate public version:
  dart pub global activate growerp.

## The Basic global dart GrowERP command.
Sub commands:
install:
  1. clone the repository from github into the local ~/growerp directory
  2. start the backend and chat server
  3. activate the dart melos global command.
  4. build the flutter system
  5. package 'admin' can now be started with flutter run.
  use the -dev switch to use the Github development branch
Import:
  will upload data like ledger(glaccount), customers products etc from the terminal
  Also has a helper program csvToCsv to convert your csv files to the
    GrowERP format.
  Parameters:
    -i input file or directory, if directory will process filenames according the [FileType]
    -u -p user/password optional, will remember from last time
    -url the base url of the backend, local host is default
    -f optional filetype, is missing will process all filetype in the specified dir
Export:
  will create CSV files for growerp entities in the current 'growerp'
  directory, if not exist will create it.
  Parameters:
    -f optional filetype, is missing will process all filetypes

flags:
  -dev if present uses development branch by installation
  -i filename : input file
  -u user : email address, with password create new company otherwise use last one
  -p password : required for new company
  -o outputDirectory : directory used for exported csv output files,default: growerp
  -url for import/export backend url
  -t receive timeout: default 60 seconds
  -f optional filetype [FileType] like glAccount, product, category etc...

## the csv to csv command
this command converts from your exported csv files to the GrowERP csv files to import. This command provides an example which was used for an existing customer previously using a SAGE50 system

Its reordering columns and incoming CSV doing optional
required conversion in the process

input parameters:
1. mandatatory the input directory name
2. optional the filetype, if missing all filetypes

examples:
dart run ~/growerp/flutter/packages/growerp/bin/csvToCsv.dart inputDir transaction
or:
dart pub global run growerp:csvToCsv

will create a new directory: growerpOutput with the converted file(s).

