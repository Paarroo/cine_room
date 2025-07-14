require 'rails_helper'

RSpec.describe "events/new", type: :view do
  before(:each) do
    assign(:event, Event.new(
      movie: nil,
      title: "MyString",
      description: "MyText",
      venue_name: "MyString",
      venue_address: "MyString",
      max_capacity: 1,
      price_cents: 1,
      status: "MyString"
    ))
  end

  it "renders new event form" do
    render

    assert_select "form[action=?][method=?]", events_path, "post" do

      assert_select "input[name=?]", "event[movie_id]"

      assert_select "input[name=?]", "event[title]"

      assert_select "textarea[name=?]", "event[description]"

      assert_select "input[name=?]", "event[venue_name]"

      assert_select "input[name=?]", "event[venue_address]"

      assert_select "input[name=?]", "event[max_capacity]"

      assert_select "input[name=?]", "event[price_cents]"

      assert_select "input[name=?]", "event[status]"
    end
  end
end
