local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ========================
-- 基础设置（全局配置）
-- ========================
vim.g.mapleader = " " -- 设置 leader 键
vim.g.maplocalleader = "\\" -- 设置本地 leader 键

-- 界面优化
vim.opt.number = true -- 显示行号
vim.opt.relativenumber = true -- 相对行号
vim.opt.cursorline = true -- 高亮当前行
vim.opt.showtabline = 2 -- 始终显示标签栏

-- 编辑体验
vim.opt.hidden = true -- 允许隐藏已修改缓冲区
vim.opt.splitright = true -- 垂直分割在右侧
vim.opt.splitbelow = true -- 水平分割在下方
vim.opt.signcolumn = "yes" -- 始终显示标记栏
vim.opt.mouse = "a" -- 启用鼠标支持

-- 快捷键优化（全部添加 desc 描述）
vim.keymap.set('n', '<leader>bn', ':bn<CR>', { desc = '下一个缓冲区' })
vim.keymap.set('n', '<leader>bp', ':bp<CR>', { desc = '上一个缓冲区' })
vim.keymap.set('n', '<leader>qq', ':bd<CR>', { desc = '关闭缓冲区窗口' })
vim.keymap.set('n', '<leader>wh', '<C-w>s', { desc = '水平分割窗口' })
vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = '垂直分割窗口' })
vim.keymap.set('n', '<leader>tt', ':tabnew<CR>', { desc = '新建标签页' })

-- 终端设置
vim.api.nvim_set_keymap('t', '<C-q>', '<C-\\><C-n>', { noremap = true, silent = true, desc = '退出终端模式' })

-- 创建自动命令组（避免重复注册）
vim.api.nvim_create_augroup('highlight_yank', { clear = true })

-- 监听 TextYankPost 事件，复制完成后触发高亮
vim.api.nvim_create_autocmd('TextYankPost', {
  group = 'highlight_yank',
  pattern = '*',  -- 适用于所有文件类型
  callback = function()
    vim.highlight.on_yank {
      higroup = 'IncSearch',  -- 使用 IncSearch 颜色组（默认黄/红色背景）
      timeout = 700,          -- 高亮持续时间（毫秒）
      on_visual = true,       -- 在可视模式下也生效（Neovim 0.9+）
    }
  end,
})

