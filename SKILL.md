---
name: mail
description: 用 IMAP 只读访问用户邮箱——按时间、发件人、关键词、未读、附件检索，读正文、下载附件、存成文件；也能把邮件里的时间信息整理进日历。当用户说「看看我邮箱」「最近有什么邮件」「总结一下这周邮件」「找找谁发的什么」「最近有哪些事要办」「把邮件里的日期加到日历」时使用。
---

# 邮箱

只读访问 IMAP 邮箱：检索、阅读、导出、下载附件。把邮件里的日期落到日历，是这个工具上的一条配方，不是它的全部。

## 铁律

1. **只读。** 不要绕过脚本去发信、删信、改已读状态。
2. **先列表，后读正文。** `search` 很便宜，`read` 会把正文塞进上下文。不要一上来就 `read` 十封。
3. **不复述凭据。** 配置文件里的账号密码不进回复、不进笔记、不写进日历。
4. 用户没说时间范围时，默认最近 7 天，并在回复里说明这个口径。

## 工具

```bash
MAIL=~/.agents/skills/mail/bin/mail
```

配置在 `~/.config/mail/account.txt`。要不要读它？**不要**，除非用户让你帮他检查配置格式；即便读也不要复述内容。

## 命令

| 命令 | 作用 | 关键参数 |
|---|---|---|
| `check` | 连通性、文件夹里的邮件数 | `--json` |
| `folders` | 列出文件夹（中文名已解码） | `--json` |
| `search` | 邮件列表，**不含正文** | 见下 |
| `read` | 读正文 | `--uid 351,352` `--chars 2000` `0` 表示全文 |
| `save` | 存成 `.md` 或 `.eml` | `--uid 351 --out 路径` |
| `attach` | 下载附件到目录 | `--uid 351 --out ./attachments` |

`search` 的过滤条件可以组合：

```bash
$MAIL search --since 7d                      # 最近 7 天
$MAIL search --since 2026-11-01 --before 2026-11-30
$MAIL search --sender citics                 # 发件人包含
$MAIL search --subject 面试                   # 主题包含
$MAIL search --query 准考证                   # 全文包含（中文走本地过滤）
$MAIL search --unread                        # 只看未读
$MAIL search --attachment                    # 只看带附件的
$MAIL search --match-any "截止,面试,航班"      # 命中任意一个词
$MAIL search --limit 50 --json               # 要结构化结果时
```

## 怎么用才省

**先看列表，再挑着读。** 列表一行一封，20 封的代价很小；正文一封就可能几千字。

```bash
$MAIL search --since 7d --limit 30           # 先看有哪些
$MAIL read --uid 351 --chars 400             # 只读需要的那封，且截断
```

要反复看的邮件用 `save` 落盘，把路径给用户，而不是把全文灌进上下文：

```bash
$MAIL save --uid 351 --out .tmp/mail-351.md
```

## 常见需求怎么接

### 「最近有什么邮件」

`search --since 7d --limit 20`，然后按三类回：**需要你处理的**、**通知类的**、**可以忽略的**。不要逐封复述。

### 「总结这周邮件」

1. `search --since 7d --limit 40 --json`
2. 先按发件人/主题分组，压成几行
3. 只对「需要动作」的邮件 `read` 细节
4. 汇报里区分「事实」和「我推测的」——比如没写截止日期，别自己补一个

### 「找某人的邮件」「找附件」

```bash
$MAIL search --sender campusrecruitment --since 30d
$MAIL search --attachment --since 30d --limit 10
$MAIL attach --uid 340 --out .tmp/att
```

`attach` 会把附件存到本地并返回路径，之后可以用别的工具读（PDF、xlsx、ics 都行）。

### 「把邮件里的时间写进日历」

前提：装了 `apple-calendar` skill（`~/.agents/skills/apple-calendar/bin/cal`）。

1. 拉候选：

   ```bash
   $MAIL search --since 7d --limit 40 --json \
     --match-any "截止,面试,笔试,会议,航班,预约,报名,过期,ddl"
   ```

2. 逐条判断，别照搬：
   - **已经过去的**不写进日历，单独列一份「已过期」给用户核对。
   - 有钟点的写定时事件；只有截止日的写全天事件，备注写清几点。
   - 窗口型（「11/6–11/8 任选」）放到窗口最后一天，备注写范围。
   - 需要先点「确认参加」的，单独列一条，往往比正场更急。
   - 同一件事的多封通知合并成一条。
3. 出确认表让用户点头，再写：

   ```bash
   $CAL add --file .tmp/plan.json --dry-run
   $CAL add --file .tmp/plan.json
   $CAL list --from 2026-11-09 --to 2026-11-20
   ```

4. **口令、准考证号、通行证这类凭据不写进日历备注**，只写「见 X 月 X 日邮件」——日历会同步到所有设备。

## 排错

| 现象 | 处理 |
|---|---|
| `找不到配置文件` | 让用户按 `config.example.txt` 建 `~/.config/mail/account.txt` |
| `登录失败` | 授权码错，或网页端没开 IMAP；按 hint 里的分邮箱说明讲给用户 |
| `连不上` | host/port 错，或网络封了 993 |
| `Unsafe Login` | 163 的 ID 命令没发出去，脚本被改过就还原 |
| 中文搜不到 | 服务端不支持 UTF-8 SEARCH，脚本已退化为本地过滤；放宽 `--since` 或用 `--sender` 收窄 |
| 结果为空 | 先 `check` 看目录对不对，再用 `folders` 确认文件夹名 |
