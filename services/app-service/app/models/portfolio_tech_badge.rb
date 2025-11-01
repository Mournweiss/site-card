require 'pg'
require_relative '../../lib/errors'

class PortfolioTechBadge
    TABLE = 'portfolio_tech_badges'.freeze

    attr_reader :id, :portfolio_id, :name, :icon

    def initialize(attrs)
        @id = attrs['id']
        @portfolio_id = attrs['portfolio_id']
        @name = attrs['name']
        @icon = attrs['icon']
    end

    def self.all_by_portfolio(conn, portfolio_id)
        begin
            conn.exec_params("SELECT * FROM #{TABLE} WHERE portfolio_id = $1 ORDER BY id ASC", [portfolio_id]).map { |row| PortfolioTechBadge.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (PortfolioTechBadge.all_by_portfolio): #{e.message}", context: {class: 'PortfolioTechBadge', method: 'all_by_portfolio', portfolio_id: portfolio_id, original: e})
        rescue => e
            raise DataConsistencyError.new("PortfolioTechBadge.all_by_portfolio error: #{e.message}", context: {class: 'PortfolioTechBadge', method: 'all_by_portfolio', portfolio_id: portfolio_id, original: e})
        end
    end

    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? PortfolioTechBadge.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (PortfolioTechBadge.find): #{e.message}", context: {class: 'PortfolioTechBadge', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("PortfolioTechBadge.find error: #{e.message}", context: {class: 'PortfolioTechBadge', method: 'find', id: id, original: e})
        end
    end
end
