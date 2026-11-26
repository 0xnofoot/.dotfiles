# deep-research 深度调研（on-demand）

> **触发条件**：用户要求「深度调研 / 深度研究 / deep research」某主题，或点名使用 hyperresearch。

hyperresearch = 本地 Python CLI + Claude Code skill 外壳：`/hyperresearch <问题>` 会按 16 步流水线做深度调研，所有来源与报告落盘到本目录 `research/` 知识库，可复用。

## 第一步：判断全局是否已安装

```bash
test -x "$HOME/.src-code/hyperresearch/.venv/bin/hyperresearch" -a -d "$HOME/.claude/skills/hyperresearch" && echo INSTALLED || echo NOT_INSTALLED
```

- **INSTALLED** → 无需安装。在任意项目目录里直接 `/hyperresearch <问题>`（或用户说「深度调研 X」）；首次在该项目运行时会自动创建该项目的 `.hyperresearch/`、`research/` 知识库与 16 个 step skills。
- **NOT_INSTALLED** → 按下面流程做一次全局安装（整台机器只需一次）。

## 自动安装流程（整机一次，全局生效）

源码 + venv 全局一份；入口 skill + 子代理装到 `~/.claude/`；之后所有项目直接 `/hyperresearch`，无需逐项目安装。

```bash
SRC="$HOME/.src-code/hyperresearch"   # 全局共享一份源码 + venv

# 1. 没有源码就先从 GitHub clone（首次 / 换机器才需要）
if [ ! -d "$SRC/.git" ]; then
  git clone https://github.com/0xnofoot/hyperresearch "$SRC"
fi

# 2. 建 uv 虚拟环境并装依赖（editable，改源码直接生效）
cd "$SRC"
test -x .venv/bin/hyperresearch || uv sync --extra crawl4ai

# 3. 全局安装入口 skill + 子代理（装到 ~/.claude/，一次全项目生效）
uv run hyperresearch install --global
```

装完后，在**任意项目**目录里 `/hyperresearch <问题>` 即可。首次在某项目运行时，会自动在该项目创建：

- `.hyperresearch/`（vault 配置 + 数据库）
- `research/`（知识库）
- 16 个 step skills（装进该项目的 `.claude/skills/`）

## fake-ip 白名单（每个项目首次运行后执行一次，幂等）

vault 是首次 `/hyperresearch` 运行时才生成的，所以白名单要在**该项目首次运行之后**、`config.toml` 存在时再注入。同内网若用 clash/tun 的 fake-ip DNS，所有域名解析到 `198.18.x.x` 保留网段，会被 SSRF 防护拒绝；放行该保留网段无任何副作用，可安全无条件执行：

```bash
if [ -f .hyperresearch/config.toml ]; then
python3 - <<'PYEOF'
import pathlib
p = pathlib.Path(".hyperresearch/config.toml")
s = p.read_text()
if "198.18.0.0/15" not in s:
    s = s.replace("allow_private_hosts = []", 'allow_private_hosts = ["198.18.0.0/15"]')
    p.write_text(s)
    print("injected fake-ip allowlist (198.18.0.0/15)")
else:
    print("fake-ip allowlist already present")
PYEOF
else
  echo "vault 尚未生成；首次 /hyperresearch 运行后再执行本段"
fi
```

## 抓取用浏览器（一次性全局，仅首次需要）

crawl4ai 本地抓取依赖反检测 Chromium。若抓取时报浏览器缺失：

```bash
cd "$HOME/.src-code/hyperresearch"
uv run python -m patchright install chromium
uv run python -m playwright install chromium
```

**系统依赖（换新机器必做，需要 sudo）**：Chromium 在 Linux 上还依赖一串系统库（libnss3/libnspr4/libatk/cups/gbm/pango/cairo 等约 78 个）。若抓取报
`error while loading shared libraries: libnspr4.so` / `libatk-1.0.so.0` 之类，用 Playwright 官方一次装全：

```bash
cd "$HOME/.src-code/hyperresearch"
uv run python -m playwright install-deps chromium
```

（提示 "your OS is not officially supported" 可忽略，它 fallback 用 ubuntu24.04 清单，依赖一样。）

装一次全局生效，之后所有项目共用。抓取 provider 默认即 `crawl4ai`（`[web] provider`），无需每项目修改。

## 更新 `~/.src-code/hyperresearch`

```bash
cd "$HOME/.src-code/hyperresearch"

# 拉自己 fork 的最新代码
git pull

# （可选）同步上游 jordan-gibbs/hyperresearch（首次先 add upstream）
# git remote add upstream https://github.com/jordan-gibbs/hyperresearch
# git fetch upstream && git merge upstream/main   # 冲突时手动解决，解决后 push 回 fork

# 依赖有变化才需要（跑一下无害）
uv sync --extra crawl4ai
```

更新后：

- 纯代码修复（不改 skill/agent 模板）→ editable 安装直接生效，无需动。
- 若上游改了**入口 skill / 子代理**模板 → 重跑 `uv run hyperresearch install --global` 刷新全局入口。
- 若上游改了 **16 个 step skills** 模板 → 各项目重跑 `uv run hyperresearch install --steps-only .` 刷新（或等该项目下次首次运行自动装）。
- 本地若自己改过源码，`git pull` 前先 commit / stash，否则可能冲突。

## 注意事项

- **`~/.src-code/hyperresearch` 不能删**：它是运行时引擎，调研时子代理每一步都在调里面的 `hpr`/`hyperresearch` 命令，删了 `/hyperresearch` 就跑不起来。`install --global` 只把「怎么调用它」写进 `~/.claude/`。
- 每个项目目录 = 独立知识库（`.hyperresearch/` + `research/`），互不影响；项目里没有 venv、没有源码副本。
- 首次在某项目运行 `/hyperresearch` 时，会向该项目根 `CLAUDE.md` **追加**一段带标记的内容，不覆盖现有文字（安全）。
- 换机器：在新机器上跑一次上面的全局安装流程即可（会自动 clone 到 `~/.src-code/hyperresearch`），之后所有项目直接 `/hyperresearch`。
- 搜索侧：fetcher 子代理的搜索已指向 search2ai MCP（`mcp__search2ai__search`），需确保 search2ai MCP 在会话中可用。
