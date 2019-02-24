module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.
    field :todo, TodoType, null: true do
      description "idをもとにTodoを取得します"
      argument :id, ID, required: true
    end

    field :todos, Types::TodoType.connection_type, null: false do
      description 'Todoリスト一覧をすべて取得します'
    end

    def todo(id:)
      Todo.find(id)
    end

    def todos
      Todo.all.order(created_at: :desc)
    end

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
  end
end
