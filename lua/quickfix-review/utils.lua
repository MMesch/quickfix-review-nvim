-- Utility functions for quickfix-review.nvim
local M = {}
local config = require('quickfix-review.config')

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

-- Get comment types dynamically from configuration
function M.get_comment_types()
  return vim.tbl_keys(config.options.comment_types)
end

-- Get configuration for a specific comment type
function M.get_comment_type_config(type_name)
  return config.options.comment_types[type_name:lower()]
end

-- Priority map for sign stacking (lower than git signs which typically use 6-10)
-- Generated dynamically based on comment types
function M.get_sign_priority(type_name)
  -- Base priority based on type importance
  local type_config = M.get_comment_type_config(type_name)
  if not type_config then return 50 end
  
  -- Map highlight groups to priorities
  local priority_map = {
    DiagnosticError = 5,
    DiagnosticWarn = 4,
    DiagnosticInfo = 3,
    DiagnosticHint = 2
  }
  
  local base_priority = priority_map[type_config.highlight] or 3
  
  -- Continuation signs get lower priority
  if type_name:find('_continuation$') then
    return 1
  end
  
  return base_priority
end

-- Initialize signs based on configuration
function M.init_signs(config)
  local signs = config.signs or {}
  for type_name, sign_def in pairs(signs) do
    vim.fn.sign_define('review_' .. type_name, sign_def)
    M.sign_config[type_name] = sign_def
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

-- Build extmark options helper
local function make_extmark_opts(text, hl_group, prio)
  local opts = {
    sign_text = text,
    sign_hl_group = hl_group,
    priority = prio,
  }
  if config.options.sign_column_slot then
    opts.number = config.options.sign_column_slot
  end
  return opts
end

-- Place signs for a comment using extmarks (supports multiple signs per line)
-- Note: For proper counting of overlapping comments, use refresh_buffer_signs instead
function M.place_comment_signs(bufnr, comment_type, start_line, end_line)
  if bufnr <= 0 or vim.fn.bufexists(bufnr) ~= 1 then return end

  local type_key = comment_type:lower()
  local sign_cfg = M.sign_config[type_key]
  local cont_cfg = M.sign_config[type_key .. '_continuation']

  if not sign_cfg then return end

  local priority = M.get_sign_priority(type_key) or 50

  -- Place sign at start line using extmark
  vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), start_line - 1, 0,
    make_extmark_opts(sign_cfg.text, sign_cfg.texthl, priority))

  if start_line ~= end_line and cont_cfg then
    local cont_priority = M.get_sign_priority(type_key .. '_continuation') or 30
    for line = start_line + 1, end_line - 1 do
      vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), line - 1, 0,
        make_extmark_opts(cont_cfg.text, cont_cfg.texthl, cont_priority))
    end
    -- Place sign at end line
    vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), end_line - 1, 0,
      make_extmark_opts(sign_cfg.text, sign_cfg.texthl, priority))
  end
end

-- Refresh all signs for a buffer, showing count when multiple comments overlap
-- This clears and re-renders all signs, consolidating overlapping start/end lines
function M.refresh_buffer_signs(bufnr, file)
  if bufnr <= 0 or vim.fn.bufexists(bufnr) ~= 1 then return end

  -- Clear existing signs
  vim.api.nvim_buf_clear_namespace(bufnr, M.get_ns_id(), 0, -1)

  local qf_list = vim.fn.getqflist()

  -- Collect all comments for this file
  -- Track: line -> { count = N, types = {type1, type2, ...}, is_continuation = bool }
  local line_info = {}

  for _, item in ipairs(qf_list) do
    local item_file = item.filename or vim.fn.bufname(item.bufnr)
    if M.files_match(item_file, file) then
      local comment_type = M.parse_comment_type(item.text)
      local start_line = item.lnum
      local end_line = item.end_lnum or item.lnum

      -- Track start line
      if not line_info[start_line] then
        line_info[start_line] = { count = 0, types = {}, is_continuation = false }
      end
      line_info[start_line].count = line_info[start_line].count + 1
      table.insert(line_info[start_line].types, comment_type)

      -- Track end line (if different from start)
      if end_line ~= start_line then
        if not line_info[end_line] then
          line_info[end_line] = { count = 0, types = {}, is_continuation = false }
        end
        line_info[end_line].count = line_info[end_line].count + 1
        table.insert(line_info[end_line].types, comment_type)

        -- Track continuation lines (middle lines)
        for line = start_line + 1, end_line - 1 do
          if not line_info[line] then
            line_info[line] = { count = 0, types = {}, is_continuation = true }
          end
          -- Only mark as continuation if not already a start/end line
          if line_info[line].count == 0 then
            line_info[line].is_continuation = true
          end
          table.insert(line_info[line].types, comment_type)
        end
      end
    end
  end

  -- Place signs based on collected info
  for line, info in pairs(line_info) do
    if info.is_continuation and info.count == 0 then
      -- Pure continuation line - show continuation sign for each type
      local seen_types = {}
      for _, comment_type in ipairs(info.types) do
        local type_key = comment_type:lower()
        if not seen_types[type_key] then
          seen_types[type_key] = true
          local cont_cfg = M.sign_config[type_key .. '_continuation']
          if cont_cfg then
            local cont_priority = M.get_sign_priority(type_key .. '_continuation') or 30
            vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), line - 1, 0,
              make_extmark_opts(cont_cfg.text, cont_cfg.texthl, cont_priority))
          end
        end
      end
    elseif info.count > 0 then
      -- Start or end line - show count or symbol
      -- Use highest priority type for the highlight
      local best_type = info.types[1]:lower()
      local best_priority = M.get_sign_priority(best_type) or 0
      for _, t in ipairs(info.types) do
        local p = M.get_sign_priority(t:lower()) or 0
        if p > best_priority then
          best_priority = p
          best_type = t:lower()
        end
      end

      local sign_cfg = M.sign_config[best_type]
      if sign_cfg then
        local sign_text
        if info.count > 1 then
          -- Multiple comments - show count
          sign_text = tostring(info.count)
        else
          -- Single comment - show symbol
          sign_text = sign_cfg.text
        end

        vim.api.nvim_buf_set_extmark(bufnr, M.get_ns_id(), line - 1, 0,
          make_extmark_opts(sign_text, sign_cfg.texthl, best_priority))
      end
    end
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