-- ========================
-- 插件配置
-- ========================
require("lazy").setup({
  -- ===== 核心插件 =====
  {
    "tanvirtin/monokai.nvim", -- 主题
    lazy = false, -- 立即加载
    priority = 1000, -- 最高优先级
    config = function()
      vim.cmd.colorscheme("monokai")
      -- 主题额外配置
      vim.g.monokai_italic = 1
      vim.g.monokai_term_italic = 1
    end
  },

  -- ===== 文件管理 =====
  {
    "nvim-tree/nvim-tree.lua", -- 文件浏览器
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- 安全加载
      local ok, nvim_tree = pcall(require, "nvim-tree")
      if not ok then return end
      
      nvim_tree.setup({
        view = { width = 30 },
        renderer = {
          group_empty = true,
          icons = { show = { file = true, folder = true, git = true } }
        },
        actions = { open_file = { quit_on_open = true } },
        filters = { custom = { "^.git$", "^node_modules$" } }, -- 隐藏特定目录
      })

      -- 快捷键
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", 
        { noremap = true, silent = true, desc = "切换文件浏览器" })
      
      vim.keymap.set("n", "<leader>f", ":NvimTreeFindFile<CR>", 
        { noremap = true, silent = true, desc = "定位当前文件" })
    end
  },

  -- ===== 终端集成 =====
  {
    "akinsho/toggleterm.nvim", -- 浮动终端
    version = "*",
    config = function()
      local ok, toggleterm = pcall(require, "toggleterm")
      if not ok then return end
      
      toggleterm.setup({
        size = 15,
        open_mapping = [[<leader>tt]],
        direction = "float",
        float_opts = {
          border = "rounded",
          winblend = 10,
          highlights = {
            border = "FloatBorder", -- 使用主题中的边框颜色
            background = "NormalFloat" -- 使用主题中的背景色
          }
        },
        close_on_exit = true,
        persist_mode = false,
        shell = vim.o.shell,
      })

      -- 终端快捷键
      local function term_map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { desc = desc, buffer = true })
      end
      
      vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", 
        { desc = "浮动终端" })
      vim.keymap.set("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", 
        { desc = "水平终端" })
      vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", 
        { desc = "垂直终端" })

      -- 终端模式快捷键
      term_map("t", "<Esc>", "<C-\\><C-n>", "退出终端模式")
      term_map("t", "<C-h>", "<C-\\><C-n><C-w>h", "向左移动")
      term_map("t", "<C-j>", "<C-\\><C-n><C-w>j", "向下移动")
      term_map("t", "<C-k>", "<C-\\><C-n><C-w>k", "向上移动")
      term_map("t", "<C-l>", "<C-\\><C-n><C-w>l", "向右移动")

      -- LazyGit 集成
      local Terminal = require("toggleterm.terminal").Terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "t", "q", "<cmd>close<CR>", {noremap = true, silent = true})
        end,
      })

      vim.keymap.set("n", "<leader>gg", function()
        lazygit:toggle()
      end, { desc = "打开LazyGit" })
    end
  },

  -- ===== 界面增强 =====
  {
    "akinsho/bufferline.nvim", -- 缓冲区标签栏
    dependencies = "nvim-tree/nvim-web-devicons",
    event = "BufReadPost", -- 延迟加载
    config = function()
      local ok, bufferline = pcall(require, "bufferline")
      if not ok then return end
      
      bufferline.setup({
        options = {
          mode = "buffers",
          separator_style = "slant",
          always_show_bufferline = true,
          show_buffer_close_icons = false,
          show_close_icon = false,
          diagnostics = "nvim_lsp",
          offsets = {
            {
              filetype = "NvimTree",
              text = "文件浏览器",
              highlight = "Directory",
              text_align = "left",
            }
          }
        }
      })
    end
  },

  -- ===== 搜索功能 =====
  {
    "nvim-telescope/telescope.nvim", -- 文件搜索
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- 编译优化
    },
    cmd = "Telescope", -- 延迟加载
    config = function()
      local ok, telescope = pcall(require, "telescope")
      if not ok then return end
      
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git", "target" },
          mappings = {
            i = {
              ["<Esc>"] = require("telescope.actions").close,
              ["<C-j>"] = require("telescope.actions").move_selection_next,
              ["<C-k>"] = require("telescope.actions").move_selection_previous,
            },
          },
          layout_strategy = "flex",
          layout_config = {
            horizontal = { preview_width = 0.6 },
          }
        },
        pickers = {
          find_files = {
            hidden = true, -- 包括隐藏文件
          }
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
          }
        }
      })
      
      pcall(telescope.load_extension, "fzf")
      
      -- 快捷键映射
      local builtin = require("telescope.builtin")
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '搜索文件' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '内容搜索' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '缓冲区搜索' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '帮助文档' })
      vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = '命令搜索' })
    end
  },

  -- ===== 会话管理 =====
  {
    "rmagatti/auto-session", -- 自动会话
    config = function()
      local ok, auto_session = pcall(require, "auto-session")
      if not ok then return end
      
      auto_session.setup({
        auto_session_enable_last_session = true,
        auto_session_create_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        log_level = "error",
      })
      
      -- 自动恢复会话（放在插件配置内确保加载顺序）
      vim.api.nvim_create_autocmd({ "VimEnter" }, {
        pattern = { "*" },
        callback = function()
          -- 安全恢复会话
          pcall(auto_session.RestoreSession)
        end,
      })
    end
  },
  
  -- ===== 可选增强插件 =====
  {
    "windwp/nvim-autopairs", -- 自动括号配对
    event = "InsertEnter",
    config = function() require("nvim-autopairs").setup() end
  },
  
  {
    "numToStr/Comment.nvim", -- 智能注释
    keys = { "gc", "gb" },
    config = function() require("Comment").setup() end
  },

   -- 安装可视化增强插件
   {
        "mvllow/modes.nvim",
        config = function()
            require("modes").setup({
                colors = {
                    visual = "#FFD700", -- 金色边框
                },
                line_opacity = 0.2,    -- 行高亮透明度
                set_cursor = true,
                set_cursorline = true,
                set_number = false,
            })
        end
    }
})

-- ========================
-- 后置配置
-- ========================
-- 确保终端颜色正确
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.cmd([[
      highlight TermCursor cterm=reverse gui=reverse
      highlight! link TermCursor Cursor
    ]])
  end
})

-- 自动切换目录
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    -- 仅在普通缓冲区设置工作目录
    if vim.bo.buftype == "" then
      vim.cmd("silent! lcd %:p:h")
    end
  end
})
