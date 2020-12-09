module MQPI
  class Job
    def initialize(task_id, step_id, files, main, callback_host, otp, logger: Logger.new(STDOUT), options: {})
      @task_id = task_id
      @step_id = step_id
      @files = files
      @main = main
      @callback_host = callback_host
      @otp = otp
      @logger = logger
      @log_prefix = "#{task_id} #{step_id}"
      @options = options
    end

    def execute
      @logger.debug("#{@log_prefix} Processing job in process #{Process.pid}")
      with_working_directory do
        download_files
        extract_files
        execute_main
        # unreachable
      end
      # unreachable
    end

    def with_working_directory
      dir = Dir.mktmpdir
      Dir.chdir(dir) do
        @logger.debug("#{@log_prefix} Base directory is #{dir}")
        yield
        # unreachable
      end
    end

    def execute_main
      @logger.debug("#{@log_prefix} Executing into ./#{@main}")
      STDOUT.flush
      Kernel.exec("./#{@main}")
    end

    def extract_files
      @files.each do |file|
        if file.end_with? '.tar'
          name = File.basename(file)
          @logger.debug("Extracting #{name}")
          system("tar", "-xf", name)
        end
      end
    end

    def download_files
      uri = URI(@callback_host)
      Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https',
        :verify_mode => @options[:insecure] ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
      ) do |http|
        @files.each do |path|
          name = File.basename(path)
          uri.path = path
          @logger.debug("#{@log_prefix} Downloading #{uri} to #{name}")

          req = Net::HTTP::Get.new(uri)
          req.basic_auth @task_id, @otp

          http.request req do |response|
            File.open(name, 'w') do |io|
              response.read_body { |chunk| io.write(chunk) }
            end
            File.chmod(0700, name)
          end
        end
      end
    end

    def self.new_from_message(message, logger = Logger.new(STDOUT), options = {})
      data = JSON.parse(message)
      Job.new(*data.values_at(*%w[task_id step_id files main callback_host otp]), logger: logger, options: options)
    end
  end
end
