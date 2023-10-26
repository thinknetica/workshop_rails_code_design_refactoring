class BookPresenter
  def initialize(book)
    @book = book
  end

  def title
    book.title
  end

  def brief_description
    book.brief_description
  end
end