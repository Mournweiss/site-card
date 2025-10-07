require_relative './app/controllers/application_controller'

run WEBrick::HTTPServlet::AbstractServlet.get_instance(
    nil,
    AppConfig.new,
    AppLogger.new,
    Renderer.new(AppConfig.new.content),
    FormHandler.new(AppLogger.new, AppConfig.new)
)
