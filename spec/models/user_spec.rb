require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
  end

  describe 'associations' do
    it { should have_many(:participations).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:events).through(:participations) }
    it { should have_many(:movies) }
    it { should have_many(:created_events).through(:movies).source(:events) }
    it { should have_one_attached(:avatar) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(user: 0, creator: 1, admin: 2).with_default(:user) }
  end

  describe 'scopes' do
    let!(:admin_user) { create(:user, :admin) }
    let!(:creator_user) { create(:user, :creator) }
    let!(:regular_user) { create(:user) }

    describe '.admin_users' do
      it 'returns only admin users' do
        expect(User.admin_users).to contain_exactly(admin_user)
      end
    end

    describe '.regular_users' do
      it 'returns only regular users' do
        expect(User.regular_users).to contain_exactly(regular_user)
      end
    end

    describe '.creators' do
      it 'returns only creator users' do
        expect(User.creators).to contain_exactly(creator_user)
      end
    end
  end

  describe '#full_name' do
    let(:user) { build(:user, first_name: 'Jean', last_name: 'Dupont') }

    it 'returns the concatenation of first_name and last_name' do
      expect(user.full_name).to eq('Jean Dupont')
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'sends welcome email' do
        expect {
          create(:user)
        }.to have_enqueued_mail(UserMailer, :welcome_email)
      end
    end

    describe 'after_update' do
      let(:user) { create(:user, :creator) }
      let!(:movie) { create(:movie, user: user) }

      it 'syncs director name to movies when name changes' do
        user.update(first_name: 'NewName')
        expect(movie.reload.director).to eq(user.full_name)
      end
    end
  end

  describe 'name change validation' do
    let(:user) { create(:user, :creator) }
    let!(:movie) { create(:movie, user: user) }

    it 'prevents name change after publishing movies' do
      user.first_name = 'NewName'
      expect(user).not_to be_valid
      expect(user.errors[:base]).to include('Impossible de modifier votre nom après publication d\'un film approuvé.')
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'has a valid admin factory' do
      expect(build(:user, :admin)).to be_valid
    end

    it 'has a valid creator factory' do
      expect(build(:user, :creator)).to be_valid
    end
  end
end