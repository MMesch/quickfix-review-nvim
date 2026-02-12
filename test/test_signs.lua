-- Tests for sign placement
local test_helper = dofile('test/init.lua')
local assert = dofile('test/assertions.lua')
local utils = require('quickfix-review.utils')

print('\nRunning sign tests...')

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

-- Get extmarks on a specific line (0-indexed internally, 1-indexed for callers)
local function get_extmarks_on_line(bufnr, lnum)
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, utils.get_ns_id(), { lnum - 1, 0 }, { lnum - 1, -1 }, { details = true })
  return marks
end

local function has_sign_on_line(bufnr, lnum)
  return #get_extmarks_on_line(bufnr, lnum) > 0
end

-- Get the sign text from extmarks on a line (maps back to sign name for compatibility)
local function get_sign_name_on_line(bufnr, lnum)
  local marks = get_extmarks_on_line(bufnr, lnum)
  if #marks > 0 then
    local details = marks[1][4]
    local sign_text = details and details.sign_text
    if not sign_text then return nil end
    -- Trim whitespace from sign_text (Neovim pads to 2 cells)
    sign_text = sign_text:gsub('%s+$', ''):gsub('^%s+', '')
    -- Map sign text back to sign name (test config uses ASCII: !, ?, N, +, Q, |)
    local sign_mapping = {
      ['!'] = 'review_issue',
      ['?'] = 'review_suggestion',
      ['N'] = 'review_note',
      ['+'] = 'review_praise',
      ['Q'] = 'review_question',
    }
    if sign_text == '|' then
      -- Check highlight to determine continuation type
      local hl = details.sign_hl_group
      if hl == 'DiagnosticError' then return 'review_issue_continuation'
      elseif hl == 'DiagnosticWarn' then return 'review_suggestion_continuation'
      elseif hl == 'DiagnosticInfo' then return 'review_note_continuation'
      elseif hl == 'DiagnosticHint' then return 'review_praise_continuation'
      end
    end
    return sign_mapping[sign_text]
  end
  return nil
end

-- Helper to clear extmarks (replaces sign_unplace)
local function clear_extmarks(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, utils.get_ns_id(), 0, -1)
end

assert.run_test('sign definitions exist', function()
  local defined = vim.fn.sign_getdefined()
  local sign_names = {}
  for _, sign in ipairs(defined) do
    sign_names[sign.name] = true
  end

  assert.truthy(sign_names['review_issue'], 'review_issue defined')
  assert.truthy(sign_names['review_suggestion'], 'review_suggestion defined')
  assert.truthy(sign_names['review_note'], 'review_note defined')
  assert.truthy(sign_names['review_praise'], 'review_praise defined')
  assert.truthy(sign_names['review_issue_continuation'], 'review_issue_continuation defined')
end)

assert.run_test('single line comment places one sign', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  vim.fn.cursor(5, 1)
  qf.add_comment('ISSUE')

  assert.truthy(has_sign_on_line(bufnr, 5), 'sign on line 5')
  assert.falsy(has_sign_on_line(bufnr, 4), 'no sign on line 4')
  assert.falsy(has_sign_on_line(bufnr, 6), 'no sign on line 6')
end)

assert.run_test('multiline comment places signs on all lines', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  qf.add_comment('ISSUE', { 3, 7 })

  -- Start and end lines should have main sign
  assert.truthy(has_sign_on_line(bufnr, 3), 'sign on start line 3')
  assert.truthy(has_sign_on_line(bufnr, 7), 'sign on end line 7')

  -- Middle lines should have continuation signs
  assert.truthy(has_sign_on_line(bufnr, 4), 'sign on line 4')
  assert.truthy(has_sign_on_line(bufnr, 5), 'sign on line 5')
  assert.truthy(has_sign_on_line(bufnr, 6), 'sign on line 6')

  -- Lines outside range should have no signs
  assert.falsy(has_sign_on_line(bufnr, 2), 'no sign on line 2')
  assert.falsy(has_sign_on_line(bufnr, 8), 'no sign on line 8')
end)

assert.run_test('continuation signs on middle lines', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  qf.add_comment('ISSUE', { 2, 6 })

  -- Start line has main sign
  local start_sign = get_sign_name_on_line(bufnr, 2)
  assert.equals(start_sign, 'review_issue', 'start line has main sign')

  -- Middle lines have continuation signs
  local middle_sign = get_sign_name_on_line(bufnr, 4)
  assert.equals(middle_sign, 'review_issue_continuation', 'middle line has continuation sign')

  -- End line has main sign
  local end_sign = get_sign_name_on_line(bufnr, 6)
  assert.equals(end_sign, 'review_issue', 'end line has main sign')
end)

assert.run_test('deleting comment removes signs', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  vim.fn.cursor(5, 1)
  qf.add_comment('ISSUE')
  assert.truthy(has_sign_on_line(bufnr, 5), 'sign placed')

  qf.delete_comment({ 5, 5 })
  assert.falsy(has_sign_on_line(bufnr, 5), 'sign removed after delete')
end)

assert.run_test('deleting multiline comment removes all signs', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  qf.add_comment('ISSUE', { 3, 6 })
  assert.truthy(has_sign_on_line(bufnr, 3), 'sign on line 3')
  assert.truthy(has_sign_on_line(bufnr, 5), 'sign on line 5')
  assert.truthy(has_sign_on_line(bufnr, 6), 'sign on line 6')

  qf.delete_comment({ 3, 6 })
  assert.falsy(has_sign_on_line(bufnr, 3), 'sign removed from line 3')
  assert.falsy(has_sign_on_line(bufnr, 5), 'sign removed from line 5')
  assert.falsy(has_sign_on_line(bufnr, 6), 'sign removed from line 6')
end)

assert.run_test('clear_review removes all signs', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  vim.fn.cursor(2, 1)
  qf.add_comment('ISSUE')
  qf.add_comment('NOTE', { 5, 8 })

  assert.truthy(has_sign_on_line(bufnr, 2), 'sign on line 2')
  assert.truthy(has_sign_on_line(bufnr, 5), 'sign on line 5')

  qf.clear_review()

  assert.falsy(has_sign_on_line(bufnr, 2), 'sign removed from line 2')
  assert.falsy(has_sign_on_line(bufnr, 5), 'sign removed from line 5')
end)

assert.run_test('different comment types use correct signs', function()
  vim.fn.setqflist({})
  clear_extmarks(vim.fn.bufnr())
  local bufnr = vim.fn.bufnr()

  vim.fn.cursor(2, 1)
  qf.add_comment('ISSUE')
  vim.fn.cursor(4, 1)
  qf.add_comment('SUGGESTION')
  vim.fn.cursor(6, 1)
  qf.add_comment('NOTE')
  vim.fn.cursor(8, 1)
  qf.add_comment('PRAISE')
  vim.fn.cursor(10, 1)
  qf.add_comment('QUESTION')

  assert.equals(get_sign_name_on_line(bufnr, 2), 'review_issue', 'issue sign')
  assert.equals(get_sign_name_on_line(bufnr, 4), 'review_suggestion', 'suggestion sign')
  assert.equals(get_sign_name_on_line(bufnr, 6), 'review_note', 'note sign')
  assert.equals(get_sign_name_on_line(bufnr, 8), 'review_praise', 'praise sign')
  assert.equals(get_sign_name_on_line(bufnr, 10), 'review_question', 'question sign')
end)

test_helper.cleanup_test_environment()

return assert
