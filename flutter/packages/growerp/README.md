
# GrowERP utilities

A command line utility to easy install/import/export

Activate local version:
```bash
  dart pub global activate --source path ~/growerp/flutter/packages/growerp
```
Activate public version:
```bash
  dart pub global activate growerp
```
## The Basic global dart GrowERP command.
Sub commands:
### install:
  1. clone the repository from github into the local ~/growerp directory
  2. start the backend and chat server
  3. activate the dart melos global command.
  4. build the flutter system
  5. package 'admin' can now be started with flutter run.
  
### Import:
  will upload data like ledger(glaccount), customers products etc from the terminal
  Also has a helper program csvToCsv to convert your csv files to the
    GrowERP format.
  #### Parameters
  * -i input file or directory, if directory will process filenames according the [FileType]
  * -u -p user/password optional, will remember from last time
  * -url the base url of the backend, local host is default
  * -f optional filetype, is missing will process all filetype in the specified dir
### Export:
  will create CSV files for growerp entities in the current 'growerp'
  directory, if not exist will create it.
  #### Parameters:
  * -f optional filetype, is missing will process all filetypes

## flags:
  * -dev if present uses development branch by installation
  * -i filename : input file
  * -u user : email address, with password create new company otherwise use last one
  * -p password : required for new company
  * -o outputDirectory : directory used for exported csv output files,default: growerp
  * -url for import/export backend url
  * -t receive timeout: default 60 seconds
  * -f optional filetype [FileType] like glAccount, product, category etc...

## the csv to csv command
this command converts from your exported csv files to the GrowERP csv files to import. This command provides an example which was used for an existing customer previously using a SAGE50 system

Its reordering columns and incoming CSV doing optional
required conversion in the process

#### input parameters:
* mandatatory the input directory name
* optional the filetype, if missing all filetypes

examples:
```bash
  dart run ~/growerp/flutter/packages/growerp/bin/csvToCsv.dart inputDir transaction
```
or after the activate growerp at the top:
```bash
  dart pub global run growerp:csvToCsv inputDir
```
will create a new directory: growerpOutput with the converted file(s).

### The conversion workflow
1. Extract csv files from the old system and put them in a single directory.
2. When importing images create an 'images' directory and a images.csv file in the format: filetype,id,filename
3. Specify the conversion rules.
    * specify the names of these files in the getFileNames function
    * specify any file wide changes in the convertFile function
    * specific the column to column conversion the convertRow function
4. convert the old system files to the GrowERP CSV format into the growerpOutput directory
    * execute activate: (just the first time or after a change)
    ```bash
    dart pub global activate --source path ~/growerp/flutter/packages/growerp
    ```
    * run conversion for a single file type for testing
    ```bash
    dart pub global run growerp:csvToCsv inputDir fileType
    ```
    * run conversion for all files
    ```bash
    dart pub global run growerp:csvToCsv inputDir
    ```
5. Import the generated GrowERP csv files into the growerp system
   * execute activate (just the first time or after a change)
   ```bash
   dart pub global activate growerp
   ```
   * import the generated files into the growerp system for a single file type 
   ```bash
   growerp import -i growerpOutput fileType -u username -p password
   ```
    * import all files
    ```bash
    growerp import -i growerpOutput -u username -p password
    ```
