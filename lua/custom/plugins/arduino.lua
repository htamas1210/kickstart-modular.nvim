return {
  'yuukiflow/Arduino-Nvim',
  ft = 'arduino',
  opts = {
    config_file = '.arduino_config.lua', -- filename used to persist the config
    board = 'arduino:avr:uno', -- target board
    port = '/dev/ttyUSB0', -- target port
    baudrate = 115200, -- target baudrate
    use_default_keymaps = true, -- load default keymaps
    use_default_commands = true, -- load default commands
    keymaps = {}, -- custom keymaps
    picker_backend = 'telescope', -- backend to use for user input commands
  },
  dependencies = {
    'nvim-telescope/telescope.nvim',
    -- optional: remove if you use Neovim's built-in LSP (>= 0.11)
    -- 'neovim/nvim-lspconfig',
  },
}
