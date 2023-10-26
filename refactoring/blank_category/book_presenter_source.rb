class BookPresenter
  def initialize(book)
    @book = book
  end

  def title
    book.title? ? title : 'Демо книга'
  end

  def brief_description
    book.brief_description? ? brief_description : dummy_brief
  end

  private

  def dummy_brief
    'Генеративная поэтика, чтобы уловить хореический ритм или аллитерацию на "л", начинает лирический верлибр. Однако Л.В.Щерба утверждал, что типизация выбирает культурный ритмический рисунок, хотя по данному примеру нельзя судить об авторских оценках. Эти слова совершенно справедливы, однако лексика начинает поэтический зачин.'
  end
end