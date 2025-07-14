require 'rails_helper'

RSpec.describe "creators/new", type: :view do
  before(:each) do
    assign(:creator, Creator.new(
      user: nil,
      bio: "MyText",
      status: 1
    ))
  end

  it "renders new creator form" do
    render

    assert_select "form[action=?][method=?]", creators_path, "post" do

      assert_select "input[name=?]", "creator[user_id]"

      assert_select "textarea[name=?]", "creator[bio]"

      assert_select "input[name=?]", "creator[status]"
    end
  end
end
