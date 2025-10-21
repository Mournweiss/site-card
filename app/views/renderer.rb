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
require_relative '../../config/initializers/pg_repository'

class Renderer
    COMPONENTS = %w[avatar.html about.html experience.html skills.html portfolio.html contacts.html]
    COMPONENTS_PATH = File.expand_path('components', __dir__)
    LAYOUT_PATH = File.expand_path('layouts/application.html', __dir__)

    def initialize(pg_repo = PGRepository.new)
        @pg_repo = pg_repo
    end

    def render(contact_message: nil)
        begin
            data_ctx = load_data_context
            sections_html = COMPONENTS.map { |file|
                path = File.join(COMPONENTS_PATH, file)
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
            inject_into_layout(layout_html, sections_html)
        rescue SiteCardError => e
            raise
        rescue Exception => e
            raise RenderError.new("Renderer fatal error: #{e.message}", context: {component: 'renderer#render', original: e})
        end
    end

    private

    def load_data_context
        ctx = {}
        @pg_repo.with_connection do |conn|

            begin
                about = About.fetch(conn) || OpenStruct.new(name: '', age: '', location: '', education: '', description: '', timezone: '')
            rescue Exception => e
                raise BDError.new("DB fetch failed (about): #{e.message}", context: {component: 'about', original: e})
            end
            ctx['about'] = { about: about }

            ctx['avatar'] = { about: about }

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
        groups.each do |h|
            piectx << {
                label: h[:group].name,
                labels: h[:skills].map { |s| s.name },
                data: h[:skills].map { |s| s.level },
                colors: Array.new(h[:skills].length) { _color_for_skill },
                # colors: ideally, fetch from DB or config - here, stub per PLAN.md
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

    def _color_for_skill
        ["#4485FE", "#EA4F52", "#32DCB8", "#2396ED", "#3759da", "#fbab1d", "#7ba9fa", "#5BFFD9", "#6a40c5", "#1e1b2d"].sample
    end

    def inject_into_layout(layout_html, sections_html)
        layout_html.gsub(
            /<main class="container py-4">.*?<\/main>/m,
            "<main class=\"container py-4\">#{sections_html}</main>"
        )
    end
end
