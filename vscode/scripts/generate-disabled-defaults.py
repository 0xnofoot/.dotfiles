#!/usr/bin/env python3
"""
从 vscode/defaults/ 目录中的默认快捷键 JSON 生成完整禁用列表，更新 keybindings.json。

用法:
  python3 generate-disabled-defaults.py                    # 读取 vscode/defaults/*.json
  python3 generate-disabled-defaults.py /tmp/extra.json    # 额外追加指定文件

导出默认快捷键:
  在任意 VSCode 系编辑器中: Cmd+Shift+P > "Preferences: Open Default Keyboard Shortcuts (JSON)"
  全选复制，保存到 vscode/defaults/<编辑器名>.json（如 vscode.json、cursor.json）

脚本自动读取 vscode/defaults/ 下所有 .json 文件，合并去重后生成禁用条目。
命令行额外传入的文件也会一并合并。
"""

import json
import re
import sys
from pathlib import Path

MARKER = "//===== Auto Generated: Disabled Defaults =====//\n"
MARKER_NOTE = "  // 以下内容由 generate-disabled-defaults.py 自动生成，请勿手动编辑\n"

SCRIPT_DIR = Path(__file__).parent
VSCODE_DIR = SCRIPT_DIR.parent
DEFAULTS_DIR = VSCODE_DIR / "defaults"
KEYBINDINGS_FILE = VSCODE_DIR / "keybindings.json"


def strip_jsonc_comments(text: str) -> str:
    """移除 JSONC 中的 // 行注释，但保留字符串内的 //"""
    return re.sub(
        r'"(?:[^"\\]|\\.)*"|//.*',
        lambda m: m.group() if m.group().startswith('"') else "",
        text,
    )


def parse_jsonc(text: str) -> list:
    """解析 JSONC（带注释和尾逗号的 JSON）"""
    text = strip_jsonc_comments(text)
    text = re.sub(r",\s*([}\]])", r"\1", text)
    return json.loads(text)


def is_shortcut_key(key: str) -> bool:
    """判断按键是否为快捷键（应被禁用）。

    含 Ctrl/Cmd/Alt/Meta 修饰符或功能键 F1-F24 → 快捷键，需要禁用
    仅含基础按键（可带 Shift）→ 基础输入（回车、退格、方向键等），保留不动
    """
    for chord in key.split(" "):
        parts = [p.strip().lower() for p in chord.split("+")]
        if {"ctrl", "cmd", "alt", "meta"} & set(parts):
            return True
        base = parts[-1]
        if re.match(r"^f\d{1,2}$", base):
            return True
    return False


# 不应被禁用的基础命令（全选、复制、剪切、粘贴、撤销、重做等）
PRESERVE_COMMANDS = {
    "editor.action.selectAll",
    "execCopy",
    "execCut",
    "execPaste",
    "undo",
    "redo",
}


def generate_disable_entry(binding: dict) -> dict:
    """将一个默认绑定转为 - 禁用条目"""
    entry = {"key": binding["key"], "command": f"-{binding['command']}"}
    if binding.get("when"):
        entry["when"] = binding["when"]
    return entry


def _escape(s: str) -> str:
    """转义 JSON 字符串值中的特殊字符（\\、\"、\\n、\\t 等）"""
    return json.dumps(s, ensure_ascii=False)[1:-1]


def format_entry(entry: dict) -> str:
    """格式化单个条目为 JSONC 字符串"""
    parts = [
        f'    "key": "{_escape(entry["key"])}"',
        f'    "command": "{_escape(entry["command"])}"',
    ]
    if "when" in entry:
        parts.append(f'    "when": "{_escape(entry["when"])}"')
    return "  {\n" + ",\n".join(parts) + "\n  }"


def collect_input_files(extra_args: list[str]) -> list[Path]:
    """收集输入文件：defaults/ 目录 + 命令行参数"""
    files = sorted(DEFAULTS_DIR.glob("*.json")) if DEFAULTS_DIR.is_dir() else []
    for arg in extra_args:
        p = Path(arg)
        if not p.exists():
            print(f"错误: 文件不存在: {p}")
            sys.exit(1)
        files.append(p)
    return files


def build_disabled_content(input_files: list[Path], above: str) -> tuple[str, int]:
    """解析输入文件，生成完整的 keybindings.json 内容。返回 (内容, 禁用条目数)"""
    seen = set()
    disable_entries = []
    for f in input_files:
        defaults = parse_jsonc(f.read_text(encoding="utf-8"))
        for binding in defaults:
            if "key" not in binding or "command" not in binding:
                continue
            key = (binding["key"], binding["command"], binding.get("when", ""))
            if key in seen:
                continue
            seen.add(key)
            if not is_shortcut_key(binding["key"]):
                continue
            if binding["command"].startswith("extension.vim_"):
                continue
            if binding["command"] in PRESERVE_COMMANDS:
                continue
            disable_entries.append(generate_disable_entry(binding))

    entries_str = ",\n".join(format_entry(e) for e in disable_entries)
    new_content = above + MARKER + MARKER_NOTE + entries_str + "\n]\n"
    return new_content, len(disable_entries)


def main():
    check_mode = "--check" in sys.argv
    args = [a for a in sys.argv[1:] if a not in ("-h", "--help", "--check")]

    if "--help" in sys.argv or "-h" in sys.argv:
        print(__doc__.strip())
        sys.exit(0)

    input_files = collect_input_files(args)

    if not input_files:
        if check_mode:
            sys.exit(0)  # 没有 defaults 文件，无需检查
        print("错误: 未找到任何默认快捷键文件")
        print(f"  请将导出的 JSON 放入 {DEFAULTS_DIR}/")
        sys.exit(1)

    if not KEYBINDINGS_FILE.exists():
        print(f"错误: keybindings.json 不存在: {KEYBINDINGS_FILE}")
        sys.exit(1)

    content = KEYBINDINGS_FILE.read_text(encoding="utf-8")
    marker_line = "//===== Auto Generated: Disabled Defaults =====//";
    marker_idx = content.find(marker_line)

    if marker_idx == -1:
        print(f"错误: keybindings.json 中未找到标记行:")
        print(f"  {marker_line}")
        sys.exit(1)

    above = content[:marker_idx]
    new_content, count = build_disabled_content(input_files, above)

    # --check 模式：对比内容，不写入
    if check_mode:
        if new_content != content:
            print(f"keybindings.json 中的禁用列表与 defaults/ 不一致")
            print(f"  请运行: python3 vscode/scripts/generate-disabled-defaults.py")
            sys.exit(1)
        sys.exit(0)

    # 正常模式：打印信息并写入
    for f in input_files:
        defaults = parse_jsonc(f.read_text(encoding="utf-8"))
        print(f"  {f.name}: {len(defaults)} 个快捷键")
    print(f"去重后 {count} 个禁用条目")

    KEYBINDINGS_FILE.write_text(new_content, encoding="utf-8")
    print(f"已更新 keybindings.json")


if __name__ == "__main__":
    main()
