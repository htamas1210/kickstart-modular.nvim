return {
  'walcht/neovim-unity',
  ft = { 'cs' },
  dependencies = { 'neovim/nvim-lspconfig' }, -- Ensure lspconfig is loaded first

  config = function()
    local function on_init_sln(client, target)
      vim.notify('Initializing: ' .. target, vim.log.levels.INFO)
      ---@diagnostic disable-next-line: param-type-mismatch
      client:notify('solution/open', {
        solution = vim.uri_from_fname(target),
      })
    end

    local function on_init_project(client, project_files)
      vim.notify('Initializing: projects', vim.log.levels.INFO)
      ---@diagnostic disable-next-line: param-type-mismatch
      client:notify('project/open', {
        projects = vim.tbl_map(function(file)
          return vim.uri_from_fname(file)
        end, project_files),
      })
    end

    local function project_root_dir_discovery(bufnr, cb)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if not bufname:match('^' .. vim.fs.joinpath '/tmp/MetadataAsSource/') then
        local root_dir = vim.fs.root(bufnr, function(fname, _)
          return fname:match '%.sln$' ~= nil
        end)

        if not root_dir then
          root_dir = vim.fs.root(bufnr, function(fname, _)
            return fname:match '%.csproj$' ~= nil
          end)
        end

        if root_dir then
          cb(root_dir)
        else
          vim.notify('[C# LSP] failed to find root directory', vim.log.levels.ERROR)
        end
      end
    end

    local roslyn_handlers = {
      ['workspace/projectInitializationComplete'] = function(_, _, ctx)
        vim.notify('Roslyn project initialization complete', vim.log.levels.INFO)
        local buffers = vim.lsp.get_buffers_by_client_id(ctx.client_id)
        local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
        for _, buf in ipairs(buffers) do
          client:request(vim.lsp.protocol.Methods.textDocument_diagnostic, {
            textDocument = vim.lsp.util.make_text_document_params(buf),
          }, nil, buf)
        end
      end,
      ['workspace/_roslyn_projectNeedsRestore'] = function(_, result, ctx)
        local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
        client:request('workspace/_roslyn_restore', result, function(err, response)
          if err then
            vim.notify(err.message, vim.log.levels.ERROR)
          end
          if response then
            vim.notify('Restoring project...', vim.log.levels.INFO)
          end
        end)
        return vim.NIL
      end,
      ['razor/provideDynamicFileInfo'] = function(_, _, _)
        -- Razor not supported
      end,
    }

    local roslyn_ls_config = {
      name = 'roslyn_ls',
      offset_encoding = 'utf-8',
      cmd = {
        'dotnet',
        '$HOME/.config/roslylsp/Microsoft.CodeAnalysis.LanguageServer.dll',
        '--logLevel=Error',
        '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
        '--stdio',
      },
      filetypes = { 'cs' },
      handlers = roslyn_handlers,
      root_dir = project_root_dir_discovery,
      on_init = function(client)
        local root_dir = client.config.root_dir
        for entry, type in vim.fs.dir(root_dir) do
          if type == 'file' and vim.endswith(entry, '.sln') then
            on_init_sln(client, vim.fs.joinpath(root_dir, entry))
            return
          end
        end
        for entry, type in vim.fs.dir(root_dir) do
          if type == 'file' and vim.endswith(entry, '.csproj') then
            on_init_project(client, { vim.fs.joinpath(root_dir, entry) })
          end
        end
      end,
      capabilities = vim.lsp.protocol.make_client_capabilities(),
      settings = {
        ['csharp|background_analysis'] = {
          dotnet_analyzer_diagnostics_scope = 'fullSolution',
          dotnet_compiler_diagnostics_scope = 'fullSolution',
        },
        ['csharp|inlay_hints'] = {
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_parameters = true,
        },
        ['csharp|completion'] = {
          dotnet_show_name_completion_suggestions = true,
        },
      },
    }

    -- NOTE: 'vim.lsp.config' does not exist in standard Neovim.
    -- We use an autocommand to start the LSP when a C# file opens.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'cs',
      callback = function()
        vim.lsp.start(roslyn_ls_config)
      end,
    })
  end,
}
