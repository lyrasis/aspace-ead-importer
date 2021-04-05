# frozen_string_literal: true

require_relative 'lib/importer'

AppConfig[:importer_profiles] = [] unless AppConfig.has_key? :importer_profiles
AppConfig[:importer_schedule] = '*/5 * * * *' unless AppConfig.has_key? :importer_schedule
AppConfig[:importer_timeout]  = '1h' unless AppConfig.has_key? :importer_timeout

ArchivesSpaceService.loaded_hook do
  ArchivesSpaceService.settings.scheduler.cron(
    AppConfig[:importer_schedule],
    allow_overlapping: false, # TODO: [newer versions] overlap: false
    mutex: 'aspace.importer.schedule',
    tags: 'aspace.importer.schedule',
    timeout: AppConfig[:importer_timeout]
  ) do
    Log.info "Processing importer profiles: #{AppConfig[:importer_profiles]}"
    AppConfig[:importer_profiles].each do |profile|
      importer = ArchivesSpace::Importer.new(profile)
      # this is an additional guard to prevent a duplicate importer process from running
      next if importer.locked?

      begin
        importer.lock
        importer.convert
        importer.import
      rescue StandardError => e
        Log.warn "Importer (#{importer.name}) encountered an unexpected error:\n#{e.message}\n#{e.backtrace}"
      ensure
        importer.unlock
      end
    end
  end
end
