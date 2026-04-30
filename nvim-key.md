# Neovim (LazyVim) 快捷键速查表

> Neovim 0.12.2 + LazyVim + Snacks Explorer
> `<leader>` = `<Space>`

---

## 基础移动与编辑

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `j` / `k` | 上下移动（支持自动换行行） | n, x |
| `<A-j>` / `<A-k>` | 向下/上移动整行 | n, i, v |
| `<` / `>` | 减少/增加缩进（保持选中） | x |
| `gcc` | 注释/取消注释当前行 | n |
| `gc` | 注释/取消注释选中区域 | x |
| `gco` / `gcO` | 在下方/上方插入注释行 | n |
| `n` / `N` | 下/上一个搜索结果（居中） | n, x, o |
| `<Esc>` | 清除搜索高亮 | n |
| `<C-s>` | 保存文件 | n, i, x, s |
| `,` / `.` / `;` | 插入模式下的撤销断点 | i |

## 文件与 Buffer

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<leader>fn` | 新建文件 | n |
| `<leader>e` | 打开/关闭文件浏览器 | n |
| `<leader>E` | 文件浏览器（当前目录） | n |
| `<leader>ff` | 查找文件 | n |
| `<leader>fr` | 最近文件 | n |
| `<leader>fb` | 查找 Buffer | n |
| `<S-h>` / `[b` | 上一个 buffer | n |
| `<S-l>` / `]b` | 下一个 buffer | n |
| `<leader>bb` | 切换到其他 buffer | n |
| `<leader>bd` | 删除 buffer | n |
| `<leader>bo` | 删除其他 buffer | n |
| `<leader>bD` | 删除 buffer 和窗口 | n |
| `<leader>bp` | 切换 buffer 固定状态 | n |
| `<leader>bP` | 删除未固定的 buffer | n |
| `<leader>br` / `<leader>bl` | 删除右/左侧 buffer | n |
| `<leader>bj` | 选择 buffer | n |
| `[B` / `]B` | 向左/右移动 buffer | n |

## 窗口与 Tab

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<C-h/j/k/l>` | 切换窗口方向（tmux/nvim 无缝导航） | n |
| `<C-Up/Down>` | 增加/减少窗口高度 | n |
| `<C-Left/Right>` | 减少/增加窗口宽度 | n |
| `<leader>-` | 水平分割窗口 | n |
| `<leader>\` | 垂直分割窗口 | n |
| `<leader>wx` | 关闭窗口（与 tmux `prefix+x` 一致） | n |
| `<leader>wd` | 关闭窗口（LazyVim 默认） | n |
| `<leader>wm` / `<leader>uZ` | 切换窗口最大化 | n |
| `<leader>uz` | 切换 Zen 模式 | n |
| `<leader><tab><tab>` | 新建 tab | n |
| `<leader><tab>d` | 关闭 tab | n |
| `<leader><tab>]` / `<leader><tab>[` | 下/上一个 tab | n |
| `<leader><tab>l` / `<leader><tab>f` | 最后/第一个 tab | n |
| `<leader><tab>o` | 关闭其他 tab | n |

## 搜索与替换

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<leader>/` | Grep 搜索（项目根目录） | n |
| `<leader>sg` | Grep 搜索 | n |
| `<leader>sw` | 搜索光标下单词 | n |
| `<leader>sr` | 搜索和替换（grug-far，多文件） | n, x |
| `<leader>st` | 搜索 TODO 注释 | n |
| `<leader>sT` | 搜索 TODO/FIX/FIXME | n |

## LSP（代码智能）

> **注意**：Neovim 0.11.2+ 不再有 `:LspRestart`，改用 `:lsp restart [server]`

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `gd` | 跳转到定义 | n |
| `gD` | 跳转到声明 | n |
| `gr` | 跳转到引用 | n |
| `gy` | 跳转到类型定义 | n |
| `gI` | 跳转到实现 | n |
| `K` | 显示悬停文档 | n |
| `<leader>ca` | 代码操作 | n |
| `<leader>cr` | 重命名符号 | n |
| `<leader>cf` | 格式化代码 | n, x |
| `<leader>cd` | 行诊断信息 | n |
| `]d` / `[d` | 下/上一个诊断 | n |
| `]e` / `[e` | 下/上一个错误 | n |
| `]w` / `[w` | 下/上一个警告 | n |
| `<leader>cs` | 符号列表（Trouble） | n |
| `<leader>cS` | LSP 引用/定义（Trouble） | n |

### LSP 命令（命令模式）

| 命令 | 功能 |
|------|------|
| `:lsp restart clangd` | 重启 clangd |
| `:lsp restart` | 重启所有 LSP |
| `:lsp enable <server>` | 启动 LSP（替代 `:LspStart`） |
| `:lsp disable <server>` | 停止 LSP（替代 `:LspStop`） |
| `:lsp log` | 查看 LSP 日志 |

## 诊断与 Quickfix

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<leader>xx` | 诊断列表（Trouble） | n |
| `<leader>xX` | Buffer 诊断（Trouble） | n |
| `<leader>xL` | Location List（Trouble） | n |
| `<leader>xQ` | Quickfix List（Trouble） | n |
| `<leader>xt` | TODO 列表（Trouble） | n |
| `[q` / `]q` | 上/下一个 Quickfix | n |
| `[t` / `]t` | 上/下一个 TODO 注释 | n |

## Git

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<leader>gg` | Lazygit（项目根目录） | n |
| `<leader>gG` | Lazygit（当前目录） | n |
| `<leader>gl` | Git 日志 | n |
| `<leader>gL` | Git 日志（当前目录） | n |
| `<leader>gb` | Git 当前行 blame | n |
| `<leader>gf` | Git 当前文件历史 | n |
| `<leader>gB` | Git Browse（浏览器打开） | n, x |
| `]h` / `[h` | 下/上一个 hunk | n |
| `]H` / `[H` | 最后/第一个 hunk | n |
| `<leader>ghs` | 暂存 hunk | n, x |
| `<leader>ghr` | 重置 hunk | n, x |
| `<leader>ghS` | 暂存整个 buffer | n |
| `<leader>ghu` | 撤销暂存 hunk | n |
| `<leader>ghR` | 重置整个 buffer | n |
| `<leader>ghp` | 预览 hunk | n |
| `<leader>ghd` | Diff This | n |
| `ih` | 选择 hunk（文本对象） | o, x |

## Snacks Explorer（文件浏览器）

| 快捷键 | 功能 |
|--------|------|
| `l` | 进入目录 / 打开文件 |
| `h` | 折叠目录 |
| `<BS>` | 跳到上级目录 |
| `.` | 聚焦当前目录为根目录 |
| `Z` | 折叠所有目录 |
| `a` | 新建文件/目录 |
| `d` | 删除文件 |
| `r` | 重命名 |
| `c` | 复制文件 |
| `m` | 移动文件 |
| `y` | 复制路径 |
| `p` | 粘贴 |
| `o` | 用系统应用打开 |
| `H` | 切换隐藏文件显示 |
| `I` | 切换 gitignore 文件显示 |
| `P` | 切换预览 |
| `<leader>/` | Grep 搜索当前目录 |
| `<c-t>` | 打开终端 |
| `]g` / `[g` | 下/上一个 git 修改文件 |

## Flash（快速跳转）

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `s` | Flash 跳转 | n, x, o |
| `S` | Flash Treesitter 选择 | n, o, x |
| `r` | 远程 Flash | o |
| `R` | Treesitter 搜索 | o, x |
| `<C-s>` | 切换 Flash 搜索 | c |

## Treesitter 文本对象 (mini.ai)

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `af` / `if` | 函数 外部/内部 | o, x |
| `ac` / `ic` | 类 外部/内部 | o, x |
| `ao` / `io` | 代码块 外部/内部 | o, x |
| `au` / `iu` | 函数调用 外部/内部 | o, x |
| `at` / `it` | 标签 外部/内部 | o, x |
| `ad` / `id` | 数字 外部/内部 | o, x |
| `ag` / `ig` | Buffer 外部/内部 | o, x |

## UI 切换

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<leader>uf` | 切换自动格式化 | n |
| `<leader>us` | 切换拼写检查 | n |
| `<leader>uw` | 切换自动换行 | n |
| `<leader>ul` | 切换行号 | n |
| `<leader>uL` | 切换相对行号 | n |
| `<leader>ud` | 切换诊断显示 | n |
| `<leader>uh` | 切换 Inlay Hints | n |
| `<leader>uc` | 切换隐藏级别 | n |
| `<leader>uT` | 切换 Treesitter 高亮 | n |
| `<leader>ub` | 切换深色/浅色背景 | n |
| `<leader>un` | 关闭所有通知 | n |
| `<leader>uG` | 切换 Git Signs | n |

## 终端与实用工具

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<leader>ft` | 终端（项目根目录） | n |
| `<leader>fT` | 终端（当前目录） | n |
| `<C-/>` | 切换终端 | n, t |
| `<leader>qq` | 退出所有 | n |
| `<leader>l` | Lazy 插件管理器 | n |
| `<leader>L` | LazyVim 更新日志 | n |
| `<leader>?` | 显示快捷键帮助（which-key） | n |
| `<leader>ui` | 检查光标位置信息 | n |
| `<leader>ur` | 重绘 / 清除搜索 / 更新 Diff | n |

## tmux 集成

| 快捷键 | 功能 | 模式 |
|--------|------|------|
| `<C-h>` | 向左导航（tmux ↔ nvim 无缝） | n |
| `<C-j>` | 向下导航（tmux ↔ nvim 无缝） | n |
| `<C-k>` | 向上导航（tmux ↔ nvim 无缝） | n |
| `<C-l>` | 向右导航（tmux ↔ nvim 无缝） | n |

---

**模式说明**: n=普通, v=可视, i=插入, x=选择, o=操作符等待, c=命令, t=终端
