-- Test runner for quickfix-review
-- Usage: nvim --headless -c 'lua dofile("test/run.lua")' -c 'qa!'

print('Running quickfix-review tests...')
print('Working directory:', vim.fn.getcwd())
print('Plugin version check:', vim.fn.readfile('lua/quickfix-review/config.lua', '', 1)[1])
print(string.rep('=', 50))

-- Track totals across all test files
local total_passed = 0
local total_failed = 0

-- Run utility tests first (no plugin dependency)
local utils_assert = dofile('test/test_utils.lua')
total_passed = total_passed + utils_assert.passed
total_failed = total_failed + utils_assert.failed
utils_assert.reset()

-- Run comment tests
local comments_assert = dofile('test/test_comments.lua')
total_passed = total_passed + comments_assert.passed
total_failed = total_failed + comments_assert.failed
comments_assert.reset()

-- Run sign tests
local signs_assert = dofile('test/test_signs.lua')
total_passed = total_passed + signs_assert.passed
total_failed = total_failed + signs_assert.failed
signs_assert.reset()

-- Run persistence tests
local persistence_assert = dofile('test/test_persistence.lua')
total_passed = total_passed + persistence_assert.passed
total_failed = total_failed + persistence_assert.failed

-- Final summary
print('')
print(string.rep('=', 50))
print('FINAL RESULTS')
print(string.rep('=', 50))

if total_failed == 0 then
  print(string.format('All tests passed: %d/%d', total_passed, total_passed + total_failed))
else
  print(string.format('Tests: %d passed, %d FAILED', total_passed, total_failed))
end

-- Exit with appropriate code for CI
if total_failed > 0 then
  vim.cmd('cquit 1')
end
