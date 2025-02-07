module TypesenseModel
  class Configuration
    attr_accessor :api_key, :host, :port, :protocol

    def initialize
      @api_key = nil
      @host = 'localhost'
      @port = 8108
      @protocol = 'http'
    end

    def client
      @client ||= Typesense::Client.new(
        api_key: api_key,
        nodes: [{
          host: host,
          port: port,
          protocol: protocol
        }],
        connection_timeout_seconds: 5
      )
    end
  end
end 