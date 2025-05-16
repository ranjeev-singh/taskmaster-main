require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:task) { create(:task, :pending, assigned_to: user, assigned_by: admin) }

  describe '#validations' do
    it 'is valid with valid attributes' do
      expect(task).to be_valid
    end

    it 'is not valid without a title' do
      task.title = nil
      expect(task).not_to be_valid
      expect(task.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without a description' do
      task.description = nil
      expect(task).not_to be_valid
      expect(task.errors[:description]).to include("can't be blank")
    end

    it 'is not valid without a due_date' do
      task.due_date = nil
      expect(task).not_to be_valid
      expect(task.errors[:due_date]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'belongs to assigned_to' do
      expect(task.assigned_to).to eq(user)
    end

    it 'belongs to assigned_by' do
      expect(task.assigned_by).to eq(admin)
    end
  end

   describe 'enums' do
    it 'defines the correct statuses' do
      expect(Task.statuses).to eq({ 'pending' => 0, 'in_progress' => 1, 'completed' => 2 })
    end

    it 'has a default status of pending' do
      expect(task.status).to eq('pending')
    end
  end
  
end