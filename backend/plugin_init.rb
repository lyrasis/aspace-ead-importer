require_relative 'lib/importer'

unless AppConfig.has_key? :importer
  AppConfig[:importer] = {
    batch: {
      create_enums: true,
      enabled: false,
      repository: {
        id: 2,
        # repo_code: 'TEST',
      },
      username: 'admin',
    },
    # EXAMPLE unitid converter
    # converter: {
    #   unitid: {
    #     split_pattern: "-",
    #     id_0: ->(value) { value },
    #     id_1: ->(value) { value.rjust(4, '0') },
    #   }
    # },
    import: {
      # EXAMPLE marcxml agents and subjects
      # converter: "MarcXMLConverter",
      # type: "marcxml_subjects_and_agents",
      converter: "EADConverter",
      type: "ead_xml",
      directory: "/tmp/aspace/import",
      error_file: "/tmp/aspace/import/importer.err",
    },
    json: {
      directory: "/tmp/aspace/json",
      error_file: "/tmp/aspace/json/importer.err",
    },
    schedule: nil,
    threads: 2,
    verbose: true,
  }
end

importer = ArchivesSpace::Importer.new AppConfig[:importer]
importer.convert if importer.has_files? # convert EAD to JSON batch files
importer.import  if importer.has_batch_enabled? and importer.has_valid_repository? # import JSON batch files
