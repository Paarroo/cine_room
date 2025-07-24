require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'validations' do
    subject { build(:review) }

    it { should validate_inclusion_of(:rating).in_range(1..5) }
    it { should validate_uniqueness_of(:user_id).scoped_to([:movie_id, :event_id]).with_message('You already reviewed this event') }
    it { should validate_length_of(:comment).is_at_least(10).is_at_most(1000) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:movie) }
    it { should belong_to(:event) }
  end

  describe 'custom validations' do
    describe '#movie_matches_event' do
      let(:movie1) { create(:movie, :approved) }
      let(:movie2) { create(:movie, :approved) }
      let(:event) { create(:event, movie: movie1) }
      let(:user) { create(:user) }

      it 'validates that movie matches the events movie' do
        review = build(:review, user: user, movie: movie2, event: event)
        expect(review).not_to be_valid
        expect(review.errors[:movie]).to include('must match the event\'s movie')
      end

      it 'is valid when movie matches event movie' do
        review = build(:review, user: user, movie: movie1, event: event)
        expect(review).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:review)).to be_valid
    end

    it 'has a valid excellent factory' do
      review = build(:review, :excellent)
      expect(review).to be_valid
      expect(review.rating).to be_in([4, 5])
    end

    it 'has a valid poor factory' do
      review = build(:review, :poor)
      expect(review).to be_valid
      expect(review.rating).to be_in([1, 2])
    end

    it 'has a valid no_comment factory' do
      review = build(:review, :no_comment)
      expect(review).to be_valid
      expect(review.comment).to be_present
    end
  end

  describe 'uniqueness validation' do
    let(:user) { create(:user) }
    let(:movie) { create(:movie, :approved) }
    let(:event) { create(:event, movie: movie) }
    let!(:existing_review) { create(:review, user: user, movie: movie, event: event) }

    it 'prevents duplicate reviews for the same event by the same user' do
      duplicate_review = build(:review, user: user, movie: movie, event: event)
      expect(duplicate_review).not_to be_valid
      expect(duplicate_review.errors[:user_id]).to include('You already reviewed this event')
    end

    it 'allows same user to review different events' do
      other_event = create(:event, movie: movie)
      other_review = build(:review, user: user, movie: movie, event: other_event)
      expect(other_review).to be_valid
    end

    it 'allows different users to review the same event' do
      other_user = create(:user)
      other_review = build(:review, user: other_user, movie: movie, event: event)
      expect(other_review).to be_valid
    end
  end

  describe 'rating validation' do
    it 'accepts ratings from 1 to 5' do
      (1..5).each do |rating|
        review = build(:review, rating: rating)
        expect(review).to be_valid
      end
    end

    it 'rejects ratings outside 1-5 range' do
      [0, 6, -1, 10].each do |invalid_rating|
        review = build(:review, rating: invalid_rating)
        expect(review).not_to be_valid
      end
    end
  end

  describe 'comment validation' do
    it 'requires minimum 10 characters' do
      review = build(:review, comment: 'Too short')  # 9 characters
      expect(review).not_to be_valid
    end

    it 'accepts comment with exactly 10 characters' do
      review = build(:review, comment: '1234567890')  # 10 characters
      expect(review).to be_valid
    end

    it 'rejects comment longer than 1000 characters' do
      long_comment = 'a' * 1001
      review = build(:review, comment: long_comment)
      expect(review).not_to be_valid
    end
  end
end