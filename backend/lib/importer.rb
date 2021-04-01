# frozen_string_literal: true

require 'fileutils'

module ArchivesSpace
  class Importer
    attr_reader :config, :name

    def initialize(config)
      @config = config
      @name   = @config[:name]

      @batch_enabled       = @config[:batch][:enabled]
      @batch_username      = @config[:batch][:username]
      @create_enums        = @config[:batch][:create_enums]

      @repository_id       = nil # retrieve this via repo prop -> value lookup
      @repository_property = @config[:batch][:repository].keys.first
      @repository_value    = @config[:batch][:repository].values.first

      @converter           = @config[:import][:converter]
      @type                = @config[:import][:type]
      @import_directory    = @config[:import][:directory]
      @import_error_file   = @config[:import][:error_file]

      @json_directory      = @config[:json][:directory]
      @json_error_file     = @config[:json][:error_file]

      @threads             = @config[:threads]
      @verbose             = @config[:verbose]
      @lock_file           = File.join(Dir.tmpdir, "aspace.importer.#{@name}.lock")
      setup
    end

    def convert
      unless any_xml? && valid_repository?
        Log.warn("[#{name}]: skipping file conversion (no files)")
        return
      end

      total = incoming_xml.count
      Log.info "[#{name}]: converting #{total} files in (#{@import_directory}) at #{Time.now}" if @verbose

      incoming_xml.each do |file|
        fn = File.basename(file, '.*')
        begin
          Log.info "[#{name}]: Converting #{fn}" if @verbose
          with_context do
            c = Object.const_get(@converter).instance_for(@type, file)
            c.run
            FileUtils.cp(c.get_output_path, File.join(@json_directory, "#{fn}.json"))
            c.remove_files
          end

          FileUtils.remove_file file
        rescue StandardError => e
          handle_error(@import_error_file, e, file)
        end
      end

      Log.info "[#{name}]: finished conversion of #{total} files at #{Time.now}" if @verbose
    end

    def import
      unless any_json? && batch_enabled? && valid_repository?
        Log.warn("[#{name}]: skipping import (no files, batch is disabled or repository is invalid)")
        return
      end

      total = incoming_json.count
      Log.info "[#{name}]: importing #{total} files in (#{@json_directory}) at #{Time.now}" if @verbose

      incoming_json.each do |file|
        fn = File.basename(file, '.*')
        begin
          stream file
          FileUtils.remove_file file
          Log.info "[#{name}]: imported #{fn}" if @verbose
        rescue StandardError => e
          handle_error(@json_error_file, e, file)
        end
      end

      Log.info "[#{name}]: finished importing #{total} files at #{Time.now}" if @verbose
    end

    def any_json?
      incoming_json.count.positive?
    end

    def any_xml?
      incoming_xml.count.positive?
    end

    def batch_enabled?
      @batch_enabled
    end

    def lock
      FileUtils.touch @lock_file
    end

    def locked?
      File.exist? @lock_file
    end

    def stream(file)
      with_context do
        File.open(file, 'r') do |fh|
          batch = StreamingImport.new(fh, ArchivesSpace::Importer::Ticker.new, false)
          batch.process
        end
      end
    end

    def valid_repository?
      repository = Repository.where(@repository_property => @repository_value)
      @repository_id = repository && (repository.count == 1) ? repository.first.id : nil
      Log.info "[#{name}]: using repo_id #{@repository_id}" if @repository_id && @verbose
      @repository_id
    end

    def unlock
      FileUtils.remove_file @lock_file
    end

    def with_context
      DB.open(DB.supports_mvcc?, retry_on_optimistic_locking_fail: true) do
        RequestContext.open(
          create_enums: @create_enums,
          current_username: @batch_username,
          repo_id: @repository_id
        ) do
          yield
        end
      end
    end

    private

    def handle_error(error_file, error, file)
      File.open(error_file, 'a') { |f| f.puts "#{File.basename(file)}: #{error.message} #{error.backtrace}" }
      FileUtils.mv(file, "#{file}.err")
    end

    def incoming_json
      Dir.glob("#{@json_directory}/*.json")
    end

    def incoming_xml
      Dir.glob("#{@import_directory}/*.xml")
    end

    def setup
      [
        @import_directory,
        @json_directory
      ].each { |d| FileUtils.mkdir_p d }

      [
        @import_error_file,
        @json_error_file
      ].each { |f| FileUtils.touch f }
    end

    class Ticker
      def initialize(out = $stdout)
        @out = out
      end

      def tick; end

      def status_update(status_code, status)
        @out.puts("#{status[:id]}. #{status_code.upcase}: #{status[:label]}")
      end

      def log(s)
        @out.puts(s)
      end

      def tick_estimate=(n); end
    end
  end
end
