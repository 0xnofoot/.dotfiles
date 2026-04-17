# 安装脚本更新 SOP

当配置发生变更时（新增/删除应用、增减依赖等），按以下流程更新相关文件。

## 涉及文件

| 文件 | 作用 |
|------|------|
| `Brewfile` | Homebrew 依赖声明，`brew bundle` 读取此文件安装所有包 |
| `<app>/.config.sh` | 各应用的配置链接与特有操作脚本，由 install.sh Step 4 自动扫描调用 |
| `install.sh` | 安装入口，Step 1-3 准备环境，Step 4 扫描 `.config.sh`，Step 5 安装字体 |

---

## 场景 1：新增应用（带配置目录）

> 示例：新增 starship prompt 配置

1. 在仓库根目录创建配置目录 `<app>/`，放入配置文件
2. **Brewfile**：添加 `brew "<app>"` 到对应分类下
3. **`<app>/.config.sh`**：创建链接脚本，遵循以下模板：

```bash
#!/bin/bash
set -e
# <app> 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/<app>"
ln -sfn "$DOTFILES_DIR/<app>" "$HOME/.config/<app>"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/<app>/" "<app>/"
```

4. **install.sh**：无需修改，Step 4 自动发现新脚本并调用

如果该应用需要非标准安装（如 Linux 上无 Homebrew formula），在 `.config.sh` 中添加安装逻辑，参见[场景 5](#场景-5应用需要非标准安装)。

---

## 场景 2：删除应用

1. **Brewfile**：删除对应的 `brew`/`cask` 行
2. **`<app>/.config.sh`**：删除（或保留配置目录但移除 `.config.sh`，则 Step 4 不再调用）
3. **install.sh**：无需修改
4. 配置目录本身是否从仓库删除，由维护者决定

---

## 场景 3：新增依赖（不带配置目录）

> 示例：某个配置文件引用了 `jq`，需要确保目标机器上安装

1. **Brewfile**：添加 `brew "<tool>"` 到对应分类下
2. **`<app>/.config.sh`** 和 **install.sh**：无需改动

仅 macOS 需要：`brew "<tool>", condition: -> { OS.mac? }`；仅 Linux 需要：`brew "<tool>", condition: -> { OS.linux? }`

---

## 场景 4：删除依赖

1. **Brewfile**：删除对应行
2. 其他文件无需改动

---

## 场景 5：应用需要非标准安装

当某个应用在 Linux 上没有 Homebrew formula，或安装本身是可选的，在其 `.config.sh` 中添加安装逻辑。

kitty 已采用可选安装模式，默认跳过，仅 `--with-kitty` 参数启用。参照此模式在 `<app>/.config.sh` 中添加：

```bash
# 可选安装（--with-<app> 时 INSTALL_APP=yes）
if [[ "${INSTALL_APP:-}" == "yes" ]]; then
  if ! command -v <app> &>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      printf "  \033[33m%s\033[0m\n" "通过 Homebrew 安装 <app>..."
      brew install --cask <app>
    else
      printf "  \033[33m%s\033[0m\n" "通过官方脚本安装 <app> (Linux)..."
      # 平台特殊安装逻辑
    fi
  fi
fi
```

同时在 install.sh 顶部的参数解析处添加对应 flag 并 export：

```bash
--with-<app>) INSTALL_APP=yes ;;
```

```bash
export INSTALL_APP
```

---

## 场景 6：应用需要根级 symlink

部分应用的配置文件需要同时出现在 `~/` 根目录（如 zsh 需要 `~/.zshrc`）。

在该应用的 `.config.sh` 中，于整目录链接之后追加根级链接（直接删除旧文件，无需备份）：

```bash
rm -f "$HOME/.<rc>"
ln -sfn "$DOTFILES_DIR/<app>/<rc>" "$HOME/.<rc>"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.<rc>" "<app>/<rc>"
```

---

## 场景 7：应用配置不走 ~/.config（如 claude）

部分应用的配置目录不在 `~/.config/` 下，或只需逐文件链接（保留目标目录中的运行时数据）。

参照 `claude/.config.sh` 的模式：不链接整目录，手动维护受管条目列表，逐项 `rm -rf` + `ln -sfn`。

---

## 场景 8：应用配置需链接到特定平台路径（如 vscode）

部分应用的配置文件需要直接链接到应用自身的用户目录（macOS/Linux 路径不同），而非 `~/.config/`。

参照 `vscode/.config.sh` 的模式：
- 检测目标目录是否存在（不存在则跳过）
- macOS 和 Linux 分别定义路径数组
- 存在则逐文件 `rm -rf` + `ln -sfn`，并输出链接信息
- 所有目录均不存在时输出黄色跳过提示

---

## 场景 9：管理 VSCode / Cursor 扩展

扩展列表存放在 `vscode/extensions/` 目录下：

| 文件 | 内容 |
|------|------|
| `shared.txt` | Code 和 Cursor 共享的扩展 |
| `code.txt` | Code 独有扩展 |
| `cursor.txt` | Cursor 独有扩展 |

**新增扩展**：在编辑器中安装后，运行 `bash vscode/scripts/sync-extensions.sh` 自动同步。

**删除扩展**：在编辑器中卸载后，运行 `bash vscode/scripts/sync-extensions.sh` 自动同步（会提示移除已卸载项）。

**pre-commit hook**（`.githooks/pre-commit`，install.sh Step 4 配置 `core.hooksPath`）：
- 每次提交自动检查扩展列表是否同步；无 code/cursor CLI 时跳过检查，不阻断提交
- 若 `vscode/default-keybindings/` 有暂存变更，同时检查禁用快捷键列表是否一致
- 检查不通过时交互式询问：输入 `y` 自动修复并加入本次提交，输入 `n` 阻止提交

**vscode/.config.sh** 自动检测 `code`/`cursor` CLI，均未找到时跳过；找到时增量安装扩展列表中尚未安装的扩展。

---

## 修改后检查清单

每次修改完成后，逐项确认：

- [ ] Brewfile 中包名是 Homebrew 实际 formula 名（`brew info <name>` 可验证）
- [ ] 新增应用已创建 `.config.sh`，且首行 `#!/bin/bash`、次行 `set -e`
- [ ] 如果增减了 install.sh 的步骤，所有 `"Step N/5"` 的分母已同步更新，并更新 CLAUDE.md 中的步骤表格
- [ ] `bash -n install.sh` 和各 `.config.sh` 语法检查通过
- [ ] macOS 特有逻辑用 `[[ "$(uname)" == "Darwin" ]]` 保护
- [ ] Linux 特有逻辑用 `[[ "$(uname)" != "Darwin" ]]` 保护

---

## Brewfile 分类约定

```ruby
# Shell        — shell 本身（zsh）
# Core Apps    — 带配置目录的核心应用（neovim, tmux, yazi）
# CLI Tools    — 配置中引用的命令行工具（fzf, fd, ripgrep, bat, eza ...）
# Media        — 媒体相关工具（mpv）
# Platform     — 平台相关（kitty cask、xclip 等带 OS 条件的包）
```

新增包时放入对应分类；如果不确定归类，优先放 CLI Tools。
