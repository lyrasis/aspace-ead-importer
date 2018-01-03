# aspace-importer

Convert import format files (such as EAD XML or MarcXML) to JSON batch files and
(optionally) load directly into ArchivesSpace.

## Configuration examples

For EAD XML (convert to json but do not import):

```ruby
AppConfig[:importer] = {
  batch: {
    create_enums: true,
    enabled: false,
    repository: {
      repo_code: 'TEST',
    },
    username: 'admin',
  },
  import: {
    converter: "EADConverter",
    type: "ead_xml",
    directory: "/tmp/aspace/ead",
    error_file: "/tmp/aspace/ead/importer.err",
  },
  json: {
    directory: "/tmp/aspace/json",
    error_file: "/tmp/aspace/json/importer.err",
  },
  threads: 2,
  verbose: true,
}
```

For MarcXML agents and subjects (convert to json and import):

```ruby
AppConfig[:importer] = {
  batch: {
    create_enums: true,
    enabled: true,
    repository: {
      repo_code: 'TEST',
    },
    username: 'admin',
  },
  import: {
    converter: "MarcXMLConverter",
    type: "marcxml_subjects_and_agents",
    directory: "/tmp/aspace/import",
    error_file: "/tmp/aspace/import/importer.err",
  },
  json: {
    directory: "/tmp/aspace/json",
    error_file: "/tmp/aspace/json/importer.err",
  },
  threads: 2,
  verbose: true,
}
```

## Customized importers

- Add a file to `backend/model/my_converter.rb` (the name is not important).
- Define the custom converter by subclassing an existing converter

## License

This project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

---
