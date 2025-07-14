require 'rails_helper'

RSpec.describe "movies/edit", type: :view do
  let(:movie) {
    Movie.create!(
      title: "MyString",
      synopsis: "MyText",
      director: "MyString",
      duration: 1,
      genre: "MyString",
      language: "MyString",
      year: 1,
      trailer_url: "MyString",
      poster_url: "MyString"
    )
  }

  before(:each) do
    assign(:movie, movie)
  end

  it "renders the edit movie form" do
    render

    assert_select "form[action=?][method=?]", movie_path(movie), "post" do

      assert_select "input[name=?]", "movie[title]"

      assert_select "textarea[name=?]", "movie[synopsis]"

      assert_select "input[name=?]", "movie[director]"

      assert_select "input[name=?]", "movie[duration]"

      assert_select "input[name=?]", "movie[genre]"

      assert_select "input[name=?]", "movie[language]"

      assert_select "input[name=?]", "movie[year]"

      assert_select "input[name=?]", "movie[trailer_url]"

      assert_select "input[name=?]", "movie[poster_url]"
    end
  end
end
