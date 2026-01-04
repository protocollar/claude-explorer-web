---
paths: test/**/*.rb
---

# Testing Conventions

## Test Types

| Type | Location | Base Class |
|------|----------|------------|
| Model | `test/models/` | `ActiveSupport::TestCase` |
| Controller | `test/controllers/` | `ActionDispatch::IntegrationTest` |
| System | `test/system/` | `ApplicationSystemTestCase` |

## Running Tests

```bash
bin/rails test                          # All tests
bin/rails test test/models/card_test.rb:42  # Single test at line
bin/rails test:system                   # System tests
bin/ci                                  # Full CI suite
```

## Test Structure

```ruby
class CardTest < ActiveSupport::TestCase
  setup do
    @card = cards(:logo)  # Access fixture
  end

  test "closes with timestamp" do
    @card.close!
    assert @card.closed?
    assert_not_nil @card.closed_at
  end
end
```

## Key Patterns

- **Minitest only** - No RSpec
- **Fixtures over factories** - `users(:david)`, `cards(:logo)`
- **One assertion per test when possible**
- **Descriptive test names** - Read like documentation
- **Setup for shared state** - `setup` block over instance variables

## Common Assertions

```ruby
assert_response :success
assert_redirected_to path
assert_difference -> { Model.count }, 1 do
  # action
end
assert_select "css-selector", text: "expected"
```

## Controller Tests

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "create" do
    assert_difference -> { Card.count }, 1 do
      post cards_path, params: { card: { title: "New" } }
    end
  end
end
```

## Turbo Stream Testing

```ruby
test "returns turbo stream" do
  post items_path(format: :turbo_stream), params: { item: { name: "Test" } }
  assert_match /<turbo-stream/, response.body
end
```

## Test Helpers

Create in `test/test_helpers/` and include in `test_helper.rb`
