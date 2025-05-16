require 'rails_helper'

RSpec.describe TaskPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:regular_user) { create(:user) }
  let(:assigned_task) { create(:task, assigned_to: regular_user, assigned_by: admin) }
  let(:other_user_task) { create(:task, assigned_to: create(:user), assigned_by: manager) }

  subject { described_class }

  def permission_for(user, record = nil)
    subject.new(user, record || assigned_task)
  end

  describe '#index?' do
    context 'when user is present' do
      it 'allows access for admin' do
        expect(permission_for(admin).index?).to be true
      end

      it 'allows access for manager' do
        expect(permission_for(manager).index?).to be true
      end

      it 'allows access for regular user' do
        expect(permission_for(regular_user).index?).to be true
      end
    end

    context 'when user is nil (unauthenticated)' do
      it 'denies access' do
        expect(permission_for(nil).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'when user is admin' do
      it 'allows access to any task' do
        expect(permission_for(admin, assigned_task).show?).to be true
        # expect(permission_for(admin, unassigned_task).show?).to be true
      end
    end

    context 'when user is regular user' do
      it 'allows access to regular user own assigned task' do
        expect(permission_for(regular_user, assigned_task).show?).to be true
      end

      it 'denies access to another user’s task' do
        expect(permission_for(regular_user, other_user_task).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'when user is admin' do
      it 'allows creation' do
        expect(permission_for(admin).create?).to be true
      end
    end

    context 'when user is manager' do
      it 'allows creation' do
        expect(permission_for(manager).create?).to be true
      end
    end

    context 'when user is regular user' do
      it 'denies creation' do
        expect(permission_for(regular_user).create?).to be false
      end
    end
  end

  describe '#update?' do
    context 'when user is admin' do
      it 'allows update of any task' do
        expect(permission_for(admin, assigned_task).update?).to be true
      end
    end

    context 'when user is regular user' do
      it 'allows update of their own assigned task' do
        expect(permission_for(regular_user, assigned_task).update?).to be true
      end

      it 'denies update of another user’s task' do
        expect(permission_for(regular_user, other_user_task).update?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'when user is admin' do
      it 'allows destruction' do
        expect(permission_for(admin, assigned_task).destroy?).to be true
      end
    end

    context 'when user is manager' do
      it 'denies destruction' do
        expect(permission_for(manager, assigned_task).destroy?).to be false
      end
    end

    context 'when user is regular user' do
      it 'denies destruction' do
        expect(permission_for(regular_user, assigned_task).destroy?).to be false
      end
    end
  end

  describe TaskPolicy::Scope do
    let!(:tasks) do
      [
        create(:task, assigned_to: regular_user, assigned_by: admin),
        create(:task, assigned_to: regular_user, assigned_by: manager)
      ]
    end

    subject { described_class.new(user, Task.all) }

    context 'when user is admin' do
      let(:user) { admin }

      it 'returns all tasks' do
        expect(subject.resolve).to match_array(tasks)
      end
    end

    context 'when user is manager' do
      let(:user) { manager }

      it 'returns all tasks' do
        expect(subject.resolve).to match_array(tasks)
      end
    end

    context 'when user is nil (unauthenticated)' do
      let(:user) { nil }

      it 'returns no tasks' do
        expect(subject.resolve).to be_empty
      end
    end
  end
end