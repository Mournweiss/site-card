require 'pg'
require_relative '../../lib/errors'
require_relative 'portfolio_language'
require_relative 'portfolio_tech_badge'

class Portfolio
    TABLE = 'portfolios'.freeze

    attr_reader :id, :title, :description, :image, :order_index

    def initialize(attrs)
        @id = attrs['id']
        @title = attrs['title']
        @description = attrs['description']
        @image = attrs['image']
        @order_index = attrs['order_index']
    end

    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY order_index ASC, id ASC").map { |row| Portfolio.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.all): #{e.message}", context: {class: 'Portfolio', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.all error: #{e.message}", context: {class: 'Portfolio', method: 'all', original: e})
        end
    end

    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? Portfolio.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.find): #{e.message}", context: {class: 'Portfolio', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.find error: #{e.message}", context: {class: 'Portfolio', method: 'find', id: id, original: e})
        end
    end

    def languages(conn)
        begin
            PortfolioLanguage.all_by_portfolio(conn, @id)
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.languages): #{e.message}", context: {class: 'Portfolio', method: 'languages', portfolio_id: @id, original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.languages error: #{e.message}", context: {class: 'Portfolio', method: 'languages', portfolio_id: @id, original: e})
        end
    end

    def tech_badges(conn)
        begin
            PortfolioTechBadge.all_by_portfolio(conn, @id)
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.tech_badges): #{e.message}", context: {class: 'Portfolio', method: 'tech_badges', portfolio_id: @id, original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.tech_badges error: #{e.message}", context: {class: 'Portfolio', method: 'tech_badges', portfolio_id: @id, original: e})
        end
    end
end
