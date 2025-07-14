require 'rails_helper'

RSpec.describe "participations/index", type: :view do
  before(:each) do
    assign(:participations, [
      Participation.create!(
        user: nil,
        event: nil,
        stripe_payment_id: "Stripe Payment",
        status: "Status"
      ),
      Participation.create!(
        user: nil,
        event: nil,
        stripe_payment_id: "Stripe Payment",
        status: "Status"
      )
    ])
  end

  it "renders a list of participations" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Stripe Payment".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Status".to_s), count: 2
  end
end
