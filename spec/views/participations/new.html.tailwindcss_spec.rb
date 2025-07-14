require 'rails_helper'

RSpec.describe "participations/new", type: :view do
  before(:each) do
    assign(:participation, Participation.new(
      user: nil,
      event: nil,
      stripe_payment_id: "MyString",
      status: "MyString"
    ))
  end

  it "renders new participation form" do
    render

    assert_select "form[action=?][method=?]", participations_path, "post" do

      assert_select "input[name=?]", "participation[user_id]"

      assert_select "input[name=?]", "participation[event_id]"

      assert_select "input[name=?]", "participation[stripe_payment_id]"

      assert_select "input[name=?]", "participation[status]"
    end
  end
end
