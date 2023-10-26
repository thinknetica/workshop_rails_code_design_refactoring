require_relative './promocode_generator_service'

RSpec.describe PromocodesImportService do
  it "sums the prices of its line items" do
    valid_since = Date.new(2023, 11, 1)
    valid_until = Date.new(2023, 11, 20)
    service = PromocodesImportService.new('Книга', valid_since, valid_until, File.path('./codes.xlsx'))
    result = service.perform

    expect(result.items_imported).to eq(41)
    expect(result.status).to eq('completed')
  end
end


# исходник
# RSpec.describe PromocodesImportService do
#   it "sums the prices of its line items" do
#     valid_since = Date.new(2023, 11, 1)
#     valid_until = Date.new(2023, 11, 20)
#     service = PromocodesImportService.new('Книга', valid_since, valid_until, File.path('./codes.xlsx'))
#     result = service.perform

#     expect(result).to eq({ products_created: 41, status: :succeeded })
#   end
# end
