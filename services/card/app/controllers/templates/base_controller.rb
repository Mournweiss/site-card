class BaseController
    attr_reader :config, :logger

    def initialize(config, logger)
        @config = config
        @logger = logger
    end

    def handle_request(method, path, req, res)
        res.status = 501
        res.body = '<h1>501 Not Implemented</h1>'
    end

    protected
    def render_template(path, params = {})
        tpl = File.read(path)
        ERB.new(tpl).result_with_hash(params)
    end
end
