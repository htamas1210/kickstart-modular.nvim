return {
  'brianhuster/live-preview.nvim',
  cmd = { 'LivePreview' },
  keys = {
    { '<leader>lp', '<cmd>LivePreview start<cr>', desc = '[L]ive [P]review Start' },
    { '<leader>lP', '<cmd>LivePreview close<cr>', desc = '[L]ive [P]review Close' },
    { '<leader>lt', '<cmd>LivePreview toggle<cr>', desc = '[L]ive [P]review Toggle' },
  },
  opts = {
    -- Port to run the preview server on
    port = 5500,
    -- Set to true if you want the browser to open automatically on start
    dynamic_root = true,
  },
}
