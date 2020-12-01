module MQPI
  class Handler
    attr_accessor :name, :port, :host, :job_options
    def initialize(name: nil, port: nil, host: nil, logger: Logger.new(STDOUT), job_options: {})
      @name = name
      @port = port
      @host = host
      @logger = logger
      @job_options = job_options
    end

    def run
      client = connect
      topic = "per-host/#{@name}"

      client.subscribe(topic)
      @logger.info("Subscribed to #{topic}")

      client.get(topic => 1) do |_topic, message|
        @logger.debug "Forking new process"
        pid = fork { Job.new_from_message(message, @logger, @job_options).execute }
        Process.detach(pid) # Or maybe double fork to reparent under init?
      end
    end

    def connect
      client = MQTT::Client.new(
        host: @host,
        port: @port,
        clean_session: false,
        client_id: Digest::SHA256.hexdigest(@name)[0..16]
      )
      client.connect()
      @logger.info("Connected to broker at #{@host}:#{@port}")
      client
    end
  end
end
