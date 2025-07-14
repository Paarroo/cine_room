require 'rails_helper'

RSpec.describe "events/index", type: :view do
  before(:each) do
    assign(:events, [
      Event.create!(
        movie: nil,
        title: "Title",
        description: "MyText",
        venue_name: "Venue Name",
        venue_address: "Venue Address",
        max_capacity: 2,
        price_cents: 3,
        status: "Status"
      ),
      Event.create!(
        movie: nil,
        title: "Title",
        description: "MyText",
        venue_name: "Venue Name",
        venue_address: "Venue Address",
        max_capacity: 2,
        price_cents: 3,
        status: "Status"
      )
    ])
  end

  it "renders a list of events" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Venue Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Venue Address".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Status".to_s), count: 2
  end
end
