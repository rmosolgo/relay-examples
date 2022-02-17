require "bundler/inline"

gemfile do
  gem "graphql", "2.0"
  gem "sinatra"
  gem "sinatra-cross_origin"
  gem "thin"
end

ME = {
  id: SecureRandom.hex,
  user_id: "me",
  todos: [
    { id: SecureRandom.hex, text: "Taste JavaScript", complete: true },
    { id: SecureRandom.hex, text: "Buy a Unicorn", complete: false },
  ]
}

class TodoSchema < GraphQL::Schema
  class CustomId < GraphQL::Types::ID
    graphql_name "CustomId"
  end

  module Node
    include GraphQL::Schema::Interface
    field :id, CustomId, null: false
  end

  class Todo < GraphQL::Schema::Object
    implements Node
    field :text, String, null: false
    field :complete, Boolean, null: false
  end

  class User < GraphQL::Schema::Object
    implements Node
    field :user_id, String, null: false
    field :todos, Todo.connection_type do
      argument :status, String, default_value: "any"
    end
    field :total_count, Int, null: false

    def total_count
      object[:todos].size
    end

    field :completed_count, Int, null: false

    def completed_count
      object[:todos].select { |t| t[:complete] }.size
    end
  end

  class Query < GraphQL::Schema::Object
    field :node, Node do
      argument :id, CustomId
    end

    def node(id:)
      # Not actually used
    end

    field :user, User do
      argument :id, String, required: false
    end

    def user(id:)
      ME
    end
  end

  class AddTodo < GraphQL::Schema::RelayClassicMutation
    argument :text, String
    argument :user_id, CustomId
    argument :client_mutation_id, String, required: false

    field :todo_edge, Todo.edge_type, null: false
    field :user, User, null: false
    field :client_mutation_id, String

    def resolve(text:, user_id:, client_mutation_id: nil)
      user = ME
      new_todo = {
        id: SecureRandom.hex,
        text: text,
        complete: false
      }
      user[:todos] << new_todo

      range_add = GraphQL::Relay::RangeAdd.new(
        parent: user,
        collection: user[:todos],
        item: new_todo,
        context: context,
      )

      {
        user: user,
        todo_edge: range_add.edge,
        client_mutation_id: client_mutation_id
      }
    end
  end

  class ChangeTodoStatus < GraphQL::Schema::RelayClassicMutation
    argument :complete, Boolean
    argument :id, CustomId
    argument :user_id, CustomId
    argument :client_mutation_id, String, required: false

    field :todo, Todo, null: false
    field :user, User, null: false
    field :client_mutation_id, String

    def resolve(user_id:, id:, complete:, client_mutation_id: nil)
      user = ME
      todo = user[:todos].find { |t| t[:id] == id }
      todo[:complete] = complete
      {
        user: user,
        todo: todo,
        client_mutation_id: client_mutation_id
      }
    end
  end

  class MarkAllTodos < GraphQL::Schema::RelayClassicMutation
    argument :complete, Boolean
    argument :user_id, CustomId
    argument :client_mutation_id, String, required: false

    field :changed_todos, [Todo], null: false
    field :user, User, null: false
    field :client_mutation_id, String

    def resolve(user_id:, complete:, client_mutation_id: nil)
      user = ME
      changed_todos = user[:todos].select { |t| t[:complete] != complete }
      changed_todos.each { |t| t[:complete] = complete }
      {
        user: user,
        changed_todos: changed_todos,
        client_mutation_id: client_mutation_id
      }
    end
  end

  class RemoveCompletedTodos < GraphQL::Schema::RelayClassicMutation
    argument :user_id, CustomId
    argument :client_mutation_id, String, required: false

    field :deleted_todo_ids, [String], null: true
    field :user, User, null: false
    field :client_mutation_id, String

    def resolve(user_id:, client_mutation_id: nil)
      user = ME
      completed_todos = user[:todos].select { |t| t[:complete] }
      user[:todos] -= completed_todos
      {
        deleted_todo_ids: completed_todos.map { |t| t[:id] },
        user: user,
        client_mutation_id: client_mutation_id
      }
    end
  end

  class RemoveTodo < GraphQL::Schema::RelayClassicMutation
    argument :id, CustomId
    argument :user_id, CustomId
    argument :client_mutation_id, String, required: false

    field :deleted_todo_id, CustomId, null: false
    field :user, User, null: false
    field :client_mutation_id, String

    def resolve(user_id:, id:, client_mutation_id: nil)
      user = ME
      todo = user[:todos].find { |t| t[:id] == id }
      user[:todos] -= [todo]

      {
        user: user,
        deleted_todo_id: todo[:id],
        client_mutation_id: client_mutation_id
      }
    end
  end

  class RenameTodo < GraphQL::Schema::RelayClassicMutation
    argument :text, String
    argument :id, CustomId
    argument :client_mutation_id, String, required: false

    field :todo, Todo, null: false
    field :client_mutation_id, String

    def resolve(id:, text:, client_mutation_id: nil)
      user = ME
      todo = user[:todos].find { |t| t[:id] == id }
      todo[:text] = text
      {
        todo: todo,
        client_mutation_id: client_mutation_id
      }
    end
  end

  class Mutation < GraphQL::Schema::Object
    field :add_todo, mutation: AddTodo
    field :change_todo_status, mutation: ChangeTodoStatus
    field :mark_all_todos, mutation: MarkAllTodos
    field :remove_completed_todos, mutation: RemoveCompletedTodos
    field :remove_todo, mutation: RemoveTodo
    field :rename_todo, mutation: RenameTodo
  end

  query(Query)
  mutation(Mutation)
end


File.write("data/schema.graphql", TodoSchema.to_definition)

require "logger"

class App < Sinatra::Base
  set :port, 3004
  register Sinatra::CrossOrigin

  configure do
    use Rack::CommonLogger, ::Logger.new(STDOUT)
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  options "*" do
    response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, Transfer-Encoding"
    response.headers["Access-Control-Allow-Origin"] = "*"
    200
  end

  post "/graphql" do
    cross_origin
    body = JSON.parse(request.body.read)
    query_str = body["query"]
    variables = body["variables"]
    result = TodoSchema.execute(query_str, variables: variables)
    content_type :json
    result.to_json
  end
end

App.run!
