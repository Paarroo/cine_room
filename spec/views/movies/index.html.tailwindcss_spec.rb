require 'rails_helper'

RSpec.describe "movies/index", type: :view do
  before(:each) do
    assign(:movies, [
      Movie.create!(
        title: "Title",
        synopsis: "MyText",
        director: "Director",
        duration: 2,
        genre: "Genre",
        language: "Language",
        year: 3,
        trailer_url: "Trailer Url",
        poster_url: "Poster Url"
      ),
      Movie.create!(
        title: "Title",
        synopsis: "MyText",
        director: "Director",
        duration: 2,
        genre: "Genre",
        language: "Language",
        year: 3,
        trailer_url: "Trailer Url",
        poster_url: "Poster Url"
      )
    ])
  end

  it "renders a list of movies" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Director".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Genre".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Language".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Trailer Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Poster Url".to_s), count: 2
  end
end
