class Admin::ReviewsController < Admin::ApplicationController
  def index
    @reviews = Review.includes(:user, :movie, :event)
  end

  def destroy
    @review = Review.find(params[:id])
    @review.destroy
    redirect_to admin_reviews_path
  end
end
