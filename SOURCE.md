# Data Source

Research question: when a public company's post reaches the Hacker News front page, does its stock price move more than the market does (abnormal return) within 1 hour, 1 day and 1 week, and is the effect larger for small companies than for large ones?

## 1. Source details

| | Hacker News (approved) | Finnhub (pending approval) |
|---|---|---|
| Name | Hacker News API | Finnhub Stock API – Quote endpoint |
| URL | `https://hacker-news.firebaseio.com/v0/topstories.json`<br>`https://hacker-news.firebaseio.com/v0/item/<id>.json` | `https://finnhub.io/api/v1/quote?symbol=<SYMBOL>&token=<KEY>` |
| Documentation | https://github.com/HackerNews/API | https://finnhub.io/docs/api/quote |
| Data format | JSON | JSON |
| Key / username required | No | Yes, a free API key. Stored in an environment variable outside the repo and never committed. |
| License | Official public API provided by Y Combinator, free to use | Free tier for personal, non-commercial use; limited to 60 requests per minute |
| Sampling frequency | Every 30 minutes | Every 30 minutes, during US market hours only (16:30–23:00 Israel time, Monday–Friday) |

Finnhub was added following the staff's suggestion to check whether appearing on HN affects a company's stock price. It is marked as pending until approved.

## 2. What is collected

From Hacker News, each sample saves the ranked list of front-page post IDs and the details of the top 30 posts (title, link, score, number of comments, author and posting time). From Finnhub, each sample saves the current quote for two market baselines, QQQ (NASDAQ-100, large companies) and IWM (Russell 2000, small companies), plus every public company whose site appears in that sample's front-page links.

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
| Finnhub `quote` | (from the request) | `symbol` |
| Finnhub `quote` | `c` | `price` |
| Finnhub `quote` | `pc` | `prev_close` |
| Finnhub `quote` | `dp` | `change_pct` |
| Finnhub `quote` | `t` (Unix seconds) | `quote_time` |
| (file name) | date and time of the sample | `sample_time` |

## 6. Expected size

Assuming a semester of about 100 days (about 70 trading days).

**`raw/`**
- HN: about 23.5 KB per sample (4.5 KB list + 19 KB for 30 posts, measured on 19 Nov 2026). 48 samples a day × 100 days ≈ **113 MB**.
- Finnhub: about 0.1 KB per quote, about 6 symbols per sample, 14 samples per trading day × 70 days ≈ 5,900 files, **under 1 MB** of data.
- Total: about **115 MB**, under the 500 MB limit.

**`dataset.csv`**
- HN rows: 30 posts × 4,800 samples = 144,000 rows × about 150 bytes ≈ **22 MB**.
- Stock rows: about 5,900 rows × about 60 bytes ≈ **0.4 MB**.
- Total: about **22 MB**.

## Note on samples

## Note on samples

The assignment asks for 4 samples from 4 different days. I started collecting on Thursday 19 Nov, so by the deadline this submission includes HN samples from 3 days (Thursday–Saturday) and stock samples from 2 (the US market is closed on Saturday). The fourth day will be added on Sunday.
