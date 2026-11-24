Eli Levey (working alone with approval from professor)

https://github.com/elilevey/git-project


## What broke

### 2026-11-24 – Finnhub unreachable
- **What I saw:** the stock sample created no files, and `curl -s` printed nothing.
- **Diagnosis:** running curl with `-S` showed `Failed to connect to finnhub.io port 443`. `git pull` worked, so the network itself was up.
- **Cause:** finnhub.io was blocked on the campus Wi-Fi. Status sites showed no outage.
- **Fix:** switched to a phone hotspot and the sample worked.
- **Why this fix:** a one-time workaround. Long term, collection moves to the course server, which needs to be checked for access to finnhub.io.
- **Lesson:** use `curl -sS` so errors are shown instead of hidden.
