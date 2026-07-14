const colorSchemes = {
  discipline: {
    foundation: "#2f6fb6",
    surface: "#2f8f6b",
    mission: "#b7791f",
    evidence: "#8d5c8b",
    line: "#6e7d8c",
    label: "#1c2733",
    labelBackground: "#ffffff"
  },
  colorblind: {
    foundation: "#0072b2",
    surface: "#009e73",
    mission: "#d55e00",
    evidence: "#cc79a7",
    line: "#5f6f7f",
    label: "#17202a",
    labelBackground: "#ffffff"
  },
  graphite: {
    foundation: "#64748b",
    surface: "#64748b",
    mission: "#334155",
    evidence: "#64748b",
    line: "#7a8694",
    label: "#17202a",
    labelBackground: "#ffffff"
  },
  instrument: {
    foundation: "#3867a6",
    surface: "#417d7a",
    mission: "#a65f1b",
    evidence: "#6f5c91",
    line: "#536d86",
    label: "#15202c",
    labelBackground: "#fbfdff"
  }
};

const labelPlacements = {
  above: {
    "text-halign": "center",
    "text-margin-x": 0,
    "text-margin-y": -10,
    "text-valign": "top"
  },
  right: {
    "text-halign": "right",
    "text-margin-x": 9,
    "text-margin-y": 0,
    "text-valign": "center"
  },
  center: {
    "text-halign": "center",
    "text-margin-x": 0,
    "text-margin-y": 0,
    "text-valign": "center"
  },
  below: {
    "text-halign": "center",
    "text-margin-x": 0,
    "text-margin-y": 10,
    "text-valign": "bottom"
  }
};

const state = {
  variant: "journal",
  labelPlacement: "above",
  colorScheme: "discipline",
  nodeScale: 1,
  arrowScale: 1
};

const readmeExport = {
  fitPadding: 70,
  panX: 20,
  panY: -19
};

const variants = {
  journal: {
    title: "Journal",
    nodeShape: "ellipse",
    padding: 90,
    defaultColorScheme: "discipline",
    positions: {
      installer: { x: 120, y: 130 },
      repo: { x: 120, y: 270 },
      app: { x: 575, y: 130 },
      behavior: { x: 325, y: 270 },
      docs: { x: 325, y: 410 },
      map: { x: 575, y: 410 },
      mission: { x: 575, y: 270 },
      eval: { x: 790, y: 200 },
      harness: { x: 970, y: 270 },
      alog: { x: 790, y: 410 }
    }
  },
  blueprint: {
    title: "Blueprint",
    nodeShape: "round-rectangle",
    padding: 105,
    defaultColorScheme: "instrument",
    positions: {
      installer: { x: 120, y: 140 },
      repo: { x: 120, y: 280 },
      app: { x: 585, y: 140 },
      behavior: { x: 325, y: 280 },
      docs: { x: 325, y: 420 },
      map: { x: 585, y: 420 },
      mission: { x: 585, y: 280 },
      eval: { x: 810, y: 180 },
      harness: { x: 1000, y: 280 },
      alog: { x: 810, y: 420 }
    }
  },
  compact: {
    title: "Compact",
    nodeShape: "ellipse",
    padding: 70,
    defaultColorScheme: "discipline",
    positions: {
      installer: { x: 225, y: 125 },
      repo: { x: 225, y: 285 },
      app: { x: 510, y: 125 },
      behavior: { x: 225, y: 445 },
      docs: { x: 435, y: 445 },
      map: { x: 645, y: 445 },
      mission: { x: 510, y: 285 },
      eval: { x: 710, y: 285 },
      harness: { x: 850, y: 125 },
      alog: { x: 855, y: 445 }
    }
  },
  clinical: {
    title: "Clinical",
    nodeShape: "ellipse",
    padding: 95,
    defaultColorScheme: "graphite",
    positions: {
      installer: { x: 120, y: 150 },
      repo: { x: 120, y: 280 },
      app: { x: 575, y: 150 },
      behavior: { x: 330, y: 280 },
      docs: { x: 330, y: 410 },
      map: { x: 575, y: 410 },
      mission: { x: 575, y: 280 },
      eval: { x: 800, y: 205 },
      harness: { x: 985, y: 280 },
      alog: { x: 800, y: 410 }
    }
  }
};

