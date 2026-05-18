return {
	"sindrets/diffview.nvim",
	enabled = true,
	lazy = false,
	keys = {
		{ "<leader>vo", function() require("diffview").open() end, desc = "Diffview open" },
		{ "<leader>vd", function() require("diffview").open("origin/develop...HEAD") end, desc = "Diffview vs develop" },
		{ "<leader>vm", function() require("diffview").open("origin/main...HEAD") end, desc = "Diffview vs main" },
		{ "<leader>vv", function() require("diffview").close() end, desc = "Diffview close" },
		{ "<leader>vh", function() vim.cmd("DiffviewFileHistory %") end, desc = "Diffview file history" },
		{ "<leader>vH", function() vim.cmd("DiffviewFileHistory") end, desc = "Diffview repo history" },
	},
}
