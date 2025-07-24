class ReviewsController < ApplicationController
  before_action :set_review, only: [ :show, :edit, :update, :destroy ]
  before_action :set_event, only: [ :new, :create ]

  def index
    @reviews = Review.includes(:user, :movie, :event)
                     .order(created_at: :desc)
                     .page(params[:page])
  end

  def show
  end

  def new
    @review = current_user.reviews.build(event: @event, movie: @event.movie)
  end

  def create
    @review = current_user.reviews.build(review_params.merge(event: @event, movie: @event.movie))

    # Only allow review creation if event is finished
    unless @event.finished?
      redirect_to event_path(@event), alert: "Vous ne pouvez laisser un avis qu'après la fin de l'événement." and return
    end

    if @review.save
      redirect_to @event, notice: 'Merci pour votre avis!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to @review.event, notice: 'Avis modifié avec succés'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    event = @review.event
    @review.destroy!
    redirect_to event, notice: 'Review deleted.'
  end

  private

  def set_review
    @review = current_user.reviews.find(params[:id])
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
