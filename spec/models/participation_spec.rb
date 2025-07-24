require 'rails_helper'

RSpec.describe Participation, type: :model do
  describe 'validations' do
    subject { build(:participation) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:event_id).with_message('User already registered for this event') }
    it { should validate_numericality_of(:seats).only_integer.is_greater_than(0) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:event) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2).with_default(:pending) }
  end

  describe 'scopes' do
    let(:upcoming_event) { create(:event, event_date: 1.week.from_now) }
    let(:past_event) { create(:event, event_date: 1.week.ago) }
    let!(:upcoming_participation) { create(:participation, event: upcoming_event) }
    let!(:past_participation) { create(:participation, event: past_event) }

    describe '.upcoming' do
      it 'returns participations for upcoming events' do
        expect(Participation.upcoming).to contain_exactly(upcoming_participation)
      end

      it 'orders by event date ascending' do
        upcoming_event2 = create(:event, event_date: 2.weeks.from_now)
        upcoming_participation2 = create(:participation, event: upcoming_event2)
        
        expect(Participation.upcoming).to eq([upcoming_participation, upcoming_participation2])
      end
    end

    describe '.past' do
      it 'returns participations for past events' do
        expect(Participation.past).to contain_exactly(past_participation)
      end

      it 'orders by event date descending' do
        past_event2 = create(:event, event_date: 2.weeks.ago)
        past_participation2 = create(:participation, event: past_event2)
        
        expect(Participation.past).to eq([past_participation, past_participation2])
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:participation)).to be_valid
    end

    it 'has a valid confirmed factory' do
      expect(build(:participation, :confirmed)).to be_valid
    end

    it 'has a valid pending factory' do
      expect(build(:participation, :pending)).to be_valid
    end

    it 'has a valid cancelled factory' do
      expect(build(:participation, :cancelled)).to be_valid
    end
  end

  describe 'uniqueness validation' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }
    let!(:existing_participation) { create(:participation, user: user, event: event) }

    it 'prevents duplicate registrations for the same event' do
      duplicate_participation = build(:participation, user: user, event: event)
      expect(duplicate_participation).not_to be_valid
      expect(duplicate_participation.errors[:user_id]).to include('User already registered for this event')
    end

    it 'allows same user to register for different events' do
      other_event = create(:event)
      other_participation = build(:participation, user: user, event: other_event)
      expect(other_participation).to be_valid
    end
  end
end