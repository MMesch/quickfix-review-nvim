-- Tests for comment add/delete operations
local test_helper = dofile('test/init.lua')
local assert = dofile('test/assertions.lua')

print('\nRunning comment tests...')

local qf = test_helper.setup_test_environment()
local test_file = test_helper.create_test_file([[
line 1
line 2
line 3
line 4
line 5
line 6
line 7
line 8
line 9
line 10
]])

assert.run_test('add single line ISSUE comment', function()
  vim.fn.setqflist({})
  vim.fn.cursor(5, 1)
  qf.add_comment('ISSUE')

  local list = vim.fn.getqflist()
  assert.length(list, 1, 'quickfix list length')
  assert.equals(list[1].lnum, 5, 'comment line number')
  assert.equals(list[1].end_lnum, 5, 'comment end line')
  assert.matches(list[1].text, '%[ISSUE%]', 'comment type in text')
end)

assert.run_test('add multiline ISSUE comment', function()
  vim.fn.setqflist({})
  qf.add_comment('ISSUE', { 3, 7 })

  local list = vim.fn.getqflist()
  assert.length(list, 1, 'quickfix list length')
  assert.equals(list[1].lnum, 3, 'comment start line')
  assert.equals(list[1].end_lnum, 7, 'comment end line')
  assert.matches(list[1].text, '%[ISSUE:L3%-7%]', 'comment type with range')
end)

assert.run_test('add SUGGESTION comment', function()
  vim.fn.setqflist({})
  vim.fn.cursor(2, 1)
  qf.add_comment('SUGGESTION')

  local list = vim.fn.getqflist()
  assert.length(list, 1, 'quickfix list length')
  assert.matches(list[1].text, '%[SUGGESTION%]', 'comment type')
end)

assert.run_test('add NOTE comment', function()
  vim.fn.setqflist({})
  vim.fn.cursor(4, 1)
  qf.add_comment('NOTE')

  local list = vim.fn.getqflist()
  assert.length(list, 1, 'quickfix list length')
  assert.matches(list[1].text, '%[NOTE%]', 'comment type')
end)

assert.run_test('add PRAISE comment', function()
  vim.fn.setqflist({})
  vim.fn.cursor(6, 1)
  qf.add_comment('PRAISE')

  local list = vim.fn.getqflist()
  assert.length(list, 1, 'quickfix list length')
  assert.matches(list[1].text, '%[PRAISE%]', 'comment type')
end)

assert.run_test('add QUESTION comment', function()
  vim.fn.setqflist({})
  vim.fn.cursor(7, 1)
  qf.add_comment('QUESTION')

  local list = vim.fn.getqflist()
  assert.length(list, 1, 'quickfix list length')
  assert.matches(list[1].text, '%[QUESTION%]', 'comment type')
end)

assert.run_test('delete single line comment', function()
  vim.fn.setqflist({})
  vim.fn.cursor(5, 1)
  qf.add_comment('ISSUE')
  assert.length(vim.fn.getqflist(), 1, 'comment added')

  qf.delete_comment({ 5, 5 })
  assert.length(vim.fn.getqflist(), 0, 'comment deleted')
end)

assert.run_test('delete multiline comment', function()
  vim.fn.setqflist({})
  qf.add_comment('ISSUE', { 2, 6 })
  assert.length(vim.fn.getqflist(), 1, 'multiline comment added')

  qf.delete_comment({ 3, 4 }) -- Delete by overlapping range
  assert.length(vim.fn.getqflist(), 0, 'multiline comment deleted')
end)

assert.run_test('delete does not affect other comments', function()
  vim.fn.setqflist({})
  vim.fn.cursor(2, 1)
  qf.add_comment('ISSUE')
  vim.fn.cursor(8, 1)
  qf.add_comment('NOTE')
  assert.length(vim.fn.getqflist(), 2, 'two comments added')

  qf.delete_comment({ 2, 2 })
  local list = vim.fn.getqflist()
  assert.length(list, 1, 'one comment remains')
  assert.matches(list[1].text, '%[NOTE%]', 'correct comment remains')
end)

assert.run_test('multiple comments on same line', function()
  vim.fn.setqflist({})
  vim.fn.cursor(5, 1)
  qf.add_comment('ISSUE')
  vim.fn.cursor(5, 1)
  qf.add_comment('NOTE')

  local list = vim.fn.getqflist()
  assert.length(list, 2, 'two comments on same line')
end)

assert.run_test('clear_review removes all comments', function()
  vim.fn.setqflist({})
  vim.fn.cursor(1, 1)
  qf.add_comment('ISSUE')
  vim.fn.cursor(3, 1)
  qf.add_comment('NOTE')
  vim.fn.cursor(5, 1)
  qf.add_comment('SUGGESTION')
  assert.length(vim.fn.getqflist(), 3, 'three comments added')

  qf.clear_review()
  assert.length(vim.fn.getqflist(), 0, 'all comments cleared')
end)

assert.run_test('summary counts comment types', function()
  vim.fn.setqflist({})
  vim.fn.cursor(1, 1)
  qf.add_comment('ISSUE')
  vim.fn.cursor(2, 1)
  qf.add_comment('ISSUE')
  vim.fn.cursor(3, 1)
  qf.add_comment('SUGGESTION')
  vim.fn.cursor(4, 1)
  qf.add_comment('NOTE')

  -- summary() prints to output, we just verify it doesn't error
  qf.summary()
  assert.length(vim.fn.getqflist(), 4, 'comments still exist after summary')
end)

test_helper.cleanup_test_environment()

return assert
