require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'validations' do
    subject { build(:event) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:venue_name) }
    it { should validate_presence_of(:venue_address) }
    it { should validate_presence_of(:event_date) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:max_capacity) }
    it { should validate_presence_of(:price_cents) }
    it { should validate_numericality_of(:max_capacity).is_greater_than(0).is_less_than_or_equal_to(100) }
    it { should validate_numericality_of(:price_cents).is_greater_than(0) }
  end

  describe 'associations' do
    it { should belong_to(:movie) }
    it { should have_many(:participations).dependent(:destroy) }
    it { should have_many(:users).through(:participations) }
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(upcoming: 0, sold_out: 1, completed: 2, cancelled: 3).with_default(:upcoming) }
  end

  describe 'scopes' do
    let!(:upcoming_event) { create(:event, :upcoming) }
    let!(:completed_event) { create(:event, :completed) }
    let!(:sold_out_event) { create(:event, :sold_out) }

    describe '.upcoming' do
      it 'returns only upcoming events' do
        expect(Event.upcoming).to contain_exactly(upcoming_event)
      end
    end

    describe '.by_title' do
      let(:movie) { create(:movie, title: 'Inception') }
      let!(:event) { create(:event, movie: movie) }

      it 'filters events by movie title' do
        expect(Event.by_title('Inception')).to contain_exactly(event)
      end
    end

    describe '.by_genre' do
      let(:drama_movie) { create(:movie, genre: 'Drame') }
      let!(:drama_event) { create(:event, movie: drama_movie) }

      it 'filters events by movie genre' do
        expect(Event.by_genre('Drame')).to contain_exactly(drama_event)
      end
    end

    describe '.by_venue' do
      let!(:event) { create(:event, venue_name: 'Cinema Rex') }

      it 'filters events by venue name' do
        expect(Event.by_venue('Cinema Rex')).to contain_exactly(event)
      end
    end

    describe '.by_date_filter' do
      let!(:this_week_event) { create(:event, event_date: 2.days.from_now) }
      let!(:next_month_event) { create(:event, event_date: 1.month.from_now) }

      it 'filters events by week' do
        expect(Event.by_date_filter('week')).to include(this_week_event)
        expect(Event.by_date_filter('week')).not_to include(next_month_event)
      end

      it 'filters events by month' do
        expect(Event.by_date_filter('month')).to include(this_week_event)
      end
    end
  end

  describe '.filter_by' do
    let(:movie) { create(:movie, title: 'Test Movie', genre: 'Drame') }
    let!(:event) { create(:event, movie: movie, venue_name: 'Test Cinema') }

    it 'combines multiple filters' do
      params = { q: 'Test', genre: 'Drame', venue: 'Test Cinema' }
      expect(Event.filter_by(params)).to contain_exactly(event)
    end
  end

  describe '#available_spots' do
    let(:event) { create(:event, max_capacity: 50) }
    let!(:participation1) { create(:participation, :confirmed, event: event, seats: 2) }
    let!(:participation2) { create(:participation, :confirmed, event: event, seats: 3) }

    it 'calculates available spots correctly' do
      expect(event.available_spots).to eq(45)
    end
  end

  describe '#sold_out?' do
    let(:event) { create(:event, max_capacity: 5) }

    context 'when event has available spots' do
      it 'returns false' do
        create(:participation, :confirmed, event: event, seats: 2)
        expect(event.sold_out?).to be false
      end
    end

    context 'when event is full' do
      it 'returns true' do
        create(:participation, :confirmed, event: event, seats: 5)
        expect(event.sold_out?).to be true
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      let(:event) { create(:event, max_capacity: 5) }

      it 'updates status to sold_out when full' do
        create(:participation, :confirmed, event: event, seats: 5)
        event.save
        expect(event.sold_out?).to be true
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:event)).to be_valid
    end

    it 'has a valid upcoming factory' do
      expect(build(:event, :upcoming)).to be_valid
    end

    it 'has a valid completed factory' do
      expect(build(:event, :completed)).to be_valid
    end

    it 'has a valid sold_out factory' do
      expect(build(:event, :sold_out)).to be_valid
    end
  end
end