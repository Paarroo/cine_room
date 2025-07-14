require 'rails_helper'

RSpec.describe "reviews/edit", type: :view do
  let(:review) {
    Review.create!(
      user: nil,
      movie: nil,
      event: nil,
      rating: 1,
      comment: "MyText"
    )
  }

  before(:each) do
    assign(:review, review)
  end

  it "renders the edit review form" do
    render

    assert_select "form[action=?][method=?]", review_path(review), "post" do

      assert_select "input[name=?]", "review[user_id]"

      assert_select "input[name=?]", "review[movie_id]"

      assert_select "input[name=?]", "review[event_id]"

      assert_select "input[name=?]", "review[rating]"

      assert_select "textarea[name=?]", "review[comment]"
    end
  end
end
