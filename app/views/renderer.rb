require 'erb'

class Renderer
    COMPONENTS_PATH = File.expand_path('components', __dir__)
    LAYOUT_PATH = File.expand_path('layouts/application.html', __dir__)

    def initialize(content)
        @content = content
    end

    def render(section)
        component_html = render_component(section)
        layout_html = File.exist?(LAYOUT_PATH) ? File.read(LAYOUT_PATH) : "<html><body>#{component_html}</body></html>"
        inject_into_layout(layout_html, component_html)
    end

    private

    def render_component(section)
        file = component_file(section)
        if file && File.exist?(file)
            File.read(file)
        else
            "<h1>404 Not Found</h1>"
        end
    end

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

    def inject_into_layout(layout_html, component_html)
        layout_html.gsub('<main class="container py-4"></main>', "<main class=\"container py-4\">#{component_html}</main>")
    end

    def h(text)
        ERB::Util.html_escape(text)
    end
end
