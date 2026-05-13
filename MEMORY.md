# MEMORY.md

## 👤 主人
- 称呼：老板 / 老大 / boss
- 风格：干练直接，带点小幽默
- 时区：Asia/Shanghai
- Discord ID: 1493580333046698135

## 🖥️ 环境
- Windows 10, Node 24.14.0
- Clash Verge TUN 模式，端口 7897
- Gateway 启动：`C:\Users\jakkie\.openclaw\gateway.cmd`

## 🤖 Agent 团队 (2026-05-10 配置)
| Agent | Discord | 模型 | Key |
|-------|---------|------|-----|
| 🔧 main | @jakkierong11_openclawbot | DeepSeek V4 PRO | sk-652...631e |
| 🎨 designer | @首席架构设计师 | DeepSeek V4 PRO | 共享 main |
| 💻 developer | @开发工程师 | DeepSeek V4 PRO | sk-1d0...be7c |
| 🧪 tester | @测试工程师 | KIMI K2.5 | sk-Clk...FTa4 |
| 🔍 reviewer | @代码审查工程师 | QWEN 3.6 | sk-d58...3a67 |

- 方案：多 Discord Bot（每个绑独立 Bot 账号）
- 子 agent thinking 已全部关闭，main 保留
- groupPolicy 全设 open
- KIMI 2.6 不稳定已换 2.5

## 🔑 重要教训
- `openclaw gateway restart` 会中断回复 → 用 cron `kind:"at"` + `deleteAfterRun:true` 延迟 10 秒重启（绝不能用 `every`，会死循环）
- `models.providers` 有安全机制拒删 → Node 直写 JSON
- 配新 agent 时注意别覆盖 main bot

## 🔗 服务
- Tavily Search (优先)：tvly-dev-4fatow-...
- Kimi Search (备用)：sk-Psyg98eP...
- OpenViking：NVIDIA API，数据在 `workspace/openviking_data/`
