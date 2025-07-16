require 'rails_helper'

RSpec.describe "StripeCheckouts", type: :request do
  describe "GET /success" do
    it "returns http success" do
      get "/stripe_checkout/success"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /cancel" do
    it "returns http success" do
      get "/stripe_checkout/cancel"
      expect(response).to have_http_status(:success)
    end
  end

end
