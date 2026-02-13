-- Configuration and defaults for quickfix-review.nvim
local M = {}

-- Default comment types
M.default_comment_types = {
  issue = { sign = '⚠', highlight = 'DiagnosticError', description = 'Problems to fix' },
  suggestion = { sign = '💭', highlight = 'DiagnosticWarn', description = 'Improvements' },
  note = { sign = '📝', highlight = 'DiagnosticInfo', description = 'Observations' },
  praise = { sign = '✨', highlight = 'DiagnosticHint', description = 'Positive feedback' },
  question = { sign = '?', highlight = 'DiagnosticInfo', description = 'Clarification needed' },
  insight = { sign = '💡', highlight = 'DiagnosticHint', description = 'Useful observations' }
}

-- Default keymaps for default comment types
M.default_type_keymaps = {
  add_issue = '<leader>ci',
  add_suggestion = '<leader>cs',
  add_note = '<leader>cn',
  add_praise = '<leader>cp',
  add_question = '<leader>cq',
  add_insight = '<leader>ck',
}

-- Default configuration
M.defaults = {
  -- Storage file path for saving/loading reviews
  storage_file = vim.fn.stdpath('data') .. '/quickfix-review.json',

  -- Default export filename (nil = clipboard only, set to 'quickfix-review.md' to also save to file)
  export_file = nil,

  -- Prompt to clear comments when file changes on disk
  prompt_on_file_change = false,

  -- Comment types: if provided, replaces defaults entirely
  -- Use additional_comment_types to add to defaults instead
  comment_types = nil,

  -- Additional comment types: merged with defaults (or with comment_types if provided)
  additional_comment_types = nil,

  -- Sign definitions (generated from comment_types, but can be overridden)
  signs = {},

  -- Sign column slot (1-indexed). Set to a specific number (e.g., 2) to place
  -- review signs in a dedicated column, allowing git gutter signs in another.
  -- Requires signcolumn=yes:N or signcolumn=auto:N with N >= sign_column_slot.
  -- nil = auto (Neovim chooses available slot)
  sign_column_slot = nil,

  -- Export format strings
  export = {
    header = '# Code Review\n\n',
    type_legend = '',  -- Generated dynamically from comment_types
    item_format = '%d. **[%s]** `%s:%d` - %s',
  },

  -- Keymaps (set to false to disable a keymap)
  -- Keymaps for comment types (add_<type>) are generated based on available types
  keymaps = {
    -- Comment type cycling
    add_comment_cycle = '<leader>ca',  -- Add comment with current cycle type
    cycle_next = '+',                  -- Cycle to next type
    cycle_previous = '-',              -- Cycle to previous type

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

  -- Start with defaults (excluding comment_types which is handled specially)
  M.options = vim.tbl_deep_extend('force', {}, M.defaults, user_opts)

  -- Determine final comment_types:
  -- 1. If user provides comment_types, use it (replaces defaults)
  -- 2. Otherwise use default_comment_types
  -- 3. Merge additional_comment_types on top
  local base_types
  if user_opts.comment_types then
    base_types = vim.deepcopy(user_opts.comment_types)
  else
    base_types = vim.deepcopy(M.default_comment_types)
  end

  if user_opts.additional_comment_types then
    base_types = vim.tbl_deep_extend('force', base_types, user_opts.additional_comment_types)
  end

  M.options.comment_types = base_types

  -- Generate keymaps for available comment types
  -- Start with user-provided keymaps, then add defaults for existing types
  for type_name, _ in pairs(M.options.comment_types) do
    local keymap_key = 'add_' .. type_name
    -- Only set default keymap if user didn't provide one and it's a default type
    if M.options.keymaps[keymap_key] == nil and M.default_type_keymaps[keymap_key] then
      M.options.keymaps[keymap_key] = M.default_type_keymaps[keymap_key]
    end
  end

  -- Generate signs from comment_types if not explicitly overridden
  if not user_opts.signs or vim.tbl_isempty(user_opts.signs) then
    M.options.signs = {}

    -- Generate main signs and continuation signs from comment_types
    for type_name, type_config in pairs(M.options.comment_types) do
      -- Main sign
      M.options.signs[type_name] = {
        text = type_config.sign,
        texthl = type_config.highlight
      }

      -- Continuation sign
      local cont_key = type_name .. '_continuation'
      M.options.signs[cont_key] = {
        text = '│',
        texthl = type_config.highlight
      }
    end
  end

  -- Generate type legend for export
  local type_descriptions = {}
  for type_name, type_config in pairs(M.options.comment_types) do
    table.insert(type_descriptions, type_name:upper() .. ' (' .. type_config.description .. ')')
  end
  M.options.export.type_legend = 'Comment types: ' .. table.concat(type_descriptions, ', ') .. '\n'

  return M
end

return M
