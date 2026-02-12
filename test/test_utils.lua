-- Tests for utility functions
local assert = dofile('test/assertions.lua')

print('\nRunning utility tests...')

-- Add current directory to runtime path
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Clear cached modules
package.loaded['quickfix-review.utils'] = nil

local utils = require('quickfix-review.utils')

assert.run_test('parse_comment_type extracts ISSUE', function()
  local result = utils.parse_comment_type('[ISSUE] Some text')
  assert.equals(result, 'ISSUE', 'parse basic ISSUE')
end)

assert.run_test('parse_comment_type extracts SUGGESTION', function()
  local result = utils.parse_comment_type('[SUGGESTION] Some text')
  assert.equals(result, 'SUGGESTION', 'parse SUGGESTION')
end)

assert.run_test('parse_comment_type extracts NOTE', function()
  local result = utils.parse_comment_type('[NOTE] Some text')
  assert.equals(result, 'NOTE', 'parse NOTE')
end)

assert.run_test('parse_comment_type extracts PRAISE', function()
  local result = utils.parse_comment_type('[PRAISE] Some text')
  assert.equals(result, 'PRAISE', 'parse PRAISE')
end)

assert.run_test('parse_comment_type extracts QUESTION', function()
  local result = utils.parse_comment_type('[QUESTION] Some text')
  assert.equals(result, 'QUESTION', 'parse QUESTION')
end)

assert.run_test('parse_comment_type handles multiline format', function()
  local result = utils.parse_comment_type('[ISSUE:L3-7] Some text')
  assert.equals(result, 'ISSUE', 'parse multiline ISSUE')
end)

assert.run_test('parse_comment_type defaults to NOTE', function()
  local result = utils.parse_comment_type('No brackets here')
  assert.equals(result, 'NOTE', 'defaults to NOTE')
end)

assert.run_test('parse_comment_type handles empty string', function()
  local result = utils.parse_comment_type('')
  assert.equals(result, 'NOTE', 'empty string defaults to NOTE')
end)

assert.run_test('files_match with identical paths', function()
  local result = utils.files_match('/home/user/file.txt', '/home/user/file.txt')
  assert.truthy(result, 'identical paths match')
end)

assert.run_test('files_match with different paths', function()
  local result = utils.files_match('/home/user/file1.txt', '/home/user/file2.txt')
  assert.falsy(result, 'different paths do not match')
end)

assert.run_test('files_match normalizes relative and absolute', function()
  -- Create a test file
  local test_file = 'test_utils_file.txt'
  local f = io.open(test_file, 'w')
  if f then
    f:write('test')
    f:close()
  end

  local cwd = vim.fn.getcwd()
  local abs_path = cwd .. '/' .. test_file
  local result = utils.files_match(test_file, abs_path)

  os.remove(test_file)
  assert.truthy(result, 'relative and absolute paths match')
end)

assert.run_test('is_special_buffer returns false for regular files', function()
  -- Create and open a regular file
  local test_file = 'test_regular_file.txt'
  local f = io.open(test_file, 'w')
  if f then
    f:write('test content')
    f:close()
  end
  vim.cmd('edit ' .. test_file)

  local result = utils.is_special_buffer()
  os.remove(test_file)

  assert.falsy(result, 'regular file is not special buffer')
end)

assert.run_test('get_real_filepath returns path for regular files', function()
  local test_file = 'test_filepath.txt'
  local f = io.open(test_file, 'w')
  if f then
    f:write('test')
    f:close()
  end
  vim.cmd('edit ' .. test_file)

  local result = utils.get_real_filepath()
  os.remove(test_file)

  assert.matches(result, 'test_filepath%.txt', 'returns file path')
end)

return assert
