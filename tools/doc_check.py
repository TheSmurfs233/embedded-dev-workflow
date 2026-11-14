#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""通用文档一致性检查（与具体工程无关）。

用法（在仓库根目录，或任意位置都行）：

    python tools/doc_check.py            # 检查本仓库所有 *.md
    python tools/doc_check.py docs/      # 只查某个目录
    python tools/doc_check.py --quiet    # 只报错误，不列通过项

它只做**能机械判定**的事，判断"这段话还准不准"仍得靠人：

  硬错误（退出码 1）
    1. 乱码：文中出现 U+FFFD（文件被错误编码写过）
    2. 表格行没以 | 收尾（一行表格被拆成两行）
    3. 表格列数与表头不一致（多半是单元格里写了裸 |）
    4. 代码块围栏 ``` 不成对（少写或多写一个，后面全乱）
    5. 文件不以换行结尾（git diff 会显示 "\\ No newline"，合并时容易粘连）

  警告（退出码仍为 0）
    6. 出现 CRLF（Markdown 混用换行，跨平台协作时表格容易错位）
    7. 同一文件里出现重复标题（复制粘贴整段留下的痕迹）

为什么不检查"内容对不对"：那是人的工作。检查器负责的是
**那些一旦错了就必然误导读者、而人又一定会漏看的事情**。
工程专属的检查（版本号 / 帮助行数 / 通道数）加在自己的项目里，
本文件刻意不依赖任何工程宏。
"""

import glob
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL_SPLIT = re.compile(r'(?<!\\)\|')

errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def read(path):
    with open(path, 'r', encoding='utf-8', errors='replace', newline='') as f:
        return f.read()


def table_cells(line):
    """| a | b |  -> 2 ；忽略被反斜杠转义的 \\|"""
    parts = CELL_SPLIT.split(line)
    return len(parts) - 2


def check_file(path, rel):
    raw = read(path)

    # 1. 乱码
    for n, line in enumerate(raw.splitlines(), 1):
        if '\ufffd' in line:
            err('%s:%d 乱码 U+FFFD' % (rel, n))

    # 5. 结尾换行
    if raw and not raw.endswith('\n'):
        err('%s 文件末尾没有换行' % rel)

    # 6. CRLF
    if '\r\n' in raw:
        warn('%s 含 CRLF 换行（建议统一 LF）' % rel)

    # 4. 围栏配对（按行首计数，避免把行内 ``` 算进去）
    fences = sum(1 for l in raw.splitlines() if l.strip().startswith('```'))
    if fences % 2:
        err('%s 代码块围栏不成对（``` 出现 %d 次）' % (rel, fences))

    # 2/3. 表格结构
    in_fence = False
    header = None
    heading_line = {}
    for n, line in enumerate(raw.splitlines(), 1):
        text = line.strip()
        if text.startswith('```'):
            in_fence = not in_fence
            header = None
            continue
        if in_fence:
            continue

        # 7. 重复标题
        if text.startswith('#'):
            title = re.sub(r'^#+\s*', '', text)
            if title in heading_line:
                warn('%s:%d 重复标题"%s"（首次出现在第 %d 行）'
                     % (rel, n, title[:40], heading_line[title]))
            else:
                heading_line[title] = n
            header = None
            continue

        if not text.startswith('|'):
            header = None
            continue
        if len(text) > 2 and not text.endswith('|'):
            err('%s:%d 表格行没以 | 收尾' % (rel, n))
            continue
        cols = table_cells(text)
        if header is None:
            header = cols
        elif cols != header:
            err('%s:%d 表格有 %d 列，表头是 %d 列（单元格里的裸 | 要写成 \\|）'
                % (rel, n, cols, header))


def main(argv):
    quiet = '--quiet' in argv
    targets = [a for a in argv[1:] if not a.startswith('-')]
    if targets:
        base = os.path.abspath(targets[0])
    else:
        base = ROOT

    files = sorted(glob.glob(os.path.join(base, '**', '*.md'), recursive=True))
    files = [p for p in files if os.sep + '.git' + os.sep not in p]

    for path in files:
        check_file(path, os.path.relpath(path, base).replace('\\', '/'))

    print('doc_check: %d 个 markdown 文件' % len(files))
    if not quiet:
        print('doc_check: 检查项 = 乱码 / 表格结构 / 围栏配对 / 结尾换行 / CRLF / 重复标题')

    if warnings:
        print()
        print('--- 警告（建议人工看一眼）---')
        for w in warnings:
            print('  ' + w)

    if errors:
        print()
        print('--- 错误 ---')
        for e in errors:
            print('  ' + e)
        print()
        print('RESULT: FAIL（%d 个错误，%d 个警告）' % (len(errors), len(warnings)))
        return 1

    print()
    print('RESULT: PASS（%d 个警告）' % len(warnings))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
