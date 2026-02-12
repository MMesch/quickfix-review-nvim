-- Configuration and defaults for quickfix-review.nvim
local M = {}

-- Default configuration
M.defaults = {
  -- Storage file path for saving/loading reviews
  storage_file = vim.fn.stdpath('data') .. '/quickfix-review.json',

  -- Default export filename (nil = clipboard only, set to 'quickfix-review.md' to also save to file)
  export_file = nil,

  -- Prompt to clear comments when file changes on disk
  prompt_on_file_change = false,

  -- Sign definitions
  signs = {
    issue = { text = '⚠', texthl = 'DiagnosticError' },
    suggestion = { text = '💭', texthl = 'DiagnosticWarn' },
    note = { text = '📝', texthl = 'DiagnosticInfo' },
    praise = { text = '✨', texthl = 'DiagnosticHint' },
    question = { text = '?', texthl = 'DiagnosticInfo' },
    insight = { text = '💡', texthl = 'DiagnosticHint' },
    -- Continuation signs for multiline comments (vertical bars)
    issue_continuation = { text = '│', texthl = 'DiagnosticError' },
    suggestion_continuation = { text = '│', texthl = 'DiagnosticWarn' },
    note_continuation = { text = '│', texthl = 'DiagnosticInfo' },
    praise_continuation = { text = '│', texthl = 'DiagnosticHint' },
    question_continuation = { text = '│', texthl = 'DiagnosticInfo' },
    insight_continuation = { text = '│', texthl = 'DiagnosticHint' },
  },

  -- Export format strings
  export = {
    header = '# Code Review\n\n',
    type_legend = 'Comment types: ISSUE (problems to fix), SUGGESTION (improvements), NOTE (observations), PRAISE (positive feedback), QUESTION (clarification needed), INSIGHT (useful observations)\n',
    item_format = '%d. **[%s]** `%s:%d` - %s',
  },

  -- Keymaps (set to false to disable a keymap)
  keymaps = {
    add_issue = '<leader>ci',
    add_suggestion = '<leader>cs',
    add_note = '<leader>cn',
    add_praise = '<leader>cp',
    add_question = '<leader>cq',
    add_insight = '<leader>ck',
    delete_comment = '<leader>cd',
    export = '<leader>ce',
    clear = '<leader>cc',
    summary = '<leader>cS',
    save = '<leader>cw',
    load = '<leader>cr',
    open_list = '<leader>co',
    next_comment = ']r',
    prev_comment = '[r',
    goto_real_file = '<leader>cg',
    view = '<leader>cv',
  },
}

-- Current options (populated by setup)
M.options = {}

-- Setup configuration by merging user options with defaults
function M.setup(opts)
  local user_opts = opts or {}
  user_opts.signs = user_opts.signs or {}

  -- Ensure continuation signs are defined (use defaults if not provided)
  local highlights = {
    issue = 'DiagnosticError', suggestion = 'DiagnosticWarn',
    note = 'DiagnosticInfo', praise = 'DiagnosticHint', question = 'DiagnosticInfo', insight = 'DiagnosticHint'
  }
  for t, hl in pairs(highlights) do
    local key = t .. '_continuation'
    if not user_opts.signs[key] then
      user_opts.signs[key] = { text = '│', texthl = hl }
    end
  end

  M.options = vim.tbl_deep_extend('force', {}, M.defaults, user_opts)
  return M.options
end

return M
