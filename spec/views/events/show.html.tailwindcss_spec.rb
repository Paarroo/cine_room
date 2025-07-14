require 'rails_helper'

RSpec.describe "events/show", type: :view do
  before(:each) do
    assign(:event, Event.create!(
      movie: nil,
      title: "Title",
      description: "MyText",
      venue_name: "Venue Name",
      venue_address: "Venue Address",
      max_capacity: 2,
      price_cents: 3,
      status: "Status"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Venue Name/)
    expect(rendered).to match(/Venue Address/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Status/)
  end
end
