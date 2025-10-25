require 'pg'
require_relative '../../lib/errors'

class PortfolioLanguage
    TABLE = 'portfolio_languages'.freeze

    attr_reader :id, :portfolio_id, :name, :percent, :color, :order_index

    def initialize(attrs)
        @id = attrs['id']
        @portfolio_id = attrs['portfolio_id']
        @name = attrs['name']
        @percent = attrs['percent']
        @color = attrs['color']
        @order_index = attrs['order_index']
    end

    def self.all_by_portfolio(conn, portfolio_id)
        begin
            conn.exec_params("SELECT * FROM #{TABLE} WHERE portfolio_id = $1 ORDER BY order_index ASC, id ASC", [portfolio_id]).map { |row| PortfolioLanguage.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (PortfolioLanguage.all_by_portfolio): #{e.message}", context: {class: 'PortfolioLanguage', method: 'all_by_portfolio', portfolio_id: portfolio_id, original: e})
        rescue => e
            raise DataConsistencyError.new("PortfolioLanguage.all_by_portfolio error: #{e.message}", context: {class: 'PortfolioLanguage', method: 'all_by_portfolio', portfolio_id: portfolio_id, original: e})
        end
    end

    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? PortfolioLanguage.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (PortfolioLanguage.find): #{e.message}", context: {class: 'PortfolioLanguage', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("PortfolioLanguage.find error: #{e.message}", context: {class: 'PortfolioLanguage', method: 'find', id: id, original: e})
        end
    end
end
