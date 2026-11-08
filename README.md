# mail-skill

> 用 IMAP 只读访问邮箱的 agent skill：按时间/发件人/关键词/附件检索、读正文、导出、下载附件，也能把邮件里的截止日期整理进 Mac 日历。

## 这是什么

一个命令行工具加一份给 agent 看的说明书。你不是让 AI「猜」邮箱里有什么，而是让它**查**：

```bash
$ mail search --since 7d --unread        # 最近一周的未读
$ mail read --uid 351 --chars 400        # 读其中一封，正文截断
$ mail attach --uid 340 --out ./att      # 把这封的附件扒下来
```

`mail-to-calendar` 只是它的一条配方：把邮件里的面试、笔试、报名截止抽出来，交给 [apple-calendar-skill](https://github.com/DAweiD1/apple-calendar-skill) 写进日历。工具本身不关心日历。

## 设计取向

**只读，而且刻意只读。** `SELECT readonly=True` + `BODY.PEEK[]`，连「标记已读」都不会发生。发信、删信、改标签这些能力，这里一个都没有。

**列表便宜，正文按需。** 邮件正文动辄几千字，全塞进模型上下文既慢又贵，还会把真正重要的信息淹掉。所以 `search` 只回一行一封的摘要，`read` 才取正文，`save` 用来落盘给之后看。

**凭据只在一个文件里。** 脚本读它，输出里永远没有它。不进 git、不进对话、不进日历备注。

## 环境要求

- Python 3.6+（macOS 自带的够用）
- 写日历那一步需要 macOS + [apple-calendar-skill](https://github.com/DAweiD1/apple-calendar-skill)

## 安装

```bash
git clone https://github.com/DAweiD1/mail-skill.git
cd mail-skill && bash scripts/install.sh
```

装到 `~/.agents/skills/mail`，并生成配置模板。

## 配置

```bash
mkdir -p ~/.config/mail && chmod 700 ~/.config/mail
cp config.example.txt ~/.config/mail/account.txt
nano ~/.config/mail/account.txt     # 填 user 和 password
chmod 600 ~/.config/mail/account.txt
```

```
user = your-address@163.com
password = 授权码
```

`password` 是**授权码**不是登录密码：

| 邮箱 | 哪里拿 |
|---|---|
| 163 / 126 / 188 | 网页版 → 设置 → POP3/SMTP/IMAP → 开启 IMAP → 生成授权码 |
| QQ / 腾讯企业邮 | 设置 → 账户 → POP3/IMAP 服务 → 开启并生成 |
| Gmail | 先开两步验证，再生成「应用专用密码」 |
| Outlook | 应用密码，`host = outlook.office365.com` |
| 公司企业邮 | `host` 改成 IT 给的地址，例如 `imap.qiye.163.com` |

验证：

```bash
~/.agents/skills/mail/bin/mail check
```

## 命令

| 命令 | 作用 |
|---|---|
| `check` | 连通性、邮件数、文件夹 |
| `folders` | 文件夹列表（中文已解码） |
| `search` | 邮件列表，不含正文 |
| `read` | 读正文 |
| `save` | 存 `.md` 或 `.eml` |
| `attach` | 下载附件 |

`search` 参数：`--since`（`7d` / `2026-11-01` / `today`）、`--before`、`--sender`、`--subject`、`--query`、`--unread`、`--attachment`、`--match-any`、`--scan`、`--limit`、`--folder`、`--json`。

`--json` 在每条命令上都可用，方便接其他程序。

## 那些坑，已经填了

写这个工具时踩到的，都留在代码里了：

- **163 的 `ID` 命令**：登录后不发，后续命令一律 `Unsafe Login`。
- **中文文件夹名**：IMAP 用 modified UTF-7，`收件箱` 在线上是 `&g0l6P3ux-`。收发两个方向都做了转换。
- **GB18030 正文**：国内邮件大量用 GB2312/GBK，解码链是「声明编码 → UTF-8 → GB18030 → Big5」。
- **中文搜索**：服务端 SEARCH 普遍不支持 UTF-8，中文关键词会退化成「拉到本地再匹配」，用 `--since` 收窄范围能快很多。

## 给 agent 用

仓库放进 `~/.agents/skills/mail/` 即可，`SKILL.md` 会被自动发现。里面写了工作流、省 token 的做法，以及「邮件转日历」的完整配方。

## 隐私与安全

- **凭据**只在 `~/.config/mail/account.txt`（`chmod 600`），脚本读它登录，任何输出里都不出现。
- **邮件正文会进入 agent 上下文**——这是让 AI 读邮件的必然代价。不想让 work 邮箱进模型，就别把它配进来。
- 脚本只有 `SELECT` / `SEARCH` / `FETCH` 三种操作，没有写入路径。
- 授权码随时可以在邮箱网页端重新生成，旧的立刻失效。

## 已知限制

- 没有增量同步，每次都在时间窗内重扫。
- 附件下载按 MIME part 走，少数嵌套 `message/rfc822` 的邮件可能漏。
- 不支持 OAuth（Gmail/Outlook 需要用应用专用密码）。

## License

MIT，见 [LICENSE](./LICENSE)。
