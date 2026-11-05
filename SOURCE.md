# Data source proposals

## Proposal 1: Apple Music – most-played songs by country

Apple publishes a live chart of the most-played songs on Apple Music for each country. The feed only ever shows the current chart, so once a day passes, that day's chart is gone unless it was saved. Collecting it regularly for several countries (for example Israel and the US) would show how songs rise and fall over the semester, how long a hit stays in the top 10, and whether a song becomes popular in one country before another.

- **Content:** The top 10 most-played songs for a country. For each song: chart position (order in the list), song name, artist name, release date, genres and a link to the song.
- **URL:** `https://rss.marketingtools.apple.com/api/v2/<country>/music/most-played/10/songs.json`
  (for example `il` for Israel, `us` for the United States)
- **Update frequency:** View counts change continuously. In a test on 5 Nov 2026, all 10 view counts had changed after about 25 minutes (e.g. 2,070,320 → 2,076,990), while the list of videos stayed the same.
- **Expected sample size:** About 6.5 KB per country per download. Collecting every hour for two countries over the semester comes to roughly 30 MB.
- **Key/password required:** No.
- **Notes:** While testing, the feed once returned a `504 Gateway Time-out` HTML page instead of JSON. The collection script will need to check that each download is valid JSON before saving it.
- **Sample** (US chart, shortened):

```json
{
  "feed": {
    "title": "Top Songs",
    "results": [
      { "name": "Solar Eclipse", "artistName": "Drake & Don Toliver" },
      { "name": "Nicole Kidman", "artistName": "ADÉLA" },
      { "name": "Been By Now", "artistName": "Morgan Wallen" }
    ]
  }
}
```

## Proposal 2: YouTube – trending music videos by country

The YouTube Data API returns the music videos currently trending in a country, together with their view, like and comment counts. These counts change constantly and the API only gives today's numbers, so the history disappears unless it is collected. This would make it possible to see how fast views grow for new hits compared with older songs, and to compare what is trending on YouTube with the Apple Music chart for the same country.

- **Content:** The top 10 trending music videos for a country. For each video: video ID, title, channel (usually the artist), publish date, view count, like count and comment count.
- **URL:** `https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&chart=mostPopular&videoCategoryId=10&regionCode=IL&maxResults=10&fields=items(id,snippet(title,channelTitle,publishedAt),statistics)&key=API_KEY`
- **Update frequency:** View, like and comment counts change continuously; the list of trending videos changes during the day (to be confirmed by comparing samples).
- **Expected sample size:** About 80 KB for the full response, reduced to about 4 KB by requesting only the needed fields with the `fields` parameter. Collecting every hour for two countries over the semester comes to roughly 20 MB.
- **Key/password required:** Yes, a free YouTube Data API key from Google Cloud. It is stored outside the project folder with `chmod 600` and is never committed.
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
    },
    {
      "snippet": { "channelTitle": "BarTzabaryOfficial" },
      "statistics": { "viewCount": "255790" }
    }
  ]
}
```

## Preference

I prefer **Proposal 1 (Apple Music)** as the main source, with YouTube as the second source to combine with it. Apple Music needs no key, has a simple stable format and small samples, while YouTube adds numbers (views, likes) that change constantly, which makes it a good source for comparison. Together they would let me ask whether the two platforms agree on what is popular in each country.
