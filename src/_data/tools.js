// Tools Pádraig publishes for AI agents (MCP servers and plugins), newest first. Each lists where to get it.
export default [
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
