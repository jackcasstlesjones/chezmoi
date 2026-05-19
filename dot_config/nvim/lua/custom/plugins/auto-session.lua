return {
  'rmagatti/auto-session',
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    pre_save_cmds = { 'DiffviewClose' },
    -- log_level = 'debug',
  },
}
