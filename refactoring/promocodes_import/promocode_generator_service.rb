require 'logger'
require 'simple_xlsx_reader'

class PromocodesImportService
  ValidationError = Class.new StandardError

  def initialize(product_name, valid_since, valid_until, import_file_path)
    @valid_since = valid_since
    @valid_until = valid_until
    @import_file_path = import_file_path
    @product = Product.find_by(name: product_name)
  end

  def perform
    validate_presence_product!
    validate_promocode_period!

    total_count = codes_to_import.count
    import_log.start
    codes_to_import.each.with_index(1) do |code_details, completed_count|
      create_promocode(code_details.first)
      track_progress(total_count:, completed_count:)
      import_log.item_importred
    end

    import_log.complete
    import_log
  rescue ValidationError
    import_log.fail
    import_log
  end

  private

  attr_reader :product, :valid_since, :valid_until

  def validate_presence_product!
    raise ValidationError, "Product not found" if product.nil?
  end

  def validate_promocode_period!
    raise ValidationError, "Valid until less than valid since not found" if valid_since > valid_until
  end

  def create_promocode(code)
    Promocode.create!(code:, valid_since:, valid_until:)
  end

  def codes_to_import
    @rows ||= begin
      doc = SimpleXlsxReader.open(@import_file_path)
      doc.sheets.first.rows
    end
  end

  def track_progress(total_count:, completed_count:)
    one_persent = total_count / 100 == 0 ? 1 : total_count / 100
    logger.info "Обработали #{completed_count} строк" if (total_count % (one_persent) == 0)
  end

  def import_log
    @import_log ||= ImportLog.new
  end

  def logger
    @logger ||= begin
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger
    end
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

class ImportLog
  def initialize
    @items_imported = 0
    @status = 'idle'
  end

  attr_reader :items_imported, :status

  def start
    @status = 'processing'
  end

  def complete
    @status = 'completed'
  end

  def fail
    @status = 'failed'
  end

  def item_importred
    @items_imported += 1 
  end
end
