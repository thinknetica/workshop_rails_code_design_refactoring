class BooksController
  def show
    book = Book.find_by(key: params[:id])

    render book: BookPresenter.new(book || NullBook.new)
  end
end

class NullBook
  def title
    'Демо книга'
  end

  def breaf_description
    'Генеративная поэтика, чтобы уловить хореический ритм или аллитерацию на "л", начинает лирический верлибр. Однако Л.В.Щерба утверждал, что типизация выбирает культурный ритмический рисунок, хотя по данному примеру нельзя судить об авторских оценках. Эти слова совершенно справедливы, однако лексика начинает поэтический зачин.'
  end
end