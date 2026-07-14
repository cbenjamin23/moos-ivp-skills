window.SKILL_GRAPH = {
  groups: {
    foundation: { label: "Foundation", color: "#6ea8fe" },
    surface: { label: "Development", color: "#72d3a4" },
    mission: { label: "Mission System", color: "#e8b96a" },
    evidence: { label: "Evidence", color: "#d88ac7" }
  },
  // `weight` is a manual visual emphasis used for node sizing, not a
  // measured code metric such as lines of code or file count.
  nodes: [
    { id: "installer", label: "moos-ivp-installer", short: "installer", group: "foundation", weight: 2 },
    { id: "repo", label: "moos-ivp-repo-builder", short: "repo-builder", group: "foundation", weight: 2 },
    { id: "app", label: "moos-app-builder", short: "app-builder", group: "surface", weight: 3 },
    { id: "behavior", label: "ivp-behavior-builder", short: "behavior-builder", group: "surface", weight: 3 },
    { id: "docs", label: "moos-ivp-docs", short: "docs", group: "surface", weight: 3 },
    { id: "map", label: "moos-map-builder", short: "map-builder", group: "surface", weight: 3 },
    { id: "mission", label: "moos-ivp-mission-builder", short: "mission-builder", group: "mission", weight: 8 },
    { id: "eval", label: "moos-ivp-eval-mission-builder", short: "eval-mission", group: "mission", weight: 5 },
    { id: "harness", label: "moos-ivp-harness-builder", short: "harness-builder", group: "mission", weight: 4 },
    { id: "alog", label: "moos-alog-analysis", short: "alog-analysis", group: "evidence", weight: 4 }
  ],
  links: [
    { source: "installer", target: "repo" },
    { source: "repo", target: "app" },
    { source: "repo", target: "behavior" },
    { source: "repo", target: "mission" },
    { source: "app", target: "mission" },
    { source: "behavior", target: "mission" },
    { source: "mission", target: "docs" },
    { source: "mission", target: "map" },
    { source: "mission", target: "app" },
    { source: "mission", target: "behavior" },
    { source: "mission", target: "eval" },
    { source: "eval", target: "mission" },
    { source: "eval", target: "harness" },
    { source: "harness", target: "eval" },
    { source: "harness", target: "mission" },
    { source: "mission", target: "alog" },
    { source: "eval", target: "alog" },
    { source: "harness", target: "alog" }
  ]
};

window.cloneSkillGraph = function cloneSkillGraph() {
  return {
    nodes: window.SKILL_GRAPH.nodes.map((node) => ({ ...node })),
    links: window.SKILL_GRAPH.links.map((link) => ({ ...link }))
  };
};
