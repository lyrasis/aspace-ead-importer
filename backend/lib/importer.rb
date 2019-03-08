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

      @input  = Dir.glob("#{@import_directory}/*.xml")
      @length = @input.length

      setup
    end

    def convert
      raise "IMPORTER [#{name}]: NO FILES TO CONVERT =(" unless has_files?
      $stdout.puts "Converting files in (#{@import_directory}) to JSON (#{@json_directory}) at #{Time.now.to_s}" if @verbose

      # with_files(@input, @length, @threads) do |file|
      @input.each do |file|
        fn = File.basename(file, ".*")
        begin
          $stdout.puts "IMPORTER [#{name}]: Converting #{fn}" if @verbose
          c = Object.const_get(@converter).instance_for(@type, file)
          c.run

          FileUtils.cp(c.get_output_path, File.join(@json_directory, "#{fn}.json"))

          c.remove_files
          FileUtils.remove_file file
        rescue Exception => ex
          File.open(@import_error_file, 'a') { |f| f.puts "#{fn}: #{ex.message} #{ex.backtrace}" }
          FileUtils.mv(file, "#{file}.err")
        end
      end

      $stdout.puts "IMPORTER [#{name}]: Finished conversion to #{@json_directory} at #{Time.now.to_s}" if @verbose
    end

    def import
      raise "IMPORTER [#{name}]: BATCH DISABLED =(" unless has_batch_enabled?
      raise "IMPORTER [#{name}]: INVALID REPOSITORY =(" unless has_valid_repository?
      $stdout.puts "IMPORTER [#{name}]: Importing JSON (#{@json_directory}) at #{Time.now.to_s}" if @verbose

      input  = Dir.glob("#{@json_directory}/*.json")
      length = input.length

      # one-by-one only or else ...
      # with_files(input, length, 1) do |batch_file|
      input.each do |batch_file|
        fn = File.basename(batch_file, ".*")
        begin
          stream batch_file
          FileUtils.remove_file batch_file
          $stdout.puts "IMPORTER - Imported #{fn}" if @verbose
        rescue Exception => ex
          File.open(@json_error_file, 'a') { |f| f.puts "#{fn}: #{ex.message}" }
        end
      end if length > 0

      $stdout.puts "IMPORTER [#{name}]: Finished JSON import at #{Time.now.to_s}" if @verbose
    end

    def has_batch_enabled?
      @batch_enabled
    end

    def has_files?
      @length > 0
    end

    def has_valid_repository?
      repository = Repository.where(@repository_property => @repository_value)
      @repository_id = (repository and repository.count == 1) ? repository.first.id : nil
      @repository_id
    end

    def setup
      [
        @import_directory,
        @json_directory,
      ].each { |d| FileUtils.mkdir_p(d) }

      [
        @import_error_file,
        @json_error_file,
      ].each { |f| File.new(f, "w") }
    end

    def stream(batch_file)
      success = false
      ticker  = ArchivesSpace::Importer::Ticker.new
      DB.open(DB.supports_mvcc?, :retry_on_optimistic_locking_fail => true) do
        RequestContext.open(
          :create_enums => @create_enums,
          :current_username => @batch_username,
          :repo_id => @repository_id
        ) do
          File.open(batch_file, "r") do |fh|
            batch = StreamingImport.new(fh, ticker, false)
            batch.process
            success = true
          end
        end
      end
      raise "IMPORTER [#{name}]: Batch import failed for #{batch_file}" unless success
      success
    end

    # TODO: revist threads, single for now (monster files)
    def with_files(files_glob, length, num_threads = 1)
      threads = []
      files_glob.each_slice((length / num_threads.to_f).ceil) do |files|
        threads << Thread.new do
          files.each do |file|
            yield file
          end
        end
      end
      threads.map(&:join)
    end

    class Ticker

      def initialize(out = $stdout)
        @out = out
      end

      def tick
      end

      def status_update(status_code, status)
        @out.puts("#{status[:id]}. #{status_code.upcase}: #{status[:label]}")
      end

      def log(s)
        @out.puts(s)
      end

      def tick_estimate=(n)
      end
    end

  end

end
