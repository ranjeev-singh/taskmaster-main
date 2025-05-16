require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }

  describe '#validations' do
    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'is not valid without an email' do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
  end

  describe '#associations' do
    it 'has many tasks' do
      task = create(:task, assigned_to: user, assigned_by: user)
      expect(user.tasks).to include(task)
    end
  end

  describe '#enums' do
    it 'defines the correct roles' do
      expect(User.roles).to eq({ 'user' => 0, 'manager' => 1, 'admin' => 2 })
    end

    it 'has a default role of user' do
      expect(user.role).to eq('user')
    end

    it 'defines role methods for role user' do
      expect(user.user?).to be true
      expect(user.manager?).to be false
      expect(user.admin?).to be false
    end

    it 'defines role methods for role admin' do
      expect(admin.admin?).to be true
      expect(admin.manager?).to be false
      expect(admin.user?).to be false
    end

    it 'defines role meethods for role manager' do
      expect(manager.user?).to be false
      expect(manager.manager?).to be true
      expect(manager.admin?).to be false
    end
  end

  describe '#jwt_payload' do
    it 'returns the JWT payload' do
      payload = user.jwt_payload
      expect(payload).to have_key('jti')
      expect(payload).to have_key('sub')
      expect(payload['sub']).to eq(user.id)
    end
  end
end
