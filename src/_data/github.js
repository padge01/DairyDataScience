// GitHub activity for the home page: the contribution heatmap, the last year's commits, pull requests,
// reviews and issues, and the public repos chosen below. Read at build time with GITHUB_TOKEN; without a
// token (or if GitHub fails) the last saved snapshot is used, so a build never breaks on it.
import { readFile, writeFile } from "node:fs/promises";

const USER = "padge01";
const SNAPSHOT = new URL("../../github-snapshot.json", import.meta.url);
// Public repos to show, in this order. Private work appears only as counts in the heatmap.
const REPOS = ["xteink-pokemon-game", "homelab"];

async function gh(path, token, body) {
  const res = await fetch(`https://api.github.com${path}`, {
    method: body ? "POST" : "GET",
    headers: { Authorization: `Bearer ${token}`, Accept: "application/vnd.github+json", "User-Agent": "dairydatascience-build" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`GitHub ${path}: ${res.status}`);
  return res.json();
}

async function fresh(token) {
  const since = new Date(Date.now() - 365 * 864e5).toISOString().slice(0, 10);
  const query = `query { user(login: "${USER}") { contributionsCollection { contributionCalendar {
    totalContributions weeks { contributionDays { date contributionCount } } } } } }`;
  const graph = await gh("/graphql", token, { query });
  const calendar = graph.data.user.contributionsCollection.contributionCalendar;
  const count = async (q, kind = "issues") =>
    (await gh(`/search/${kind}?per_page=1&q=${encodeURIComponent(q)}`, token)).total_count;
  const [commits, pullRequests, reviews, issues] = await Promise.all([
    count(`author:${USER} author-date:>=${since}`, "commits"),
    count(`author:${USER} is:pr created:>=${since}`),
    count(`reviewed-by:${USER} -author:${USER} is:pr created:>=${since}`),
    count(`author:${USER} is:issue created:>=${since}`),
  ]);
  const repos = await Promise.all(
    REPOS.map(async (name) => {
      const r = await gh(`/repos/${USER}/${name}`, token);
      return { name: r.name, url: r.html_url, description: r.description, language: r.language, pushedAt: r.pushed_at };
    }),
  );
  return {
    fetchedAt: new Date().toISOString(),
    total: calendar.totalContributions,
    days: calendar.weeks.flatMap((w) => w.contributionDays.map((d) => [d.date, d.contributionCount])),
    counts: { commits, pullRequests, reviews, issues },
    repos,
  };
}

export default async function () {
  const token = process.env.GITHUB_TOKEN;
  if (token) {
    try {
      const data = await fresh(token);
      await writeFile(SNAPSHOT, JSON.stringify(data, null, 1) + "\n");
      return data;
    } catch (error) {
      console.warn(`[github] using the saved snapshot: ${error.message}`);
    }
  }
  return JSON.parse(await readFile(SNAPSHOT, "utf8"));
}
