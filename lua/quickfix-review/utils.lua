-- Utility functions for quickfix-review.nvim
local M = {}

local COMMENT_TYPES = {'issue', 'suggestion', 'note', 'praise', 'question'}

-- Namespace for extmarks (lazy initialized)
local ns_id = nil

-- Get or create the namespace ID
function M.get_ns_id()
  if not ns_id then
    ns_id = vim.api.nvim_create_namespace('quickfix_review')
  end
  return ns_id
end

-- Store sign configuration for extmark use
M.sign_config = {}

-- Priority map for sign stacking (lower than git signs which typically use 6-10)
local SIGN_PRIORITY = {
  issue = 5,
  suggestion = 4,
  note = 3,
  praise = 2,
  question = 2,
  issue_continuation = 1,
  suggestion_continuation = 1,
  note_continuation = 1,
  praise_continuation = 1,
  question_continuation = 1,
}

-- Initialize signs based on configuration
function M.init_signs(config)
  local signs = config.signs or {}
  for _, t in ipairs(COMMENT_TYPES) do
    if signs[t] then
      vim.fn.sign_define('review_' .. t, signs[t])
      M.sign_config[t] = signs[t]
    end
    local cont_key = t .. '_continuation'
    if signs[cont_key] then
      vim.fn.sign_define('review_' .. cont_key, signs[cont_key])
      M.sign_config[cont_key] = signs[cont_key]
    end
  end
end

-- Check if two file paths refer to the same file
function M.files_match(file1, file2)
  if file1 == file2 then return true end
  local abs1 = vim.fn.fnamemodify(file1, ':p')
  local abs2 = vim.fn.fnamemodify(file2, ':p')
  return abs1 == abs2
end

-- Extract comment type from formatted text like "[ISSUE]" or "[ISSUE:L1-5]"
function M.parse_comment_type(text)
  return text:match('%[([^:%]]+)') or 'NOTE'
end

-- Place signs for a comment using extmarks (supports multiple signs per line)
function M.place_comment_signs(bufnr, comment_type, start_line, end_line)
  if bufnr <= 0 or vim.fn.bufexists(bufnr) ~= 1 then return end

  local type_key = comment_type:lower()
  local sign_cfg = M.sign_config[type_key]
  local cont_cfg = M.sign_config[type_key .. '_continuation']

  if not sign_cfg then return end

  local priority = SIGN_PRIORITY[type_key] or 50

  -- Place sign at start line using extmark
  vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), start_line - 1, 0, {
    sign_text = sign_cfg.text,
    sign_hl_group = sign_cfg.texthl,
    priority = priority,
  })

  if start_line ~= end_line and cont_cfg then
    local cont_priority = SIGN_PRIORITY[type_key .. '_continuation'] or 30
    for line = start_line + 1, end_line - 1 do
      vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), line - 1, 0, {
        sign_text = cont_cfg.text,
        sign_hl_group = cont_cfg.texthl,
        priority = cont_priority,
      })
    end
    -- Place sign at end line
    vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), end_line - 1, 0, {
      sign_text = sign_cfg.text,
      sign_hl_group = sign_cfg.texthl,
      priority = priority,
    })
  end
end

-- Extract real file path from special diff buffers
function M.get_real_filepath()
  local bufname = vim.fn.expand('%:p')

  -- Handle diffview buffers: diffview:///path/.git//hash/file.txt
  local diffview_match = bufname:match('diffview://.*//[^/]+/(.*)')
  if diffview_match then
    return diffview_match
  end

  -- Handle fugitive buffers: fugitive:///path/.git//hash/file.txt
  local fugitive_match = bufname:match('fugitive://.*//[^/]+/(.*)')
  if fugitive_match then
    return fugitive_match
  end

  -- Handle codediff buffers
  local codediff_match = bufname:match('codediff://+(.+)')
  if codediff_match then
    local clean_path = codediff_match:match('//:[^/]+/(.*)')
    if clean_path then
      return clean_path
    end
    clean_path = codediff_match:match('/+([^/].*)')
    if clean_path then
      return clean_path
    end
  end

  return bufname
end

-- Check if current buffer is a diff/special buffer
function M.is_special_buffer()
  local bufname = vim.fn.expand('%:p')
  return bufname:match('^diffview://')
      or bufname:match('^fugitive://')
      or bufname:match('^codediff://')
end

return M
