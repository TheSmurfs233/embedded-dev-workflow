#!/usr/bin/env bash
# ---------------------------------------------------------------
# new_project.sh —— 用本仓库的规范初始化一个新工程骨架
#
# 用法：
#   bash tools/new_project.sh <工程名> [目标目录]
#
#   <工程名>    会写进 STATUS.md / README.md 的标题（建议英文或拼音，无空格）
#   [目标目录]  默认 ./<工程名>
#
# 生成内容：
#   STATUS.md                          一页纸状态牌
#   README.md                          工程说明骨架
#   docs/00_开发日志.md                 追加式日志
#   docs/01_项目进度.md                 阶段表
#   docs/19_硬件资源与引脚映射.md        引脚/外设/中断
#   docs/38_踩坑清单.md                 现象→根因→规矩
#   test/doc_check.py                  文档一致性检查
#   test/verify.sh                     一条命令跑完检查
#   .gitattributes / .gitignore
#
# 不做什么：不建工程文件、不选芯片、不装工具链。
# 目标目录已存在且非空时默认拒绝（用 --force 覆盖）。
# ---------------------------------------------------------------
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

name="${1:-}"
if [ -z "$name" ]; then
    echo "用法: bash tools/new_project.sh <工程名> [目标目录]" >&2
    exit 2
fi

dst="${2:-$name}"
force=0
if [ "${3:-}" = "--force" ] || [ "${2:-}" = "--force" ]; then
    force=1
    [ "${2:-}" = "--force" ] && dst="$name"
fi

if [ -e "$dst" ] && [ -n "$(ls -A "$dst" 2>/dev/null || true)" ] && [ "$force" -ne 1 ]; then
    echo "ERR 目标目录已存在且非空: $dst" >&2
    echo "    换一个目录名，或加 --force 覆盖" >&2
    exit 3
fi

mkdir -p "$dst/docs" "$dst/test"

# ---------------- 生成文件 ----------------

cat > "$dst/.gitattributes" <<'EOF'
* text=auto
*.md   text eol=lf
*.py   text eol=lf
*.sh   text eol=lf
EOF

cat > "$dst/.gitignore" <<'EOF'
build/
*.o
*.d
*.elf
*.hex
*.bin
*.map
*.log
__pycache__/
EOF

cat > "$dst/README.md" <<EOF
# ${name}

> 一句话说明这个工程做什么、给谁用。

## 快速开始

