require 'rails_helper'

RSpec.describe "creators/edit", type: :view do
  let(:creator) {
    Creator.create!(
      user: nil,
      bio: "MyText",
      status: 1
    )
  }

  before(:each) do
    assign(:creator, creator)
  end

  it "renders the edit creator form" do
    render

    assert_select "form[action=?][method=?]", creator_path(creator), "post" do

      assert_select "input[name=?]", "creator[user_id]"

      assert_select "textarea[name=?]", "creator[bio]"

      assert_select "input[name=?]", "creator[status]"
    end
  end
end
