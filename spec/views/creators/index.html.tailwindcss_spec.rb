require 'rails_helper'

RSpec.describe "creators/index", type: :view do
  before(:each) do
    assign(:creators, [
      Creator.create!(
        user: nil,
        bio: "MyText",
        status: 2
      ),
      Creator.create!(
        user: nil,
        bio: "MyText",
        status: 2
      )
    ])
  end

  it "renders a list of creators" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
