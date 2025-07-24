require 'rails_helper'

RSpec.describe Movie, type: :model do
  describe 'validations' do
    subject { build(:movie) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:synopsis) }
    it { should validate_presence_of(:director) }
    it { should validate_presence_of(:duration) }
    it { should validate_presence_of(:genre) }
    it { should validate_presence_of(:year) }
    it { should validate_numericality_of(:duration).is_greater_than(0).is_less_than(300) }
    it { should validate_numericality_of(:year).is_greater_than(1900).is_less_than_or_equal_to(Date.current.year) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:validated_by).class_name('User').optional }
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_one_attached(:poster) }
  end

  describe 'enums' do
    it { should define_enum_for(:validation_status).with_values(pending: 0, approved: 1, rejected: 2).with_default(:pending) }
  end

  describe 'scopes' do
    let!(:approved_movie) { create(:movie, :approved) }
    let!(:pending_movie) { create(:movie) }

    describe '.approved' do
      it 'returns only approved movies' do
        expect(Movie.approved).to contain_exactly(approved_movie)
      end
    end

    describe '.by_title' do
      let!(:movie1) { create(:movie, title: 'Inception') }
      let!(:movie2) { create(:movie, title: 'The Matrix') }

      it 'filters movies by title' do
        expect(Movie.by_title('Matrix')).to contain_exactly(movie2)
      end

      it 'is case insensitive' do
        expect(Movie.by_title('matrix')).to contain_exactly(movie2)
      end
    end

    describe '.by_genre' do
      let!(:drama_movie) { create(:movie, genre: 'Drame') }
      let!(:comedy_movie) { create(:movie, genre: 'Comédie') }

      it 'filters movies by genre' do
        expect(Movie.by_genre('Drame')).to contain_exactly(drama_movie)
      end
    end
  end

  describe '.filter_by' do
    let!(:movie1) { create(:movie, :approved, title: 'Test Movie', genre: 'Drame', year: 2023) }
    let!(:movie2) { create(:movie, :approved, title: 'Another Movie', genre: 'Comédie', year: 2022) }

    it 'combines multiple filters' do
      params = { q: 'Test', genre: 'Drame', year: 2023 }
      expect(Movie.filter_by(params)).to contain_exactly(movie1)
    end

    it 'only returns approved movies' do
      pending_movie = create(:movie, title: 'Test Movie')
      params = { q: 'Test' }
      expect(Movie.filter_by(params)).to contain_exactly(movie1)
    end
  end

  describe 'callbacks' do
    describe 'before_update' do
      let(:movie) { create(:movie, :approved) }

      it 'prevents update if movie is approved' do
        expect {
          movie.update(title: 'New Title')
        }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(movie.errors[:base]).to include('Un film approuvé ne peut plus être modifié.')
      end
    end

    describe 'after_update' do
      let(:user) { create(:user) }
      let(:movie) { create(:movie, user: user) }
      let(:admin) { create(:user, :admin) }

      it 'promotes user to creator when movie is approved' do
        movie.update(validation_status: :approved, validated_by: admin)
        expect(user.reload.role).to eq('creator')
      end
    end
  end

  describe 'custom validations' do
    describe '#authorship_must_be_confirmed' do
      it 'validates authorship confirmation on create' do
        movie = build(:movie)
        movie.authorship_confirmed = "0"
        expect(movie).not_to be_valid
        expect(movie.errors[:base]).to include('Tu dois confirmer être l\'auteur ou l\'autrice de cette vidéo pour pouvoir la publier.')
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:movie)).to be_valid
    end

    it 'has a valid approved factory' do
      expect(build(:movie, :approved)).to be_valid
    end

    it 'has a valid rejected factory' do
      expect(build(:movie, :rejected)).to be_valid
    end
  end
end