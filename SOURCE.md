# Data source proposals

## Proposal 1: Hacker News – from "new" to the front page

Hacker News is a well-known tech news site where users post links and vote them up. Every post starts in the "new" list, and only some reach the front page, where the ranking keeps changing all day. The site only shows the current ranking, so the path each post takes (when it reached the front page, how high it climbed and how long it stayed) is lost unless it is collected. Collecting both lists regularly would show which new posts make it to the front page, how long that takes, and whether AI-related posts make it more often or stay longer than other topics.

- **Content:** Two lists of post IDs in ranked order: the front page (`topstories`) and the newest posts (`newstories`). For the top posts of each list, the post details: title, score, number of comments, author, time posted and the linked URL.
- **URLs:**
  - `https://hacker-news.firebaseio.com/v0/topstories.json`
  - `https://hacker-news.firebaseio.com/v0/newstories.json`
  - `https://hacker-news.firebaseio.com/v0/item/<id>.json` (details of one post)
  - Documentation: https://github.com/HackerNews/API
- **Update frequency:** Changes constantly. In a test on 6 Nov 2026, about 15 new posts appeared in the "new" list and several front-page posts changed position within about 20 minutes.
- **Expected sample size:** About 4.5 KB for each list, plus about 0.4 KB per post for details. Fetching both lists and the details of the top 30 posts in each comes to about 33 KB per sample. Collecting every 30 minutes over the semester comes to roughly 160 MB, under the 500 MB limit.
- **Key/password required:** No. It is HN's official public API.
- **Notes:** Post times are Unix timestamps (UTC). The API returns the current state only; historical ranking is not available from it.
- **Sample** (front page, shortened):

```json
[50390124, 50389333, 50385272, 50390525, 50391145]
```

  Details of the top post:

```json
{
  "title": "Dutch 'idealist' bank ASN blocks non-Google Android, including GrapheneOS",
  "score": 255,
  "time": 1793957232,
  "url": "https://github.com/PrivSec-dev/banking-apps-compat-report/issues/105"
}
```

## Proposal 2: YouTube – trending music videos by country

The YouTube Data API returns the music videos currently trending in a country, together with their view, like and comment counts. These counts change constantly and the API only gives today's numbers, so the history disappears unless it is collected. This would make it possible to see how fast views grow for new hits compared with older songs, and how the trending list changes during the day.

- **Content:** The top 10 trending music videos for a country. For each video: video ID, title, channel (usually the artist), publish date, view count, like count and comment count.
- **URL:** `https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&chart=mostPopular&videoCategoryId=10&regionCode=IL&maxResults=10&fields=items(id,snippet(title,channelTitle,publishedAt),statistics)&key=API_KEY`
- **Update frequency:** View counts change continuously. In a test on 5 Nov 2026, all 10 view counts had changed after about 25 minutes (e.g. 2,070,320 → 2,076,990), while the list of videos stayed the same.
- **Expected sample size:** About 80 KB for the full response, reduced to about 4 KB by requesting only the needed fields with the `fields` parameter. Collecting every hour for two countries over the semester comes to roughly 20 MB.
- **Key/password required:** Yes, a free YouTube Data API key from Google Cloud. It is stored outside the project folder with `chmod 600` and is never committed.
- **Possible issue:** YouTube's API policies limit how long API data such as view counts may be stored, and some view-count history is tracked by outside sites. This is one reason Proposal 1 is my preference.
- **Sample** (Israel, shortened):

```json
{
  "items": [
    {
      "snippet": {
        "title": "סטטיק & נועה קירל - אקסים אובססיביים (Prod. By Nuri)",
        "channelTitle": "Static and Ben El - סטטיק ובן אל"
      },
      "statistics": { "viewCount": "2076602" }
    }
  ]
}
```

## Preference

I prefer **Proposal 1 (Hacker News)**. It is an official, documented API with no key and no limits on storing the data, it changes every few minutes, and the ranking history it shows disappears unless collected. I also checked another tech site, Lobsters, as a possible second source, but its robots.txt disallows automated access, so I did not use it.
