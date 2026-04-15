# 安装脚本更新 SOP

当配置发生变更时（新增/删除应用、增减依赖等），按以下流程更新安装脚本。

## 涉及文件

| 文件 | 作用 |
|------|------|
| `Brewfile` | Homebrew 依赖声明，brew bundle 读取此文件安装所有包 |
| `install.sh` | 安装入口，包含 `CONFIG_PACKAGES` 数组和九步安装流程 |

## 场景 1：新增应用（带配置目录）

> 示例：新增 starship prompt 配置

1. 在仓库根目录创建配置目录 `<app>/`，放入配置文件
2. **Brewfile**：添加 `brew "<app>"` 到对应分类下
3. **install.sh**：将 `<app>` 追加到 `CONFIG_PACKAGES` 数组（第 5 行）
4. 如果该应用在 Linux 上无法通过 Homebrew 安装（如 kitty），需在 Step 4 区域添加平台特殊安装逻辑（参见[场景 5](#场景-5应用需要非标准安装)）
5. 如果该应用需要 `~/.config/` 之外的 symlink（如 zsh 需要 `~/.zshrc`），需在 Step 6 区域添加对应逻辑（参见[场景 6](#场景-6应用需要根级-symlink)）

## 场景 2：删除应用

1. **Brewfile**：删除对应的 `brew`/`cask` 行
2. **install.sh**：从 `CONFIG_PACKAGES` 数组中移除
3. 如果该应用有平台特殊安装逻辑（Step 4 区域），一并删除
4. 如果该应用有额外 symlink 逻辑（Step 6 区域），一并删除
5. 配置目录本身是否从仓库删除，由维护者决定

## 场景 3：新增依赖（不带配置目录）

> 示例：某个配置文件引用了 `jq`，需要确保目标机器上安装

1. **Brewfile**：添加 `brew "<tool>"` 到对应分类下
2. **install.sh**：无需改动（brew bundle 会自动安装 Brewfile 中所有包）
3. 如果该工具仅 macOS 需要，使用 `brew "<tool>" if OS.mac?`；仅 Linux 需要则用 `if OS.linux?`

## 场景 4：删除依赖

1. **Brewfile**：删除对应行
2. **install.sh**：无需改动

## 场景 5：应用需要非标准安装

当某个应用在 Linux 上没有 Homebrew formula，或安装本身是可选的，需要单独处理。

kitty 已改为可选安装模式（Step 4），通过交互式提示或 `--with-kitty` / `--no-kitty` 参数控制。参照此模式，在 install.sh 的 Step 4 区域添加类似逻辑：

```bash
if command -v <app> &>/dev/null; then
  # 已安装，跳过
elif [[ "$(uname)" == "Darwin" ]]; then
  brew install --cask <app>
else
  # 平台特殊安装逻辑（curl 官方安装脚本等）
fi
```

如果应用从 Brewfile 中移除（改为可选），确保在 install.sh 中手动调用 `brew install`。

## 场景 6：应用需要根级 symlink

部分应用的配置文件不在 `~/.config/` 下，而是在 `$HOME` 根目录（如 `~/.zshrc`）。

参照 zsh 的模式，在 install.sh 的 Step 6 区域添加：

```bash
# 备份已有的非 symlink 文件
if [[ -e "$HOME/.<rc>" && ! -L "$HOME/.<rc>" ]]; then
  warn "Backing up .<rc> to .<rc>.bak"
  mv "$HOME/.<rc>" "$HOME/.<rc>.bak"
fi
ln -sfn "$HOME/.config/<app>/<rc>" "$HOME/.<rc>"
```

## 场景 7：应用配置路径因平台而异（如 vscode/cursor）

部分应用的配置虽然也链接到 `~/.config/<app>`，但还需将其中的文件链接到应用自身的用户配置目录（macOS/Linux 路径不同），且不需要脚本自动安装应用本体。

参照 vscode 的模式（install.sh Step 7）：
- 应用配置目录已通过 Step 5 链接到 `~/.config/`
- 检测目标应用目录是否存在（不存在则 skip）
- 存在则将 `~/.config/<app>/` 下的配置文件逐个 symlink 到应用用户目录
- macOS 和 Linux 使用不同的目标路径

## 修改后检查清单

每次修改完成后，逐项确认：

- [ ] Brewfile 中包名是 Homebrew 实际 formula 名（`brew info <name>` 可验证）
- [ ] `CONFIG_PACKAGES` 数组与仓库中实际存在的配置目录一致
- [ ] 如果增减了 install.sh 的步骤，所有 `"Step N/M"` 的分母已同步更新
- [ ] `bash -n install.sh` 语法检查通过
- [ ] macOS 特有逻辑用 `[[ "$(uname)" == "Darwin" ]]` 保护
- [ ] Linux 特有逻辑用 `[[ "$(uname)" != "Darwin" ]]` 保护

## Brewfile 分类约定

```ruby
# Shell        — shell 本身（zsh）
# Core Apps    — 带配置目录的核心应用（neovim, tmux, yazi）
# CLI Tools    — 配置中引用的命令行工具（fzf, fd, ripgrep, bat, eza ...）
# Media        — 媒体相关工具（mpv）
# Platform     — 平台相关（kitty cask、xclip 等带 OS 条件的包）
```

新增包时放入对应分类；如果不确定归类，优先放 CLI Tools。
