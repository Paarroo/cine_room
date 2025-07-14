require 'rails_helper'

RSpec.describe "reviews/new", type: :view do
  before(:each) do
    assign(:review, Review.new(
      user: nil,
      movie: nil,
      event: nil,
      rating: 1,
      comment: "MyText"
    ))
  end

  it "renders new review form" do
    render

    assert_select "form[action=?][method=?]", reviews_path, "post" do

      assert_select "input[name=?]", "review[user_id]"

      assert_select "input[name=?]", "review[movie_id]"

      assert_select "input[name=?]", "review[event_id]"

      assert_select "input[name=?]", "review[rating]"

      assert_select "textarea[name=?]", "review[comment]"
    end
  end
end
