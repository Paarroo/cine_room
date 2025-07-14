require 'rails_helper'

RSpec.describe "movies/new", type: :view do
  before(:each) do
    assign(:movie, Movie.new(
      title: "MyString",
      synopsis: "MyText",
      director: "MyString",
      duration: 1,
      genre: "MyString",
      language: "MyString",
      year: 1,
      trailer_url: "MyString",
      poster_url: "MyString"
    ))
  end

  it "renders new movie form" do
    render

    assert_select "form[action=?][method=?]", movies_path, "post" do

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
