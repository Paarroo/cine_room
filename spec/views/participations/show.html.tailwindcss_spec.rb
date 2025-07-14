require 'rails_helper'

RSpec.describe "participations/show", type: :view do
  before(:each) do
    assign(:participation, Participation.create!(
      user: nil,
      event: nil,
      stripe_payment_id: "Stripe Payment",
      status: "Status"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Stripe Payment/)
    expect(rendered).to match(/Status/)
  end
end
