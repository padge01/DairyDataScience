// Tools Pádraig publishes for AI agents (MCP servers and plugins), newest first. Each lists where to get it.
export default [
  {
    name: "Ration Lab",
    icon: "/img/tools/ration-lab.png",
    description:
      "Fully featured ration formulation software built in Rust, with multiple linear and nonlinear solvers. Includes chance-constrained solutions based on the variation in feed tests, and the variation between cows in a pen from my PhD thesis. Available online, or as an MCP server your AI agent can connect to and run.",
    get: [
      { where: "In your browser", how: "lab.dairydatascience.com" },
      { where: "MCP server", how: "https://lab.dairydatascience.com/mcp", code: true },
      { where: "Claude", how: "Add a custom connector with the address above" },
    ],
    links: [
      { label: "Open the lab", url: "https://lab.dairydatascience.com/" },
      { label: "Privacy", url: "https://lab.dairydatascience.com/privacy" },
      { label: "Terms", url: "https://lab.dairydatascience.com/terms" },
    ],
    year: 2026,
  },
  {
    name: "Dairy Data Tools",
    icon: "/img/tools/dairy-data-tools.png",
    description:
      "A dairy's own DairyComp and EZfeed exports, read by your AI assistant: the herd, each pen and cow, pen cows joined to pen feed, a weekly or visit review, and a ration change with the season taken out. Worked out by tested scripts, not guessed.",
    get: [
      { where: "Claude", how: "Customize > Plugins > Add marketplace: padge01/dairy-data-tools" },
      { where: "Codex and others", how: "npx skills add padge01/dairy-data-tools", code: true },
      { where: "On your computer", how: "pip install dairy-data-tools", code: true },
    ],
    links: [
      { label: "GitHub", url: "https://github.com/padge01/dairy-data-tools" },
      { label: "PyPI", url: "https://pypi.org/project/dairy-data-tools/" },
      { label: "DOI", url: "https://doi.org/10.5281/zenodo.23493936" },
    ],
    year: 2026,
  },
  {
    name: "BESTPRED",
    icon: "/img/tools/bestpred.png",
    description:
      "USDA's best prediction of dairy lactation records, as tools any AI agent can call: 305-day and mature-equivalent milk, fat and protein, reliability and persistency from a herd's or a cow's test days. A Python port checked against USDA's own program.",
    get: [
      { where: "Claude", how: "In Claude's plugin directory: BESTPRED" },
      { where: "Any agent", how: "https://bestpred.dairydatascience.com/mcp", code: true },
      { where: "Codex", how: "codex plugin marketplace add padge01/bestpred-python", code: true },
      { where: "On your computer", how: "uvx bestpred-mcp", code: true },
    ],
    links: [
      { label: "GitHub", url: "https://github.com/padge01/bestpred-python" },
      { label: "PyPI", url: "https://pypi.org/project/bestpred-mcp/" },
      { label: "Privacy", url: "https://bestpred.dairydatascience.com/privacy" },
    ],
    year: 2026,
  },
];
