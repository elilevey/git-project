# Data Source

Research question: when a public company's post reaches the Hacker News front page, does its stock price move more than the market does (abnormal return) within 1 hour, 1 day and 1 week, and is the effect larger for small companies than for large ones?

## 1. Source details

| | Hacker News (approved) | Finnhub (pending approval) |
|---|---|---|
| Name | Hacker News API | Finnhub Stock API – Quote endpoint |
| URL | `https://hacker-news.firebaseio.com/v0/topstories.json`<br>`https://hacker-news.firebaseio.com/v0/item/<id>.json` | `https://finnhub.io/api/v1/quote?symbol=<SYMBOL>&token=<KEY>` |
| Documentation | https://github.com/HackerNews/API | https://finnhub.io/docs/api/quote |
| Data format | JSON | JSON |
| Key / username required | No | Yes, a free API key. Stored in `~/.finnhub_key` (outside the project, `chmod 600`) and never committed. |
| License | Official public API provided by Y Combinator, free to use | Free tier for personal, non-commercial use; limited to 60 requests per minute |
| Sampling frequency | Every 30 minutes (one run of `bin/collect.sh`; scheduled with cron from the next stage) | Same run as HN. Outside US market hours (14:30–21:00 UTC, Monday–Friday) the quote returns the last closing price |

Finnhub was added following the staff's suggestion to check whether appearing on HN affects a company's stock price. It is marked as pending until approved.

## 2. What is collected

From Hacker News, each sample saves the ranked list of front-page post IDs and the details of the top 30 posts (title, link, score, number of comments, author and posting time). From Finnhub, each sample saves the current quote for two market baselines, QQQ (NASDAQ-100, large companies) and IWM (Russell 2000, small companies), plus every public company whose site appears in that sample's front-page links.

### File format

Each run of `bin/collect.sh` saves **one file per sample**: `raw/YYYY-mm-dd/HHMM.json`, with the date and time in **UTC**. The file is built in a temporary folder and moved into `raw/` only once it is complete and validated, so `raw/` never holds a half-written sample. The file contains:

| Field | Content |
|---|---|
| `sample_time` | Time of the sample, ISO 8601 UTC |
| `hn_top` | The full front-page ranking from `topstories.json` (list of post IDs) |
| `hn_items` | The details of the top 30 posts, as returned by `item/<id>.json` |
| `quotes` | One Finnhub quote per ticker, with an added `symbol` field |

Samples taken before 26 Nov 2026 were collected by hand in an earlier format: Israel time instead of UTC, and several files per sample (`HHMM_hn_top.json`, `HHMM_hn_items.json`, `HHMM_<SYMBOL>.json`). Since `raw/` is append-only, they were left as they are; `normalise.sh` will handle both formats.

### Matching posts to companies: `tickers.csv`

`tickers.csv` (in the project root) maps a company's domain to its stock ticker, with the header `Domain,Ticker`. A post matches a row if its domain **equals** the table's domain or **ends with a dot plus** that domain, so `investors.paloaltonetworks.com` matches `paloaltonetworks.com`, but `notpaloaltonetworks.com` does not.

The table only lists sites where a public company talks about itself. Deliberately excluded:
- **Platforms** owned by public companies but where anyone posts (`github.com`, `youtube.com`, `substack.com`, `wordpress.com`, `docs.google.com`): posts there are hosted by the company, not about it.
- **News sites** (e.g. `reuters.com`): their articles are about other companies.
- **Private companies** (e.g. `openai.com`, `databricks.com`): no stock price.

The table is maintained by hand: new domains are reviewed periodically and added with a commit. **Limitation:** a company is only captured from the moment it is added to the table. Earlier samples have no quote for it, and missing quotes are not filled in afterwards.

## 3. Schema

All samples are merged into one table, `dataset.csv`, with one row per post per sample (HN rows) or one row per symbol per sample (stock rows). Columns that don't apply to a row are left empty.

| Column | Content | Unit |
|---|---|---|
| `sample_time` | When the sample was taken | ISO 8601, UTC |
| `source` | `hn` or `stock` | text |
| `rank` | Position on the front page (1 = top) | integer |
| `post_id` | HN post ID | integer |
| `title` | Post title | text |
| `url` | Link the post points to | text |
| `domain` | Domain of `url` (e.g. `blog.google`), used to match a post to a company | text |
| `score` | Points (upvotes) at sample time | integer |
| `comments` | Number of comments at sample time | integer |
| `author` | HN username of the poster | text |
| `post_time` | When the post was published | ISO 8601, UTC |
| `symbol` | Stock ticker (e.g. `GOOGL`, `QQQ`) | text |
| `price` | Current price | USD |
| `prev_close` | Previous day's closing price | USD |
| `change_pct` | Change since previous close | percent |
| `quote_time` | Time of the quote | ISO 8601, UTC |

## 4. Why these columns

`post_time`, `rank` and `sample_time` show when a post reached the front page and how long it stayed. `url` and `domain` link a post to a company. `score` and `comments` measure how much attention the post got, which may explain the size of an effect. `price`, `prev_close` and `quote_time` are needed to compute returns over each time window, and QQQ/IWM rows give the market baseline for abnormal returns.

Dropped fields: `kids` (comment IDs; the largest field and not needed, since `comments` already holds the count), `type` (always `story` on the front page), `text` (post body, only on posts without a link, so it can't be matched to a company), and Finnhub's `d`, `h`, `l` and `o` (the dollar change can be computed from `price` and `prev_close`; the day's high, low and open aren't needed for the question).

## 5. Field translation

| Source | Source field | Schema column |
|---|---|---|
| HN `topstories.json` | position in the list | `rank` |
| HN `item` | `id` | `post_id` |
| HN `item` | `title` | `title` |
| HN `item` | `url` | `url` |
| HN `item` | (derived from `url`) | `domain` |
| HN `item` | `score` | `score` |
| HN `item` | `descendants` | `comments` |
| HN `item` | `by` | `author` |
| HN `item` | `time` (Unix seconds) | `post_time` |
| Finnhub `quote` | `symbol` (added by `collect.sh`) | `symbol` |
| Finnhub `quote` | `c` | `price` |
| Finnhub `quote` | `pc` | `prev_close` |
| Finnhub `quote` | `dp` | `change_pct` |
| Finnhub `quote` | `t` (Unix seconds) | `quote_time` |
| sample file | `sample_time` (older samples: from the folder and file name, converted from Israel time to UTC) | `sample_time` |

## 6. Expected size

Assuming a semester of about 100 days (about 70 trading days), with a sample every 30 minutes (48 a day).

**`raw/`**
- One sample file is about 34 KB (measured on 26 Nov 2026: front-page list, 30 posts and quotes). 48 samples a day × 100 days ≈ 4,800 files ≈ **163 MB**, under the 500 MB limit.

**`dataset.csv`**
- HN rows: 30 posts × 4,800 samples = 144,000 rows × about 150 bytes ≈ **22 MB**.
- Stock rows: about 3 tickers per sample (QQQ, IWM and any matched company) × 4,800 samples ≈ 14,400 rows × about 60 bytes ≈ **0.9 MB**.
- Total: about **23 MB**.

## Note on samples

Manual samples (old format): HN on 19, 20, 21 and 22 Nov 2026; stock quotes on 19, 20 and 24 Nov 2026 (the US market is closed on weekends, and the 23 Nov sample was missed). From 26 Nov 2026, samples are taken with `bin/collect.sh` in the format described above.
