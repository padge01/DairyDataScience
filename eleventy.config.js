import { feedPlugin } from "@11ty/eleventy-plugin-rss";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** One year of contributions as a GitHub-style grid: weeks across, Sunday to Saturday down. */
function heatmap(days) {
  const cell = 11, gap = 3, top = 16;
  const max = Math.max(1, ...days.map(([, n]) => n));
  // Five steps on one hue, by lightness, so the scale never depends on telling colors apart.
  const level = (n) => (n === 0 ? 0 : Math.min(4, Math.ceil((Math.log(n + 1) / Math.log(max + 1)) * 4)));
  const first = new Date(`${days[0][0]}T00:00:00Z`).getUTCDay();
  let rects = "", labels = "", lastMonth = -1;
  days.forEach(([date, n], i) => {
    const slot = i + first, col = Math.floor(slot / 7), row = slot % 7;
    const x = col * (cell + gap), y = top + row * (cell + gap);
    const d = new Date(`${date}T00:00:00Z`);
    if (row === 0 && d.getUTCMonth() !== lastMonth && d.getUTCDate() <= 7) {
      lastMonth = d.getUTCMonth();
      labels += `<text x="${x}" y="10">${MONTHS[lastMonth]}</text>`;
    }
    rects += `<rect x="${x}" y="${y}" width="${cell}" height="${cell}" rx="2" class="l${level(n)}"><title>${n} on ${date}</title></rect>`;
  });
  const width = (Math.floor((days.length + first - 1) / 7) + 1) * (cell + gap) - gap;
  const height = top + 7 * (cell + gap) - gap;
  return `<svg class="heatmap" viewBox="0 0 ${width} ${height}" role="img" aria-label="Contributions in the last year">${labels}${rects}</svg>`;
}

export default function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy("src/css");
  eleventyConfig.addPassthroughCopy("src/img");
  eleventyConfig.addPassthroughCopy("src/archive");
  eleventyConfig.addPassthroughCopy("src/talks/**/*.pdf");
  eleventyConfig.addPassthroughCopy("src/writing/**/*.{png,jpg,jpeg,gif,svg,webp}");
  eleventyConfig.addPassthroughCopy({ "src/_redirects": "_redirects" });
  eleventyConfig.addPassthroughCopy("src/robots.txt");
  // The ARPAS 2026 deck: one built file and its PDF, copied as they are (unlisted: nothing links here; noindex).
  eleventyConfig.addPassthroughCopy("src/arpas-2026");
  eleventyConfig.ignores.add("src/arpas-2026/**");

  eleventyConfig.addShortcode("heatmap", heatmap);
  eleventyConfig.addFilter("monthYear", (d) => {
    const date = new Date(d);
    return `${MONTHS[date.getUTCMonth()]} ${date.getUTCFullYear()}`;
  });
  eleventyConfig.addFilter("isoDate", (d) => new Date(d).toISOString().slice(0, 10));
  eleventyConfig.addFilter("number", (n) => Number(n).toLocaleString("en-US"));

  // Writing and talks share one list, newest first.
  eleventyConfig.addCollection("entries", (api) =>
    api.getFilteredByTag("entry").sort((a, b) => b.date - a.date),
  );

  eleventyConfig.addPlugin(feedPlugin, {
    type: "rss",
    outputPath: "/feed.xml",
    collection: { name: "entries", limit: 30 },
    metadata: {
      language: "en",
      title: "Dairy Data Science",
      subtitle: "Pádraig Lucey on dairy data, nutrition models and AI agents.",
      base: "https://dairydatascience.com/",
      author: { name: "Pádraig Lucey" },
    },
  });

  return {
    dir: { input: "src", includes: "_includes", data: "_data", output: "_site" },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
}
