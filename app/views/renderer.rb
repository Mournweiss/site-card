class Renderer
    COMPONENTS = %w[avatar.html about.html experience.html skills.html portfolio.html contacts.html]
    COMPONENTS_PATH = File.expand_path('components', __dir__)
    LAYOUT_PATH = File.expand_path('layouts/application.html', __dir__)

    def render(contact_message: nil)
        sections_html = COMPONENTS.map { |file|
            path = File.join(COMPONENTS_PATH, file)
            File.exist?(path) ? File.read(path) : ''
        }.join("\n")
        if contact_message && !sections_html.empty?
            sections_html = sections_html.sub('</form>', "<div class=\"alert alert-info mt-3\">#{contact_message}</div></form>")
        end
        layout_html = File.exist?(LAYOUT_PATH) ? File.read(LAYOUT_PATH) : "<html><body>#{sections_html}</body></html>"
        inject_into_layout(layout_html, sections_html)
    end

    private

    def inject_into_layout(layout_html, sections_html)
        layout_html.gsub(
            /<main class="container py-4">.*?<\/main>/m,
            "<main class=\"container py-4\">#{sections_html}</main>"
        )
    end
end