const nodes = SKILL_GRAPH.nodes.map((node) => ({
  group: "nodes",
  data: {
    id: node.id,
    label: node.short,
    fullLabel: node.label,
    group: node.group,
    weight: node.weight
  },
  classes: node.group
}));

const links = SKILL_GRAPH.links.map((link, index) => ({
  group: "edges",
  data: {
    id: `e${index}`,
    source: link.source,
    target: link.target
  }
}));

const cy = cytoscape({
  container: document.getElementById("graph"),
  elements: [...nodes, ...links],
  style: [],
  layout: { name: "preset" }
});

function baseStyle() {
  const colors = colorSchemes[state.colorScheme];
  const labelPlacement = labelPlacements[state.labelPlacement];
  const variantName = state.variant;
  const variant = variants[variantName];
  const baseNode = variant.nodeShape === "round-rectangle" ? 5 : 4.2;
  const nodeScale = state.nodeScale;
  const edgeWidth = (variantName === "blueprint" ? 1.65 : 1.35) * state.arrowScale;
  return [
    {
      selector: "node",
      style: {
        "background-color": (ele) => colors[ele.data("group")],
        "border-color": "#ffffff",
        "border-opacity": variantName === "clinical" ? 1 : 0.86,
        "border-width": variantName === "blueprint" ? 2.2 : 1.4,
        "color": colors.label,
        "font-size": 13,
        "font-weight": 700,
        "height": (ele) => (18 + ele.data("weight") * baseNode) * nodeScale,
        "label": "data(label)",
        "shape": variant.nodeShape,
        "text-background-color": colors.labelBackground,
        "text-background-opacity": 0.9,
        "text-background-padding": 4,
        "text-border-color": "#d9e1ea",
        "text-border-opacity": 0.85,
        "text-border-width": 0.7,
        "text-halign": labelPlacement["text-halign"],
        "text-margin-x": labelPlacement["text-margin-x"],
        "text-margin-y": labelPlacement["text-margin-y"],
        "text-outline-color": colors.labelBackground,
        "text-outline-width": 1.6,
        "text-valign": labelPlacement["text-valign"],
        "width": (ele) => {
          if (variant.nodeShape === "round-rectangle") return (42 + ele.data("weight") * 8) * nodeScale;
          return (18 + ele.data("weight") * 4.2) * nodeScale;
        }
      }
    },
    {
      selector: "edge",
      style: {
        "curve-style": "bezier",
        "line-color": colors.line,
        "line-opacity": variantName === "clinical" ? 0.46 : 0.56,
        "arrow-scale": 1.15 * state.arrowScale,
        "target-arrow-color": colors.line,
        "target-arrow-fill": "filled",
        "target-arrow-shape": "triangle",
        "width": edgeWidth
      }
    },
    {
      selector: ".faded",
      style: { "opacity": 0.14 }
    },
    {
      selector: ".selectedNeighborhood",
      style: { "opacity": 1 }
    },
    {
      selector: "node.selectedNeighborhood",
      style: {
        "border-color": "#17202a",
        "border-width": 2.4
      }
    }
  ];
}

function updateHudColors() {
  const colors = colorSchemes[state.colorScheme];
  const root = document.documentElement;
  root.style.setProperty("--blue", colors.foundation);
  root.style.setProperty("--green", colors.surface);
  root.style.setProperty("--amber", colors.mission);
  root.style.setProperty("--plum", colors.evidence);
}

function updateControlValues() {
  document.getElementById("labelPlacement").value = state.labelPlacement;
  document.getElementById("colorScheme").value = state.colorScheme;
  document.getElementById("nodeScale").value = Math.round(state.nodeScale * 100);
  document.getElementById("arrowScale").value = Math.round(state.arrowScale * 100);
}

