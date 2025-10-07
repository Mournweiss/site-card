require 'erb'

class Renderer
    COMPONENTS_PATH = File.expand_path('../components', __dir__)

    def initialize(content)
        @content = content
    end

    def render(section)
        file = component_file(section)
        if file && File.exist?(file)
            File.read(file)
        else
            "<h1>404 Not Found</h1>"
        end
    end

    private

    def component_file(section)
        name = case section
            when 'Home' then 'home.html'
            when 'About' then 'about.html'
            when 'Portfolio' then 'portfolio.html'
            when 'Contacts' then 'contacts.html'
            else nil
        end
        name ? File.join(COMPONENTS_PATH, name) : nil
    end

    def h(text)
        ERB::Util.html_escape(text)
    end
end
