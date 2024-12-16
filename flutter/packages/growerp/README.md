
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
  
### import:
  will upload data like ledger(glaccount), customers products etc from the terminal
  Also has a helper program convertToCsv to convert your files to the
    GrowERP CSV format.
  #### Parameters
  * -i input file or directory, if directory will process filenames according the [FileType]
  * -u -p user/password optional, will remember from last time
  * -url the base url of the backend, local host is default
  * -f optional filetype, is missing will process all filetype in the specified dir

### finalize:
  After all imports, this will finalize the import
  1. complete all documents which have been posted in the ledger
  2. complete order of which the invoice is completed
  3. complete past time periods

### export: (partly developed)
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

### the convertToCsv command
this command converts from your exported csv/ods/xlsx files to the GrowERP csv files to import. This command provides an example which was used for an existing customer previously using a SAGE50 system

#### input parameters:
* mandatatory the input directory name
* optional the filetype, if missing all filetypes

examples:
```bash
  dart run ~/growerp/flutter/packages/growerp/bin/convertToCsv.dart inputDir transaction
```
or after the activate growerp at the top:
```bash
  dart pub global run growerp:csvToCsv inputDir
```
will create a new directory: growerpOutput with the converted file(s).

### The conversion workflow
1. Extract csv/ods/xlsx files from the old system and put them in a single directory.
2. When importing images create an 'images' directory and a images.csv file in the format: filetype,id,filename
3. Specify the conversion rules.
    * specify the names of these files in the getFileNames function
    * specify any file wide changes in the convertFile function
    * specific the column to column conversion the convertRow function
4. convert the old system files to the GrowERP CSV format into the growerpOutput directory
    * execute activate: 
    ```bash
    dart pub global activate --source path ~/growerp/flutter/packages/growerp
    ```
    * run conversion for a single file type for testing (date optional)
    for creating starting balances you need at least a start date for the transactions 
    ```bash
    dart pub global run growerp:csvToCsv inputDir -f fileType -start yyyy/mm/dd -end yyy/mm/dd
    ```
    * run conversion for all files
    ```bash
    dart pub global run growerp:convertToCsv inputDir
    ```
5. Import the generated GrowERP csv files into the growerp system
   * execute activate 
   ```bash
   dart pub global activate growerp
   ```
   * import the generated files into the growerp system for a single file type 
   ```bash
   growerp import -i growerpOutput -d fileType -u username -p password
   ```
    * import all files
    ```bash
    growerp import -i growerpOutput -u username -p password
    ```

# the complete conversion process.

1. Export files from the old system
2. adjust the convert_to_csv program
3. Import process
  1. [pause](http://localhost:8080/vapps/system/ServiceJob/Jobs/ServiceJobDetail?jobName=recalculate_GlAccountOrgSummaries) the 'recalculate account summaries' program
  2. run the import growerp command
  3. disable the accounting seca by removing the programs as listed in the [initstart](moqui/runtime/component/growerp/deploy/initstart.sh) file under 'DISABLE_SECA' setting
  4. run the finalize growerp command
4. enable the recalculate job and restore the seca files.

