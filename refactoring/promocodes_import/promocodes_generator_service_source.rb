require 'logger'
require 'simple_xlsx_reader'

class PromocodesImportService
  def initialize(product_name, valid_since, valid_until, import_file_path)
    @product_name = product_name
    @valid_since = valid_since
    @valid_until = valid_until
    @import_file_path = import_file_path
  end

  def perform
    doc = SimpleXlsxReader.open(@import_file_path)
    product = Product.find_by(name: @product_name)
    raise "Product not found" if product.nil?
    raise "Valid until less than valid since not found" if @valid_since > @valid_until

    rows = doc.sheets.first.rows
    total_count = rows.count
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger.info "Started import with #{total_count} items"
    result = { products_created: 0, status: :processing }

    rows.each_with_index do |row, index|
      Promocode.create!(code: row.first, valid_since: @valid_since, valid_until: @valid_until)
      one_persent = total_count / 100 == 0 ? 1 : total_count / 100
      logger.info "Обработали #{index} строк" if (total_count % (one_persent) == 0)
      result[:products_created] += 1
    end

    result[:status] = :succeeded
    result
  rescue StandardError
    result[:status] = :failed
    result
  end
end

class Promocode
  def self.create!(**)
  end
end

class Product < Struct.new(:name)
  def self.find_by(name)
    new(name)
  end
end
