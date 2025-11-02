require 'pg'
require_relative '../../lib/errors'

# Describes programming languages, percentages, and palette used in a portfolio section.
class PortfolioLanguage
    TABLE = 'portfolio_languages'.freeze

    attr_reader :id, :portfolio_id, :name, :percent, :color, :order_index

    # Initializes a PortfolioLanguage association for a project.
    #
    # Parameters:
    # - id: String|Integer - language ID
    # - portfolio_id: String|Integer - associated project's ID
    # - name: String - language name
    # - percent: String|Numeric - percentage (as a string)
    # - color: String - color code (hex or CSS)
    # - order_index: String|Integer - ordering position
    #
    # Returns: PortfolioLanguage
    def initialize(attrs)
        @id = attrs['id']
        @portfolio_id = attrs['portfolio_id']
        @name = attrs['name']
        @percent = attrs['percent']
        @color = attrs['color']
        @order_index = attrs['order_index']
    end

    # Returns all language rows for given portfolio, ordered by index.
    #
    # Parameters:
    # - conn: PG::Connection
    # - portfolio_id: String|Integer
    #
    # Returns: Array<PortfolioLanguage>
    #
    # Raises:
    # - BDError/DataConsistencyError on DB errors
    def self.all_by_portfolio(conn, portfolio_id)
        begin
            conn.exec_params("SELECT * FROM #{TABLE} WHERE portfolio_id = $1 ORDER BY order_index ASC, id ASC", [portfolio_id]).map { |row| PortfolioLanguage.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (PortfolioLanguage.all_by_portfolio): #{e.message}", context: {class: 'PortfolioLanguage', method: 'all_by_portfolio', portfolio_id: portfolio_id, original: e})
        rescue => e
            raise DataConsistencyError.new("PortfolioLanguage.all_by_portfolio error: #{e.message}", context: {class: 'PortfolioLanguage', method: 'all_by_portfolio', portfolio_id: portfolio_id, original: e})
        end
    end

    # Finds one PortfolioLanguage by id.
    #
    # Parameters:
    # - conn: PG::Connection
    # - id: String|Integer
    #
    # Returns: PortfolioLanguage|nil
    #
    # Raises:
    # - BDError/DataConsistencyError on errors
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
