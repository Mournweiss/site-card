# Abstract base controller for other controllers to inherit common logic/config access
class BaseController
    attr_reader :config, :logger

    # Initializes the controller with config and logger instances.
    #
    # Parameters:
    # - config: Object - global app configuration reference
    # - logger: Object - logger instance to be used for error/info logging
    def initialize(config, logger)
        @config = config
        @logger = logger
    end

    # Main request handler stub (to be overridden in subclasses). Responds 501 by default.
    #
    # Parameters:
    # - method: String - HTTP method (e.g., 'GET', 'POST')
    # - path: String - request path/route
    # - req: Object - request object from framework
    # - res: Object - response object to be filled
    #
    # Returns:
    # - nil
    def handle_request(method, path, req, res)
        res.status = 501
        res.body = '<h1>501 Not Implemented</h1>'
    end

    protected

    # Renders an ERB template at a given file path with provided locals.
    #
    # Parameters:
    # - path: String - absolute/relative path to the ERB view file
    # - params: Hash (default: empty) - locals to inject into template binding
    #
    # Returns:
    # - String - rendered content from the ERB template
    def render_template(path, params = {})
        tpl = File.read(path)
        ERB.new(tpl).result_with_hash(params)
    end
end
