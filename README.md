# mail-to-calendar-skill

> 读邮箱（IMAP，只读）里带时间信息的邮件，抽成日程写进 Mac 日历的 agent skill：面试通知、笔试、报名截止、会议、航班、账单到期。

## 这是什么

[apple-calendar-skill](https://github.com/DAweiD1/apple-calendar-skill) 的配套 skill。分工是：

- **这个 skill**：从邮箱里把「什么时候要做什么」捞出来，判断哪些还没过期。
- **apple-calendar-skill**：把确定的事件写进日历，写完读回校验。

两个加起来，一句「看看我邮箱里最近有什么要办的」就能落到手机日历上。

## 设计取向

**只读，而且刻意只读。** 脚本用 `SELECT readonly=True` + `BODY.PEEK[]`，连「标记已读」都不会发生。你邮箱里发生什么事，都该由你自己决定，agent 只负责看。

**默认不全量输出。** 拉 7 天邮件可能上百封，全塞进上下文既慢又贵。脚本只把命中时间类关键词（面试、截止、航班、会议……）或带 `.ics` 附件的邮件交出来，其余只计数。

**凭据只在一个文件里，只被脚本读。** 不进 git、不进对话、不写进日历。备注里也不会出现考试口令、准考证号这类东西——那些跟着 iCloud 同步到所有设备不合适。

## 环境要求

- Python 3.6+（macOS 自带的就够）
- 写日历那一步需要 macOS + [apple-calendar-skill](https://github.com/DAweiD1/apple-calendar-skill)

## 安装

```bash
# 1) 先装日历那半边
git clone https://github.com/DAweiD1/apple-calendar-skill.git
cd apple-calendar-skill && bash scripts/build.sh && bash scripts/install.sh

# 2) 再装这个
git clone https://github.com/DAweiD1/mail-to-calendar-skill.git
cd mail-to-calendar-skill && bash scripts/install.sh
```

## 配置（三步）

```bash
# 1) 建配置目录
mkdir -p ~/.config/mail-to-calendar && chmod 700 ~/.config/mail-to-calendar

# 2) 复制模板（装了 skill 的话模板已经在）
cp config.example.txt ~/.config/mail-to-calendar/account.txt

# 3) 编辑，填 user 和 password
nano ~/.config/mail-to-calendar/account.txt
chmod 600 ~/.config/mail-to-calendar/account.txt
```

文件长这样：

```
user = your-address@163.com
password = 你的授权码
```

`password` 填的是**授权码**，不是登录密码：

| 邮箱 | 哪里拿授权码 |
|---|---|
| 163 / 126 / 188 | 网页版 → 设置 → POP3/SMTP/IMAP → 开启 IMAP → 生成授权码 |
| QQ / 腾讯企业邮 | 设置 → 账户 → POP3/IMAP 服务 → 开启并生成 |
| Gmail | 先开两步验证，再生成「应用专用密码」 |
| Outlook | 用应用密码，`host = outlook.office365.com` |
| 公司企业邮 | `host` 改成 IT 给的 IMAP 地址，例如 `imap.qiye.163.com` |

`host` / `port` / `folder` 一般不用填，脚本会按邮箱域名自动选服务器。

验证：

```bash
~/.agents/skills/mail-to-calendar/bin/mail check
```

看到「连接成功」和邮件数就通了。

## 用法

```bash
MAIL=~/.agents/skills/mail-to-calendar/bin/mail

$MAIL check                          # 账号连通性
$MAIL fetch --days 7                 # 人看的摘要
$MAIL fetch --days 7 --json          # 给 agent / 其他程序用
$MAIL fetch --days 30 --limit 40     # 放宽窗口、控制规模
$MAIL fetch --no-filter              # 不做关键词过滤，全给
```

`fetch --json` 的结构：

```json
{
  "ok": true,
  "account": "xxx@163.com",
  "days": 7,
  "scanned": 22,
  "matched": 18,
  "messages": [
    { "uid": "…", "date": "2026-11-06T19:17:58+08:00",
      "from": "…", "subject": "…", "ics": [], "text": "…" }
  ]
}
```

## 给 agent 用

把仓库放进 `~/.agents/skills/mail-to-calendar/`，`SKILL.md` 会被自动发现。里面写死了工作流：先 `check`，再 `fetch`，判断哪些没过期，出确认表，交给 apple-calendar 写入。

## 隐私与安全

说清楚代价，别装看不见：

- **凭据**只存在 `~/.config/mail-to-calendar/account.txt`（`chmod 600`），脚本读它登录，任何输出里都不会出现。
- **邮件正文会进入 agent 的上下文**。这是抽日程的必然代价——不读正文就不知道日期。介意的话，别把 agent 指向工作邮箱。
- 脚本**不会**标记已读、删除、转发、发信。它只有 `SELECT`、`SEARCH`、`FETCH`。
- 授权码随时可以在邮箱网页端重新生成，旧的立刻失效。

## 已知限制

- `.ics` 附件目前只识别文件名、不解析内容（下一步的事）。
- 关键词过滤是字面匹配，冷门措辞可能漏。
- 不做增量（每次重扫窗口内全部邮件），邮件量特别大的账号要自己调 `--limit`。

## License

MIT，见 [LICENSE](./LICENSE)。
