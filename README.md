# Todoアプリのバックエンド

以下はその作成手順を書いています。

## first commit

`$ ruby -v`

ruby 2.6.1p33


`$ bundler -v`

Bundler version 2.0.1

`$ mkdir backend_todo_app`

`$ cd backend_todo_app`

`$ rails new . --api --skip-bundle`


Gemfile
```
gem 'graphql'
gem 'rack-cors'
group :development do
  gem 'graphiql-rails' # graphqlのテスト画面
  gem 'sass-rails', '~> 5.0'    # graphiql-railsで必要(--apiオプションでは自動追加されない)
  gem 'uglifier', '>= 1.3.0'    # 同上
  gem 'coffee-rails', '~> 4.2'  # 同上
end
```

このままだとDB作成時に `Gem::LoadError: can't activate sqlite3 (~> 1.3.6)` のエラーが発生するので修正する。

```
gem 'sqlite3', '~> 1.3.6'
```

`$ bundle install --path vendor/bundle`

.gitignore
```
vendor/bundle
```

## set DB and Table

`$ bundle exec rails db:create`

`$ bundle exec rails g model todo content:string`

## set cors

config/initializers/cors.rb
コメントを外す
```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /localhost\:\d+/ #<=修正

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

## set graphql
`$ bundle exec rails generate graphql:install`

config/routes.rb
```
if Rails.env.development?
  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
end
```

`$ bundle exec rails s -p 4000`

フロントエンドはポート3000で実行するため4000で実行する

`GET /graphiql` にアクセスすると、graphqlのテストクライアントにアクセスできるようになる。

## set original type (TodoType)
`$ bundle exec rails g graphql:object todo id:ID! content:String!`

## add new field to QueryType (todo)

app/graphql/types/query_type.rb
```
field :todo, TodoType, null: true do
  description "idをもとにTodoを取得します"
  argument :id, ID, required: true
end

def todo(id:)
  Todo.find(id)
end
```
`$ bundle exec rails c`

`irb> Todo.create(content: 'todo1')`

`irb> Todo.create(content: 'todo2')`

`GET /graphiql` にアクセスする

request
```
{
  todo(id: 1) {
      id
      content
    }
}
```

response
```
{
  "data": {
    "todo": {
      "id": "1",
      "content": "todo1"
    }
  }
}
```

## add new field to QueryType (todos)

app/graphql/types/query_type.rb
```
field :todos, Types::TodoType.connection_type, null: false do
  description 'Todoリスト一覧を取得します'
end

def todos
  Todo.all.order(created_at: :desc)
end
```

`GET /graphiql` にアクセスする

request
```
query todos {
  todos {
    pageInfo {
      hasPreviousPage
      hasNextPage
      endCursor
      startCursor
    }
    edges {
      cursor
      node {
        id
        content
      }
    }
  }
}

```

response
```
{
  "data": {
    "todos": {
      "pageInfo": {
        "hasPreviousPage": false,
        "hasNextPage": false,
        "endCursor": "Mg",
        "startCursor": "MQ"
      },
      "edges": [
        {
          "cursor": "MQ",
          "node": {
            "id": "2",
            "content": "todo2"
          }
        },
        {
          "cursor": "Mg",
          "node": {
            "id": "1",
            "content": "todo1"
          }
        }
      ]
    }
  }
}
```

## add new field to MutationType (addTodoMutation)

`$ bundle exec rails g graphql:mutation AddTodoMutation`

app/graphql/mutations/add_todo_mutation.rb
```
field :todo,    Types::TodoType, null: false
field :errors,   [String],       null: false

argument :content, String, required: true

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
```

app/models/todo.rb
```
validates :content, presence: true
```

`GET /graphiql` にアクセスする

request
```
mutation addTodoMutation($content: String = "Todo3") {
  addTodoMutation(input: {content: $content}) {
    todo {
      id
      content
    }
    errors
  }
}
```

response
```
{
  "data": {
    "addTodoMutation": {
      "todo": {
        "id": "3",
        "content": "Todo3"
      },
      "errors": []
    }
  }
}
```
todoがnullの場合
error response
```
{
  "data": {
    "addTodoMutation": null
  },
  "errors": [
    {
      "message": "Cannot return null for non-nullable field Todo.id"
    }
  ]
}
```
