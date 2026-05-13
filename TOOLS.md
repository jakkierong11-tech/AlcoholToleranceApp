# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## 🤖 Discord Bot 用户 ID 映射

**互相 @ 时必须用 `<@ID>` 格式，不能用纯文本 `@名字`。纯文本不会触发通知，对方收不到。**

| Bot 名称 | Agent | Discord 用户 ID | @ 格式 |
|----------|-------|----------------|--------|
| @jakkierong11_openclawbot | 🔧 main | 1502893673531183306 | `<@1502893673531183306>` |
| @首席架构设计师 | 🎨 designer | 1502992127456706710 | `<@1502992127456706710>` |
| @开发工程师 | 💻 developer | 1502995946089484449 | `<@1502995946089484449>` |
| @测试工程师 | 🧪 tester | 1502996847982153870 | `<@1502996847982153870>` |
| @代码审查工程师 | 🔍 reviewer | 1502997357694812311 | `<@1502997357694812311>` |

**规则：只要在 Discord 消息里写 `<@1502992127456706710>`，Discord 就会渲染成蓝色可点击的 @首席架构设计师，对方会收到通知。**

## 🔄 Bot 互 @ 重试协议

当 bot A @ bot B 分配任务时，按以下规则处理超时：

1. **第一次 @**：发送 `<@botB_ID> 任务内容`，等待 30 秒
2. **第二次 @**：若 30 秒无回复，再 @ 一次（同样的 `<@ID>` 格式）
3. **上报老板**：连续 2 次 @ 都没唤醒，bot A 私信老板 `<@1493580333046698135>` 说 "botB（名称）好像挂了，@ 了两次都没回应"

**老板 Discord ID：** `1493580333046698135`（私信用 `<@1493580333046698135>` 格式）
