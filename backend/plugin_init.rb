require_relative 'lib/importer'

unless AppConfig.has_key? :ead_importer
  AppConfig[:ead_importer] = {
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
    ead: {
      converter: "ImporterEADConverter",
      directory: "/tmp/aspace/ead",
      error_file: "/tmp/aspace/ead/ead-importer.err",
    },
    json: {
      directory: "/tmp/aspace/json",
      error_file: "/tmp/aspace/json/ead-importer.err",
    },
    schedule: nil,
    threads: 2,
    verbose: true,
  }
end

importer = ArchivesSpace::Importer.new AppConfig[:ead_importer]
importer.convert if importer.has_ead_files? # convert EAD to JSON batch files
importer.import  if importer.has_batch_enabled? and importer.has_valid_repository? # import JSON batch files