\`\`\`bash
bash test/verify.sh     # 构建 + 主机测试 + 文档检查
\`\`\`

## 文档导航

| 想知道什么 | 看哪 |
|---|---|
| 现在做到哪、下一步做什么 | \`STATUS.md\` |
| 每个阶段怎么验收 | \`docs/01_项目进度.md\` |
| 某天做了什么、数据多少 | \`docs/00_开发日志.md\` |
| 引脚与外设 | \`docs/19_硬件资源与引脚映射.md\` |
| 踩过的坑 | \`docs/38_踩坑清单.md\` |

## 流程规范

开发流程见 \`workflow/\`（从流程仓库复制）。
EOF

cat > "$dst/STATUS.md" <<EOF
# STATUS · ${name}

> 最后更新：$(date +%Y-%m-%d) · 固件 #1 · 分支 \`main\`

## 做到哪（只写有证据的）

| 阶段 | 内容 | 状态 | 证据 |
|---|---|---|---|
| S0 | 工程能编译 | ⬜ | — |
| S1 | 底层自检 | ⬜ | — |
| S2 | 输出通道 | ⬜ | — |
| S3 | 采样通道 | ⬜ | — |

**当前能力一句话**：还没开始。

## 下一步（一次一件事）

1. 建工程、点灯、打印版本号

## 卡在哪（含已排除的猜测）

| 问题 | 现状 | 已排除 |
|---|---|---|

## 悬而未决（≤3 条）

| # | 事项 | 选项 | 倾向 |
|---|---|---|---|

## 提交前的三件套

- \`bash test/host/build.sh\` → \`failed: 0\`
- \`python test/doc_check.py\` → \`PASS\`
- 构建 → \`0 Error 0 Warning\`

## 文档导航

| 想知道什么 | 看哪 |
|---|---|
| 每个阶段怎么验收 | \`docs/01_项目进度.md\` |
| 数据和实验记录 | \`docs/00_开发日志.md\` |
| 引脚与外设 | \`docs/19_硬件资源与引脚映射.md\` |
| 踩过的坑 | \`docs/38_踩坑清单.md\` |
EOF

cat > "$dst/docs/00_开发日志.md" <<EOF
# 开发日志 · ${name}

> 只追加，不改旧条目。每条必须带数据。

---

## $(date +%Y-%m-%d) · 工程初始化

### 做了什么
- 用 \`tools/new_project.sh\` 生成骨架

### 数据
| 项 | 值 |
|---|---|
| 工具链版本 | |
| 目标芯片 | |
| Flash / RAM | |

### 下一步
- 建工程、点灯、打印版本号
EOF

cat > "$dst/docs/01_项目进度.md" <<EOF
# 项目进度 · ${name}

> 这是"现在做到哪"的唯一事实来源。

## 阶段表

| 阶段 | 内容 | 状态 | 验收标准 | 证据 | 固件 |
|---|---|---|---|---|---|
| S0 | 工程与自检 | ⬜ | 能编译、能打印版本号 | — | — |
| S1 | 输出通道 | ⬜ | 输出可测、无直通 | — | — |
| S2 | 采样通道 | ⬜ | 与仪表误差 < 1% | — | — |
| S3 | 开环驱动 | ⬜ | 能按指令动作 | — | — |
| S4 | 闭环控制 | ⬜ | 阶跃超调 < 5% | — | — |
| S5 | 保护与异常 | ⬜ | 每类保护都能触发一次 | — | — |
| S6 | 移植清单 | ⬜ | 换器件只改参数 | — | — |

## 已知的取舍

| 决策 | 选择 | 原因 |
|---|---|---|
EOF

cat > "$dst/docs/19_硬件资源与引脚映射.md" <<EOF
# 硬件资源与引脚映射 · ${name}

## 1. 主控与外设

| 项 | 值 | 备注 |
|---|---|---|
| 芯片型号 | | |
| 主频 | | |
| 调试口 | | |

## 2. 引脚分配

| 引脚 | 功能 | 复用/模式 | 备注 |
|---|---|---|---|
| | | | |

## 3. 中断与优先级

| 中断 | 优先级 | 周期/触发 | 说明 |
|---|---|---|---|
| | | | |

## 4. 时钟与总线

| 总线 | 频率 | 用途 |
|---|---|---|
| | | |

## 5. 冲突记录

| 冲突 | 结论 | 处理 |
|---|---|---|
EOF

cat > "$dst/docs/38_踩坑清单.md" <<EOF
# 踩坑清单 · ${name}

> 每条：现象 → 根因 → 现在的规矩 → 出处。
> 只记"花了 30 分钟以上才想明白"的。

---

## 0. 只记这五条

1. 判据用物理不变量，不用会随工况漂移的量
2. 先测量再修改：加仪表抓失败那一刻的数据
3. 帧计数与好帧计数分开统计
4. 故障/停机后必须把状态机彻底复位
5. 换 shell 就换编译器——先看脚本打印的 \`env:\`

---

## 1. 判据与验证

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

## 2. 状态机与模式

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

## 3. 参数与单位

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

## 4. 采样与硬件

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

## 5. 控制环

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

## 6. 工具链与环境

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

## 7. 文档与流程

| # | 现象 | 根因 | 现在的规矩 | 出处 |
|---|---|---|---|---|

---

## 待验证的可疑点

| # | 猜测 | 迹象 | 如何验证 |
|---|---|---|---|
EOF

cp "$SRC/tools/doc_check.py" "$dst/test/doc_check.py"

cat > "$dst/test/verify.sh" <<'EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------
# verify.sh —— 一条命令跑完能自动化的检查
#
#   bash test/verify.sh
#
# 只认输出里的结果标记，不认退出码：
# 某些 IDE/包装脚本会把子进程的退出码吃掉或改成 1。
#
# 退出码：0 全过 / 1 有失败
# ---------------------------------------------------------------
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

log="$(mktemp -d)"
fails=0
note() { printf '%s\n' "$*"; }

# 选一个可用的 python（doc_check.py 只需要标准库）
PY=""
for c in python3 python py; do
    if command -v "$c" >/dev/null 2>&1; then PY="$c"; break; fi
done

# ---- 1/3 主机测试 ----
if [ -f test/host/build.sh ]; then
    note "[1/3] 主机测试 (test/host/build.sh)"
    if bash test/host/build.sh > "$log/host.log" 2>&1; then
        if grep -Eq 'failed:[[:space:]]*[1-9]' "$log/host.log"; then
            note "       FAIL（输出里有失败计数）"; fails=$((fails+1))
        elif grep -q 'RESULT: PASS' "$log/host.log"; then
            note "       PASS"
        else
            note "       PASS（退出码 0，未见失败计数）"
        fi
    else
        note "       FAIL（退出码非 0）"; fails=$((fails+1))
        tail -20 "$log/host.log"
    fi
else
    note "[1/3] 主机测试 —— 跳过（没有 test/host/build.sh）"
fi

# ---- 2/3 文档检查 ----
if [ -f test/doc_check.py ]; then
    note "[2/3] 文档检查 (test/doc_check.py)"
    if [ -z "$PY" ]; then
        note "       FAIL（找不到 python3 / python）"; fails=$((fails+1))
    elif $PY test/doc_check.py > "$log/doc.log" 2>&1; then
        if grep -q 'RESULT: PASS' "$log/doc.log"; then
            note "       PASS"
        else
            note "       FAIL（没有出现 RESULT: PASS）"; fails=$((fails+1))
            tail -20 "$log/doc.log"
        fi
    else
        note "       FAIL（退出码非 0）"; fails=$((fails+1))
        tail -20 "$log/doc.log"
    fi
else
    note "[2/3] 文档检查 —— 跳过（没有 test/doc_check.py）"
fi

# ---- 3/3 固件构建（无法通用，只提醒）----
note "[3/3] 固件构建 —— 需要手动跑"
note "      必须 0 Error 0 Warning，并把体积记进 docs/31 或 01"

note ""
if [ "$fails" -eq 0 ]; then
    note "RESULT: PASS（自动检查全过，别忘了第 3 步）"
    exit 0
else
    note "RESULT: FAIL（$fails 项）"
    exit 1
fi
EOF

chmod +x "$dst/test/verify.sh" 2>/dev/null || true

# ---------------- 自检 ----------------
chk="$(python3 "$dst/test/doc_check.py" 2>&1 || python "$dst/test/doc_check.py" 2>&1 || true)"
if printf '%s' "$chk" | grep -q 'RESULT: PASS'; then
    echo "OK  骨架已生成并通过文档检查: $dst"
else
    echo "WARN 骨架已生成，但文档检查未通过，请检查:" >&2
    printf '%s\n' "$chk" | tail -10 >&2
fi

cat <<EOF

下一步：
  cd $dst
  git init -b main
  git add -A && git commit -m "chore: 初始化工程骨架"
  # 然后按流程仓库的 08_新工程落地清单.md 逐项打钩
  # （若已把流程仓库复制到本工程的 workflow/，则是 workflow/08_新工程落地清单.md）
EOF
