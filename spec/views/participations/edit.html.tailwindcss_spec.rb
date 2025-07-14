require 'rails_helper'

RSpec.describe "participations/edit", type: :view do
  let(:participation) {
    Participation.create!(
      user: nil,
      event: nil,
      stripe_payment_id: "MyString",
      status: "MyString"
    )
  }

  before(:each) do
    assign(:participation, participation)
  end

  it "renders the edit participation form" do
    render

    assert_select "form[action=?][method=?]", participation_path(participation), "post" do

      assert_select "input[name=?]", "participation[user_id]"

      assert_select "input[name=?]", "participation[event_id]"

      assert_select "input[name=?]", "participation[stripe_payment_id]"

      assert_select "input[name=?]", "participation[status]"
    end
  end
end
