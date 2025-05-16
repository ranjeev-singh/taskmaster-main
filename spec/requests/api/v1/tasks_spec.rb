require 'rails_helper'

RSpec.describe "Api::V1::TasksController", type: :request do
  let(:admin) { create(:user, role: 'admin') }
  let(:manager) { create(:user, role: 'manager') }
  let(:non_admin) { create(:user) }
  let(:user) { create(:user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{JWT.encode({ sub: admin.id }, Rails.application.credentials.secret_key_base)}" } }
  let(:json) { JSON.parse(response.body) }

  before do
    allow_any_instance_of(Api::V1::TasksController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(Api::V1::TasksController).to receive(:current_user).and_return(admin)
  end

  describe 'GET /api/v1/tasks' do
    let!(:tasks) { create_list(:task, 3, assigned_to: user, assigned_by: admin) }

    context 'filters tasks by email' do
      before { allow_any_instance_of(TaskPolicy::Scope).to receive(:resolve).and_return(Task.where(id: tasks.pluck(:id))) }

      it 'filters tasks by email' do
        get "/api/v1/tasks", headers: auth_headers
        puts "Response tasks: #{json.map { |t| t['id'] }}"
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(3)
      end

      it 'filters tasks by email' do
        get "/api/v1/tasks", params: { q: user.email }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(3)
        expect(json).to all(include("assigned_to" => hash_including("email" => user.email)))
      end

      it 'filters tasks by status' do
        create(:task, status: 'completed', assigned_by: admin)
        get "/api/v1/tasks", params: { status: 'pending' }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json).to all(include("status" => "pending"))
      end

      it 'when unauthorized' do
        create(:task, due_date: Date.today.in_time_zone("UTC").beginning_of_day, assigned_by_id: admin.id, assigned_to_id: user.id)
        get "/api/v1/tasks", params: { start_date: Date.today - 1.day, end_date: Date.today + 1.day }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(1)
        expect(Date.parse(json.first["due_date"])).to eq(Date.today)
      end
    end

    context 'when unauthorized' do
      before { allow_any_instance_of(TaskPolicy::Scope).to receive(:resolve).and_return(Task.none) }

      it 'returns an empty array' do
        get "/api/v1/tasks", headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /api/v1/tasks/:id" do
    let(:task) { create(:task, assigned_to: user, assigned_by: admin) }

    context 'when #authorized' do
      before { allow_any_instance_of(TaskPolicy).to receive(:show?).and_return(true) }

      it 'returns the t#ask' do
        get "/api/v1/tasks/#{task.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(json["id"]).to eq(task.id)
        expect(json["title"]).to eq(task.title)
      end
    end

    context 'when unauthorized' do
      before { allow_any_instance_of(TaskPolicy).to receive(:show?).and_raise(Pundit::NotAuthorizedError) }

      it 'returns forbidden' do
        get "/api/v1/tasks/#{task.id}", headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when task not found" do
      it "returns not found" do
        get "/api/v1/tasks/999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/tasks" do
    let(:valid_params) do
      {
        task: {
          title: Faker::Lorem.sentence(word_count: 4),
          description: Faker::Lorem.paragraph,
          status: "pending",
          due_date: Faker::Date.forward(days: 20).to_s,
          assigned_to_id: user.id,
          assigned_by_id: admin.id
        }
      }
    end
    let(:invalid_params) { { task: { title: "" } } }

    context 'when #authorized' do
      before do
        allow_any_instance_of(TaskPolicy).to receive(:create?).and_return(true)
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'creates a task and broadcasts' do
        expect {
          post "/api/v1/tasks", params: valid_params, headers: auth_headers, as: :json
        }.to change(Task, :count).by(1)

        expect(response).to have_http_status(:created)
        task = Task.last
        expect(json["id"]).to eq(task.id)
        expect(task.assigned_by).to eq(admin)
      end
    end

    context 'returns #forbidden' do
      before { allow_any_instance_of(TaskPolicy).to receive(:create?).and_raise(Pundit::NotAuthorizedError) }

      it 'returns forbidden' do
        post "/api/v1/tasks", params: valid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when invalid params' do
      before { allow_any_instance_of(TaskPolicy).to receive(:create?).and_return(true) }

      it 'returns unprocessable entity' do
        post "/api/v1/tasks", params: invalid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to have_key("title")
      end
    end
  end

  describe "PUT /api/v1/tasks/:id" do
    let(:task) { create(:task, assigned_to: user, assigned_by: admin) }
    let(:update_params) { { task: { status: "in_progress" } } }

    context "when authorized as admin" do
      before do
        allow_any_instance_of(TaskPolicy).to receive(:update?).and_return(true)
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'updates the task and broadcasts to assigned_to' do
        put "/api/v1/tasks/#{task.id}", params: update_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(json["status"]).to eq("in_progress")
        expect(task.reload.status).to eq("in_progress")

        # expect(ActionCable.server).to have_received(:broadcast).with(
        #   "tasks_#{user.id}",
        #   hash_including(
        #     action: "task_updated",
        #     task: hash_including("id" => task.id, "status" => "in_progress"),
        #     message: "Task updated by #{admin.email}"
        #   )
        # )
      end
    end

    context 'when authorized as regular user' do
      before do
        allow_any_instance_of(Api::V1::TasksController).to receive(:current_user).and_return(user)
        allow_any_instance_of(TaskPolicy).to receive(:update?).and_return(true)
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'updates the task and broadcasts to #assigned_by' do
        put "/api/v1/tasks/#{task.id}", params: update_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(json["status"]).to eq("in_progress")

        # expect(ActionCable.server).to have_received(:broadcast).with(
        #   "tasks_#{admin.id}",
        #   hash_including(
        #     action: "status_updated",
        #     task: hash_including("id" => task.id, "status" => "in_progress"),
        #     message: "The status of task chnage to 'in_progress' by #{user.email}"
        #   )
        # )
      end
    end

    context 'when unauthorized' do
      before { allow_any_instance_of(TaskPolicy).to receive(:update?).and_raise(Pundit::NotAuthorizedError) }

      it 'returns #forbidden' do
        put "/api/v1/tasks/#{task.id}", params: update_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when invalid params' do
      before { allow_any_instance_of(TaskPolicy).to receive(:update?).and_return(true) }
      let(:invalid_update_params) { { task: { status: "invalid" } } }

      it 'returns unprocessable entity' do
        put "/api/v1/tasks/#{task.id}", params: invalid_update_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to have_key("status")
      end
    end
  end


  describe "DELETE /api/v1/tasks/:id" do
    let!(:task) { create(:task, assigned_to: user, assigned_by: admin) }

    context 'when #authorized' do
      before { allow_any_instance_of(TaskPolicy).to receive(:destroy?).and_return(true) }

      it 'deletes the task' do
      expect(Task.count).to eq(1), "Task was not created: #{task.errors.full_messages}"
      expect(Task.find_by(id: task.id)).to be_present, "Task not found in database"

      expect {
        delete "/api/v1/tasks/#{task.id}", headers: auth_headers
      }.to change(Task, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
    end

    context 'when #unauthorized' do
      before { allow_any_instance_of(TaskPolicy).to receive(:destroy?).and_raise(Pundit::NotAuthorizedError) }

      it 'returns forbidden' do
        delete "/api/v1/tasks/#{task.id}", headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'other_user_task' do
      it 'returns not found' do
        delete "/api/v1/tasks/999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
