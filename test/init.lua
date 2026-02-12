-- Test initialization for quickfix-review
-- This file sets up the testing environment

-- Add current directory to runtime path
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Clear any cached modules
package.loaded['quickfix-review'] = nil
package.loaded['quickfix-review.config'] = nil
package.loaded['quickfix-review.utils'] = nil
package.loaded['quickfix-review.storage'] = nil
package.loaded['quickfix-review.export'] = nil

-- Load the plugin
local quickfix_review = require('quickfix-review')

-- Mock input function for testing
local original_input = vim.fn.input
vim.fn.input = function(prompt)
  return 'Test comment'
end

-- Test helper functions
local M = {}

function M.setup_test_environment()
  -- Clear any existing quickfix list
  vim.fn.setqflist({})

  -- Setup the plugin with test configuration
  quickfix_review.setup({
    signs = {
      issue = { text = '!', texthl = 'DiagnosticError' },
      suggestion = { text = '?', texthl = 'DiagnosticWarn' },
      note = { text = 'N', texthl = 'DiagnosticInfo' },
      praise = { text = '+', texthl = 'DiagnosticHint' },
      question = { text = 'Q', texthl = 'DiagnosticInfo' },
      issue_continuation = { text = '|', texthl = 'DiagnosticError' },
      suggestion_continuation = { text = '|', texthl = 'DiagnosticWarn' },
      note_continuation = { text = '|', texthl = 'DiagnosticInfo' },
      praise_continuation = { text = '|', texthl = 'DiagnosticHint' },
      question_continuation = { text = '|', texthl = 'DiagnosticInfo' },
    },
    keymaps = {
      add_issue = false,
      add_suggestion = false,
      add_note = false,
      add_praise = false,
      delete_comment = false,
      export = false,
      clear = false,
      summary = false,
      save = false,
      load = false,
      open_list = false,
      next_comment = false,
      prev_comment = false,
      goto_real_file = false,
      view = false,
    }
  })

  return quickfix_review
end

function M.cleanup_test_environment()
  -- Restore original input function
  vim.fn.input = original_input

  -- Clear quickfix list
  vim.fn.setqflist({})

  -- Remove extmarks from all buffers
  local utils = require('quickfix-review.utils')
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, utils.get_ns_id(), 0, -1)
    end
  end

  -- Clean up test files
  os.remove('test_file.txt')
end

function M.create_test_file(content)
  local test_file = 'test_file.txt'
  local file = io.open(test_file, 'w')
  if file then
    file:write(content)
    file:close()
    vim.cmd('edit ' .. test_file)
    return test_file
  end
  return nil
end

function M.get_qf_list()
  return vim.fn.getqflist()
end

function M.print_qf_list()
  local list = M.get_qf_list()
  print('Quickfix List (' .. #list .. ' items):')
  for i, item in ipairs(list) do
    print(string.format('  %d. %s:%d-%d - %s',
      i, vim.fn.fnamemodify(item.filename, ':.'), item.lnum, item.end_lnum or item.lnum, item.text))
  end
end

return M
