require 'erb'
require 'json'
require 'ostruct'
require_relative '../../lib/errors'
require_relative '../models/about'
require_relative '../models/skill_group'
require_relative '../models/skill'
require_relative '../models/experience'
require_relative '../models/portfolio'
require_relative '../models/portfolio_language'
require_relative '../models/portfolio_tech_badge'
require_relative '../models/contact'
require_relative '../models/career'
require_relative '../models/avatar'
require_relative '../../config/initializers/pg_repository'

class Renderer
    @repo_instance = nil
    def self.pg_repository_instance
        @repo_instance ||= PGRepository.new
    end

    PUBLIC_COMPONENTS = %w[avatar.html about.html experience.html skills.html portfolio.html contacts.html footer.html]
    ADMIN_COMPONENTS = %w[panel.html]
    COMPONENTS_PATH_PUBLIC = File.expand_path('components/public', __dir__)
    COMPONENTS_PATH_ADMIN  = File.expand_path('components/admin', __dir__)
    COMPONENTS_PATH_AUTH   = File.expand_path('components/auth', __dir__)
    LAYOUT_PATH = File.expand_path('layouts/application.html', __dir__)

    def initialize(pg_repo = nil)
        @pg_repo = pg_repo || self.class.pg_repository_instance
    end

    def render_navbar(nav_links: nil)
        navbar_path = File.expand_path('components/public/navbar.html', __dir__)
        erb_template = ERB.new(File.read(navbar_path))
        links = nav_links || [
            {href: '#avatar', label: 'Avatar'},
            {href: '#about',  label: 'About'},
            {href: '#experience', label: 'Experience'},
            {href: '#skills', label: 'Skills'},
            {href: '#portfolio', label: 'Portfolio'},
            {href: '#contacts', label: 'Contacts'}
        ]
        erb_template.result_with_hash(nav_links: links)
    end

    def render(contact_message: nil, mode: :public, nav_links: nil)
        begin
            data_ctx = load_data_context
            case mode
            when :admin
                components = ADMIN_COMPONENTS
                components_path = COMPONENTS_PATH_ADMIN
            else
                components = PUBLIC_COMPONENTS
                components_path = COMPONENTS_PATH_PUBLIC
            end

            navbar_html = (mode == :public) ? render_navbar(nav_links: nav_links) : ''

            sections_html = components.map { |file|
                path = File.join(components_path, file)
                section_name = file.gsub('.html', '')
                begin
                    if File.exist?(path)
                        erb_template = ERB.new(File.read(path))
                        html = erb_template.result_with_hash(data: (data_ctx[section_name] || {}))
                        case section_name
                        when 'skills'
                            json = json_skills(data_ctx['skills'])
                            html + "\n<script id=\"context-skills\" type=\"application/json\">#{json}</script>"
                        when 'experience'
                            json = json_experience(data_ctx['experience'])
                            html + "\n<script id=\"context-experience\" type=\"application/json\">#{json}</script>"
                        else
                            html
                        end
                    else
                        ''
                    end
                rescue Exception => e
                    raise TemplateError.new("Template error in #{file}: #{e.message}", context: {component: file, original: e})
                end
            }.join("\n")
            if contact_message && !sections_html.empty?
                sections_html = sections_html.sub('</form>', "<div class=\"alert alert-info mt-3\">#{contact_message}</div></form>")
            end
            layout_html = File.exist?(LAYOUT_PATH) ? File.read(LAYOUT_PATH) : "<html><body>#{sections_html}</body></html>"
            inject_into_layout(layout_html, sections_html, navbar_html)
        rescue SiteCardError => e
            raise
        rescue Exception => e
            raise RenderError.new("Renderer fatal error: #{e.message}", context: {component: 'renderer#render', original: e})
        end
    end

    def render_component(component, data = {})
        fname = component.to_s.gsub(/[^a-zA-Z0-9_]/, '') + '.html'
        allowed = PUBLIC_COMPONENTS + Dir.entries(COMPONENTS_PATH_PUBLIC).select{|f| f.match?(/^[a-z0-9_]+\.html$/i) }
        path = File.join(COMPONENTS_PATH_PUBLIC, fname)
        raise "Component not found" unless allowed.include?(fname) && File.exist?(path)
        ERB.new(File.read(path)).result_with_hash(data: data)
    end

    private

    def load_data_context
        ctx = {}
        @pg_repo.with_connection do |conn|

            begin
                about = About.fetch(conn) || OpenStruct.new(age: '', location: '', education: '', languages: '')
            rescue Exception => e
                raise BDError.new("DB fetch failed (about): #{e.message}", context: {component: 'about', original: e})
            end
            begin
                avatar = Avatar.fetch(conn) || OpenStruct.new(name: '', role: '', description: '')
            rescue Exception => e
                raise BDError.new("DB fetch failed (avatar): #{e.message}", context: {component: 'avatar', original: e})
            end
            begin
                careers = (about && about.id) ? Career.all_by_about(conn, about.id) : []
            rescue Exception => e
                raise BDError.new("DB fetch failed (Career): #{e.message}", context: {component: 'career', original: e})
            end
            ctx['about'] = { about: about, languages: about.languages, careers: careers }
            ctx['avatar'] = { avatar: avatar, img_src: avatar.image_url }

            begin
                skill_groups = SkillGroup.all(conn) || []
            rescue Exception => e
                raise BDError.new("DB fetch failed (SkillGroup): #{e.message}", context: {component: 'skill_group', original: e})
            end
            skill_hash = skill_groups.map do |group|
                begin
                    skills = Skill.all_by_group(conn, group.id) || []
                rescue Exception => e
                    raise BDError.new("DB fetch failed (Skill): #{e.message}", context: {component: 'skill', group_id: group.id, original: e})
                end
                {
                    group: group,
                    skills: skills
                }
            end
            ctx['skills'] = { skill_groups: skill_hash }

            begin
                experiences = Experience.all(conn) || []
            rescue Exception => e
                raise BDError.new("DB fetch failed (Experience): #{e.message}", context: {component: 'experience', original: e})
            end
            ctx['experience'] = { experiences: experiences }

            begin
                portfolios = Portfolio.all(conn) || []
            rescue Exception => e
                raise BDError.new("DB fetch failed (Portfolio): #{e.message}", context: {component: 'portfolio', original: e})
            end
            portfolio_blocks = portfolios.map do |p|
                begin
                    languages = p.languages(conn) || []
                rescue Exception => e
                    raise BDError.new("DB fetch failed (PortfolioLanguage): #{e.message}", context: {component: 'portfolio_language', portfolio_id: p.id, original: e})
                end
                begin
                    tech_badges = p.tech_badges(conn) || []
                rescue Exception => e
                    raise BDError.new("DB fetch failed (PortfolioTechBadge): #{e.message}", context: {component: 'portfolio_tech_badge', portfolio_id: p.id, original: e})
                end
                {
                    portfolio: p,
                    languages: languages,
                    tech_badges: tech_badges
                }
            end
            ctx['portfolio'] = { portfolios: portfolio_blocks }

            begin
                contacts = Contact.all(conn) || []
            rescue Exception => e
                raise BDError.new("DB fetch failed (Contact): #{e.message}", context: {component: 'contact', original: e})
            end
            ctx['contacts'] = { contacts: contacts }
        end
        ctx
    end

    def json_skills(ctx)
        groups = ctx[:skill_groups] || []
        piectx = []
        groups.each_with_index do |h, idx|
            skill_colors = h[:skills].map { |s| s.color || '#888888' }
            piectx << {
                id: "about-skill-chart-#{idx+1}",
                label: h[:group].name,
                labels: h[:skills].map { |s| s.name },
                data: h[:skills].map { |s| s.level },
                colors: skill_colors,
                width: 378, height: 378
            }
        end
        JSON.generate(piectx)
    end

    def json_experience(ctx)
        arr = ctx[:experiences] || []
        JSON.generate({
            labels: arr.map { |e| e.label },
            datasets: [{ label: "Experience", data: arr.map { |e| e.value }, fill: true, backgroundColor: "rgba(60,140,255,0.22)", borderColor: "#54a3fa", pointBackgroundColor: "#3c7fff", tension: 0.4 }]
        })
    end

    def inject_into_layout(layout_html, sections_html, navbar_html = '')
        layout_with_nav = navbar_html && !navbar_html.empty? ? layout_html.sub('<body>', "<body>\n#{navbar_html}") : layout_html
        layout_with_nav.gsub(
            /<main class="container py-4">.*?<\/main>/m,
            "<main class=\"container py-4\">#{sections_html}</main>"
        )
    end
end