function writeUrlState() {
  const url = new URL(window.location.href);
  url.searchParams.set("variant", state.variant);
  url.searchParams.set("labels", state.labelPlacement);
  url.searchParams.set("scheme", state.colorScheme);
  url.searchParams.set("nodes", Math.round(state.nodeScale * 100));
  url.searchParams.set("arrows", Math.round(state.arrowScale * 100));
  window.history.replaceState({}, "", url);
}

function readScaleParam(params, name, fallback, min, max) {
  const rawValue = Number(params.get(name) || fallback);
  if (!Number.isFinite(rawValue)) return fallback / 100;
  return Math.min(max, Math.max(min, rawValue / 100));
}

function applyGraphState(updateUrl = true) {
  const variant = variants[state.variant] || variants.journal;
  document.getElementById("variantTitle").textContent = variant.title;
  document.getElementById("variantEyebrow").textContent = "Analysis Network";
  document.querySelectorAll(".variant-button").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.variant === state.variant);
  });
  updateHudColors();
  updateControlValues();
  cy.style(baseStyle());
  cy.nodes().forEach((node) => node.position(variant.positions[node.id()]));
  cy.elements().removeClass("faded selectedNeighborhood");
  const isReadmeExport = document.body.classList.contains("is-readme-export");
  if (isReadmeExport) {
    cy.fit(undefined, readmeExport.fitPadding);
    cy.panBy({ x: readmeExport.panX, y: readmeExport.panY });
  } else {
    cy.fit(undefined, variant.padding);
  }
  if (updateUrl) writeUrlState();
}

function setVariant(variantName, updateUrl = true) {
  state.variant = variants[variantName] ? variantName : "journal";
  state.colorScheme = variants[state.variant].defaultColorScheme;
  applyGraphState(updateUrl);
}

cy.on("tap", "node", (event) => {
  const node = event.target;
  cy.elements().addClass("faded").removeClass("selectedNeighborhood");
  node.closedNeighborhood().removeClass("faded").addClass("selectedNeighborhood");
});

cy.on("tap", (event) => {
  if (event.target === cy) cy.elements().removeClass("faded selectedNeighborhood");
});

document.querySelectorAll(".variant-button").forEach((button) => {
  button.addEventListener("click", () => setVariant(button.dataset.variant));
});

document.getElementById("labelPlacement").addEventListener("change", (event) => {
  state.labelPlacement = labelPlacements[event.target.value] ? event.target.value : "above";
  applyGraphState();
});

document.getElementById("colorScheme").addEventListener("change", (event) => {
  state.colorScheme = colorSchemes[event.target.value] ? event.target.value : "discipline";
  applyGraphState();
});

document.getElementById("nodeScale").addEventListener("input", (event) => {
  state.nodeScale = Number(event.target.value) / 100;
  applyGraphState();
});

document.getElementById("arrowScale").addEventListener("input", (event) => {
  state.arrowScale = Number(event.target.value) / 100;
  applyGraphState();
});

const params = new URLSearchParams(window.location.search);
if (params.get("export") === "readme") {
  document.body.classList.add("is-readme-export");
}
const requestedVariant = params.get("variant") || "journal";
state.variant = variants[requestedVariant] ? requestedVariant : "journal";
state.colorScheme = variants[state.variant].defaultColorScheme;
if (labelPlacements[params.get("labels")]) state.labelPlacement = params.get("labels");
if (colorSchemes[params.get("scheme")]) state.colorScheme = params.get("scheme");
state.nodeScale = readScaleParam(params, "nodes", 100, 0.7, 1.35);
state.arrowScale = readScaleParam(params, "arrows", 100, 0.7, 1.8);
applyGraphState(false);

window.addEventListener("resize", () => {
  cy.fit(undefined, variants[state.variant]?.padding || variants.journal.padding);
});
