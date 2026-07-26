# growerp example

`growerp` is a command-line tool, not a library you import. Activate it and
run it against a GrowERP backend:

```bash
dart pub global activate growerp
export PATH="$PATH":"$HOME/.pub-cache/bin"

# install a full local GrowERP system (frontend, backend, chat) under ~/growerp
growerp install

# convert a legacy export to GrowERP's standard import CSV format
convertToCsv /path/to/legacy/export -f glAccount

# import the converted CSV files into a new company
growerp import -i growerpOutput -u user@example.com -p password -n "My Company" -c USD

# finalize the import once accounting entries have been verified
growerp finalize -u user@example.com -p password
```

See the package [README](../README.md) for the full command reference and
pre-import checklist.
