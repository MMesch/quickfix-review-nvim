# Quickfix Review Testing

This directory contains tests for the quickfix-review plugin.

## Running Tests

### Run All Tests

```bash
nvim --headless -c 'lua dofile("test/run.lua")' -c 'qa!'
```

Check the exit code to determine pass/fail:
```bash
nvim --headless -c 'lua dofile("test/run.lua")' -c 'qa!' && echo "PASSED" || echo "FAILED"
```

**Important**: The tests add the current directory to the runtime path to ensure the local plugin version is loaded. This is necessary to test changes to the plugin code.

### Verifying Plugin Version

The test output includes a "Plugin version check" line that shows the first line of the config file. This confirms that the current directory's plugin is being tested, not an installed version.

### Run Individual Test Files

```bash
# Utility function tests
nvim --headless -c 'lua dofile("test/test_utils.lua")' -c 'qa!'

# Comment add/delete tests
nvim --headless -c 'lua dofile("test/test_comments.lua")' -c 'qa!'

# Sign placement tests
nvim --headless -c 'lua dofile("test/test_signs.lua")' -c 'qa!'

# Save/load persistence tests
nvim --headless -c 'lua dofile("test/test_persistence.lua")' -c 'qa!'
```

### Interactive Debugging

For debugging failing tests:

```bash
nvim -c 'lua dofile("test/test_comments.lua")'
```

## Test Files

| File | Description |
|------|-------------|
| `assertions.lua` | Minimal assertion library with pass/fail tracking |
| `init.lua` | Test initialization and helper functions |
| `run.lua` | Test runner that executes all test files |
| `test_utils.lua` | Tests for utility functions (parse_comment_type, files_match, etc.) |
| `test_comments.lua` | Tests for adding, deleting, and managing comments |
| `test_signs.lua` | Tests for sign placement on single and multiline comments |
| `test_persistence.lua` | Tests for save/load functionality |

## Writing New Tests

### Basic Structure

```lua
local test_helper = dofile('test/init.lua')
local assert = dofile('test/assertions.lua')

print('\nRunning my tests...')

local qf = test_helper.setup_test_environment()
local test_file = test_helper.create_test_file([[
line 1
line 2
line 3
]])

assert.run_test('my test name', function()
  -- Test code here
  assert.equals(actual, expected, 'description')
end)

test_helper.cleanup_test_environment()
return assert
```

### Available Assertions

```lua
assert.equals(actual, expected, msg)      -- Equality check
assert.not_equals(actual, expected, msg)  -- Inequality check
assert.contains(tbl, value, msg)          -- Table contains value
assert.matches(str, pattern, msg)         -- String pattern match
assert.truthy(value, msg)                 -- Value is truthy
assert.falsy(value, msg)                  -- Value is falsy
assert.length(tbl, expected, msg)         -- Table length check
```

### Adding to Test Runner

Add your test file to `run.lua`:

```lua
local my_assert = dofile('test/test_myfeature.lua')
total_passed = total_passed + my_assert.passed
total_failed = total_failed + my_assert.failed
my_assert.reset()
```

## Test Environment

The test environment:
- Mocks `vim.fn.input()` to return "Test comment"
- Disables all keymaps to avoid conflicts
- Uses simple ASCII signs (!, ?, N, +) instead of emoji
- Clears quickfix list and signs between test files
- Creates temporary test files that are cleaned up automatically

## CI Integration

The test runner exits with code 1 if any tests fail:

```bash
nvim --headless -c 'lua dofile("test/run.lua")' -c 'qa!'
exit_code=$?
if [ $exit_code -ne 0 ]; then
  echo "Tests failed!"
  exit 1
fi
```
