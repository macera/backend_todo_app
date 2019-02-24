module Mutations
  class AddTodoMutation < GraphQL::Schema::RelayClassicMutation
    # TODO: define return fields
    # field :post, Types::PostType, null: false
    field :todo,    Types::TodoType, null: false
    field :errors,   [String],       null: false

    # TODO: define arguments
    argument :content, String, required: true

    # TODO: define resolve method
    # def resolve(name:)
    #   { post: ... }
    # end
    def resolve(content: nil)
      todo = Todo.new
      todo.content = content if content

      if todo.save
        { todo: todo, errors: [] }
      else
        {
          todo: todo,
          errors: todo.errors.full_messages
        }
      end
    end
  end
end
