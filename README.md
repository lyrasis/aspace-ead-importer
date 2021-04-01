# aspace-importer

Convert import format files (such as EAD XML or MarcXML) to JSON batch files and
(optionally) load directly into ArchivesSpace on a recurring schedule.

This plugin allows you to drop files into a directory and have them automatically
imported into ArchivesSpace.
## Configuration examples

For EAD XML (convert to json and import):

```ruby
AppConfig[:importer_profiles] = [{
  name: 'default',
  batch: {
    create_enums: true,
    enabled: true,
    repository: {
      repo_code: 'TEST'
    },
    username: 'admin'
  },
  import: {
    converter: 'EADConverter',
    type: 'ead_xml',
    directory: File.join(Dir.tmpdir, 'aspace', 'test', 'ead_xml'),
    error_file: File.join(Dir.tmpdir, 'aspace', 'test', 'ead_xml', 'importer.err')
  },
  json: {
    directory: File.join(Dir.tmpdir, 'aspace', 'test', 'json'),
    error_file: File.join(Dir.tmpdir, 'aspace', 'test', 'json', 'importer.err')
  },
  verbose: true
}]
```

For MarcXML agents and subjects (convert to json and import):

```ruby
AppConfig[:importer_profiles] = [{
  name: 'default',
  batch: {
    create_enums: true,
    enabled: true,
    repository: {
      repo_code: 'TEST'
    },
    username: 'admin'
  },
  import: {
    converter: 'MarcXMLConverter',
    type: 'marcxml_subjects_and_agents',
    directory: File.join(Dir.tmpdir, 'aspace', 'test', 'marcxml'),
    error_file: File.join(Dir.tmpdir, 'aspace', 'test', 'marcxml', 'importer.err')
  },
  json: {
    directory: File.join(Dir.tmpdir, 'aspace', 'test', 'json'),
    error_file: File.join(Dir.tmpdir, 'aspace', 'test', 'json', 'importer.err')
  },
  verbose: true
}]
```

## Schedule

Use `AppConfig[:importer_schedule]` to determine how often files are checked for. Examples:

- `AppConfig[:importer_schedule] = '*/5 * * * *'` # every 5 minutes [default]
- `AppConfig[:importer_schedule] = '0 * * * *'` # every hour

The schedule is a [cron](https://crontab.guru/) formatted string.

Import tasks are allowed to run for 1 hour by default. This can be changed with `AppConfig[:importer_timeout]`.

## Custom importers

- Add a file to `backend/model/my_converter.rb` (the name is not important).
- Define the custom converter by subclassing an existing converter
- Reference it in the config: `converter: "MyAwesomeConverter"`

## License

This project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

---
