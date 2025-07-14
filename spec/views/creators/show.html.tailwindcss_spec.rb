require 'rails_helper'

RSpec.describe "creators/show", type: :view do
  before(:each) do
    assign(:creator, Creator.create!(
      user: nil,
      bio: "MyText",
      status: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/2/)
  end
end
