require 'rails_helper'

RSpec.describe "Api::V1::UsersController", type: :request do

  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:user) { create(:user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{JWT.encode({ sub: admin.id }, Rails.application.credentials.secret_key_base)}" } }
  let(:json) { JSON.parse(response.body) }

  before do
    allow_any_instance_of(Api::V1::UsersController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(Api::V1::UsersController).to receive(:current_user).and_return(admin)
  end
  
 describe "GET /api/v1/users" do
    let!(:users) { [admin, manager, user] } # Pre-create users

    context 'when #authorized' do
      before { allow_any_instance_of(UserPolicy::Scope).to receive(:resolve).and_return(User.where(id: users.pluck(:id))) }

      it 'returns all users' do
        get "/api/v1/users", headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(3)
        expect(json).to all(include("id", "email", "role"))
        expect(json.map { |u| u["email"] }).to match_array(users.map(&:email))
      end

      it 'filters users by #email' do
        get "/api/v1/users", params: { q: user.email }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(1)
        expect(json.first).to include("email" => user.email, "role" => "user")
      end
    end

    context 'when #unauthorized' do
      before { allow_any_instance_of(UserPolicy::Scope).to receive(:resolve).and_return(User.none) }

      it 'when unauthorized' do
        get "/api/v1/users", headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    let(:user) { create(:user, role: 'user') }
    let!(:tasks) { create_list(:task, 2, assigned_to: user, assigned_by: admin) }

    context 'when #authorized' do
      before { allow_any_instance_of(UserPolicy).to receive(:show?).and_return(true) }

      it 'returns the user with tasks' do
        get "/api/v1/users/#{user.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json["id"]).to eq(user.id)
        expect(json["email"]).to eq(user.email)
        expect(json["role"]).to eq(user.role)
        expect(json["tasks"].size).to eq(2)
        expect(json["tasks"]).to all(include("id", "title", "description", "due_date", "assigned_to_id", "status"))
        expect(json["tasks"].map { |t| t["assigned_to_id"] }).to all(eq(user.id))
      end
    end

    context 'when #unauthorized' do
      before { allow_any_instance_of(UserPolicy).to receive(:show?).and_raise(Pundit::NotAuthorizedError) }

      it 'returns forbidden' do
        get "/api/v1/users/#{user.id}", headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user not found' do
      it 'returns not found' do
        get "/api/v1/users/999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/users/:id" do
    let(:user) { create(:user, role: 'user') }

    context 'when #authorized' do
      before { allow_any_instance_of(UserPolicy).to receive(:destroy?).and_return(true) }

      it '#deletes the user' do
        expect(User.count).to eq(1)
        expect(User.find_by(id: user.id)).to be_present

        expect {
          delete "/api/v1/users/#{user.id}", headers: auth_headers
        }.to change(User, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when #unauthorized' do
      before { allow_any_instance_of(UserPolicy).to receive(:destroy?).and_raise(Pundit::NotAuthorizedError) }

      it 'returns #forbidden' do
        delete "/api/v1/users/#{user.id}", headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when #user not found' do
      it 'returns not found' do
        delete "/api/v1/users/999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

end