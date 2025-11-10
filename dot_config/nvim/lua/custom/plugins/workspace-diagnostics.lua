return {
	"artemave/workspace-diagnostics.nvim",
	config = function()
		-- Setup workspace diagnostics
		require("workspace-diagnostics").setup({
			-- Optional: customize which files to scan
			-- By default uses git ls-files
			-- workspace_files = function()
			--   return vim.fn.systemlist('git ls-files')
			-- end
		})

		-- Integrate with LSP attach
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("workspace-diagnostics-attach", { clear = true }),
			callback = function(event)
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client then
					-- Populate workspace diagnostics when LSP attaches
					require("workspace-diagnostics").populate_workspace_diagnostics(client, event.buf)
				end
			end,
		})

		-- Optional: Add a manual trigger keymap
		vim.keymap.set("n", "<leader>wd", function()
			for _, client in ipairs(vim.lsp.get_clients()) do
				require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
			end
		end, { desc = "[W]orkspace [D]iagnostics refresh" })
	end,
}
