require 'fileutils'

module ArchivesSpace

  class Importer

    attr_reader :config

    def initialize(config)
      @config = config

      @batch_enabled       = @config[:batch][:enabled]
      @repository_property = @config[:batch][:repository].keys.first
      @repository_value    = @config[:batch][:repository].values.first
      @ead_directory       = @config[:ead][:directory]
      @ead_error_file      = @config[:ead][:error_file]
      @json_directory      = @config[:json][:directory]
      @json_error_file     = @config[:json][:error_file]
      @threads             = @config[:threads]
      @verbose             = @config[:verbose]

      @input  = Dir.glob("#{@ead_directory}/*.xml")
      @length = @input.length

      setup
    end

    def convert
      raise "NO EAD FILES TO CONVERT =(" unless has_ead_files?
      $stdout.puts "Converting EAD (#{@ead_directory}) to JSON (#{@json_directory}) at #{Time.now.to_s}" if @verbose
      
      threads = []
      @input.each_slice((@length / @threads.to_f).ceil) do |files|
        threads << Thread.new do
          files.each do |ead_file|
            fn = File.basename(ead_file, ".*")
            begin
              c = Converter.for('ead_xml', ead_file)
              c.run

              FileUtils.cp(c.get_output_path, File.join(@json_directory, "#{fn}.json"))

              c.remove_files
              FileUtils.remove_file ead_file
            rescue Exception => ex
              File.open(@ead_error_file, 'a') { |f| f.puts "#{fn}: #{ex.message}" }
            end
          end
        end
      end

      threads.map(&:join)
      $stdout.puts "Finished EAD conversion to #{@json_directory} at #{Time.now.to_s}" if @verbose
    end

    def import
      raise "BATCH DISABLED =(" unless has_batch_enabled?
      raise "INVALID REPOSITORY =(" unless has_valid_repository?
      $stdout.puts "Importing JSON (#{@json_directory}) at #{Time.now.to_s}" if @verbose

      Dir.glob("#{@json_directory}/*.json").each do |batch_file|
        fn = File.basename(batch_file, ".*")
        begin
          # TODO
          FileUtils.remove_file batch_file
        rescue Exception => ex
          File.open(@json_error_file, 'a') { |f| f.puts "#{fn}: #{ex.message}" }
        end
      end

      $stdout.puts "Finished JSON import at #{Time.now.to_s}" if @verbose
    end

    def has_batch_enabled?
      @batch_enabled
    end

    def has_ead_files?
      @length > 0
    end

    def has_valid_repository?
      # TODO
      # fail if cannot find repository
      false
    end

    def setup
      [
        @ead_directory,
        @json_directory,
      ].each { |d| FileUtils.mkdir_p(d) }

      [
        @ead_error_file,
        @json_error_file,
      ].each { |f| File.new(f, "w") }
    end

  end

end