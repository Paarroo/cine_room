require 'rails_helper'

RSpec.describe "movies/show", type: :view do
  before(:each) do
    assign(:movie, Movie.create!(
      title: "Title",
      synopsis: "MyText",
      director: "Director",
      duration: 2,
      genre: "Genre",
      language: "Language",
      year: 3,
      trailer_url: "Trailer Url",
      poster_url: "Poster Url"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Director/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Genre/)
    expect(rendered).to match(/Language/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Trailer Url/)
    expect(rendered).to match(/Poster Url/)
  end
end
