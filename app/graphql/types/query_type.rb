module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.
    field :todo, TodoType, null: true do
      description "idをもとにTodoを取得します"
      argument :id, ID, required: true
    end

    def todo(id:)
      Todo.find(id)
    end

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
  end
end
