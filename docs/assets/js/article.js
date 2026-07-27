(() => {
  const timelineLayer = document.querySelector(".page-hero__timelines");
  if (timelineLayer && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    const timelines = [
      { name: "Mission Builder", top: "9%", left: "3%", length: 300, angle: 7, delay: 0, revisions: [11, 18, 32, 49, 68, 90, 96] },
      { name: "MOOS-IvP Docs", top: "15%", left: "68%", length: 260, angle: -11, delay: 2.2, revisions: [17, 41] },
      { name: "App Builder", top: "73%", left: "5%", length: 270, angle: -8, delay: 4.4, revisions: [12, 17, 42] },
      { name: "Behavior Builder", top: "84%", left: "70%", length: 260, angle: 9, delay: 6.6, revisions: [18, 42] },
      { name: "Eval Mission Builder", top: "46%", left: "1%", length: 240, angle: 15, delay: 8.8, revisions: [12, 32, 49, 81, 84, 86, 94, 97] },
      { name: "Harness Builder", top: "58%", left: "76%", length: 250, angle: -14, delay: 11, revisions: [12, 17, 32, 49, 72, 81, 86, 90] },
      { name: "ALog Analysis", top: "5%", left: "47%", length: 210, angle: -5, delay: 13.2, revisions: [49] },
      { name: "Repo Builder", top: "91%", left: "30%", length: 300, angle: 2, delay: 15.4, revisions: [9, 22, 38, 42] },
      { name: "Installer", top: "34%", left: "82%", length: 190, angle: -20, delay: 17.6, revisions: [] },
      { name: "Map Builder", top: "78%", left: "83%", length: 190, angle: 12, delay: 19.8, revisions: [] }
    ];

    timelines.forEach((entry) => {
      const timeline = document.createElement("span");
      timeline.className = "hero-timeline";
      timeline.style.setProperty("--timeline-top", entry.top);
      timeline.style.setProperty("--timeline-left", entry.left);
      timeline.style.setProperty("--timeline-length", `${entry.length}px`);
      timeline.style.setProperty("--timeline-angle", `${entry.angle}deg`);
      timeline.style.setProperty("--timeline-delay", `${entry.delay}s`);

      const origin = document.createElement("span");
      origin.className = "hero-timeline__origin";

      const start = document.createElement("span");
      start.className = "hero-timeline__start";

      const label = document.createElement("span");
      label.className = "hero-timeline__label";
      label.textContent = entry.name;

      const rail = document.createElement("span");
      rail.className = "hero-timeline__rail";

      entry.revisions.forEach((position) => {
        const revision = document.createElement("span");
        revision.className = "hero-timeline__revision";
        revision.style.left = `${position}%`;
        rail.appendChild(revision);
      });

      origin.append(start, label);
      timeline.append(origin, rail);
      timelineLayer.appendChild(timeline);
    });
  }

  const skillProfiles = Array.from(document.querySelectorAll(".skill-profile"));
  const mobileNav = document.querySelector(".mobile-nav__details");
  const navLinks = Array.from(document.querySelectorAll(".article-nav a[href^='#']"));
  const supportHeadings = new Set(["Assets", "References", "Scripts", "Common faults"]);

  const syncSkillCard = (profile) => {
    const card = profile.closest(".skill-card");
    const toggle = card?.querySelector(".skill-card__toggle");
    if (!card || !toggle) return;
    card.classList.toggle("is-open", profile.open);
    toggle.setAttribute("aria-expanded", String(profile.open));
  };

  skillProfiles.forEach((profile) => {
    const card = profile.closest(".skill-card");
    const heading = card?.querySelector(":scope > h2");
    if (!card || !heading) return;

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "skill-card__toggle";
    toggle.textContent = heading.textContent;
    toggle.id = heading.id;
    toggle.setAttribute("aria-controls", `${heading.id}-profile`);
    profile.id = `${heading.id}-profile`;
    heading.replaceWith(toggle);
    card.classList.add("skill-card--enhanced");

    toggle.addEventListener("click", () => {
      profile.open = !profile.open;
      syncSkillCard(profile);
    });

    profile.addEventListener("toggle", () => syncSkillCard(profile));
    syncSkillCard(profile);
  });

  document.querySelectorAll(".skill-profile__body h3").forEach((heading) => {
    if (supportHeadings.has(heading.textContent.trim())) {
      heading.classList.add("skill-support-heading");
    }
  });

  const setAllSkills = (open) => {
    skillProfiles.forEach((profile) => {
      profile.open = open;
      syncSkillCard(profile);
    });
  };

  document.querySelectorAll("[data-skill-action]").forEach((button) => {
    button.addEventListener("click", () => {
      setAllSkills(button.dataset.skillAction === "expand");
    });
  });

  let printOpenState = [];
  window.addEventListener("beforeprint", () => {
    printOpenState = skillProfiles.map((profile) => profile.open);
    setAllSkills(true);
  });
  window.addEventListener("afterprint", () => {
    skillProfiles.forEach((profile, index) => {
      profile.open = printOpenState[index] ?? profile.open;
    });
  });

  const openHashTarget = () => {
    if (!window.location.hash) return;

    let target;
    try {
      target = document.querySelector(window.location.hash);
    } catch {
      return;
    }

    if (!target) return;

    const profile = target.matches(".skill-card")
      ? target.querySelector(".skill-profile")
      : target.closest(".skill-profile")
        || target.closest(".skill-card")?.querySelector(".skill-profile");

    if (profile) {
      profile.open = true;
      syncSkillCard(profile);
    }

    const positionTarget = () => window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        target.scrollIntoView({ block: "start" });
      });
    });

    positionTarget();
    if (document.readyState !== "complete") {
      window.addEventListener("load", positionTarget, { once: true });
    }
  };

  openHashTarget();
  window.addEventListener("hashchange", openHashTarget);

  navLinks.forEach((link) => {
    link.addEventListener("click", () => {
      const target = document.querySelector(link.getAttribute("href"));
      const profile = target?.querySelector(".skill-profile")
        || target?.closest(".skill-card")?.querySelector(".skill-profile");
      if (profile) {
        profile.open = true;
        syncSkillCard(profile);
      }
      if (mobileNav) mobileNav.open = false;
    });
  });

  const sectionTargets = navLinks
    .map((link) => {
      const id = link.getAttribute("href").slice(1);
      return document.getElementById(id);
    })
    .filter(Boolean);

  if ("IntersectionObserver" in window && sectionTargets.length) {
    const activeSections = new Map();
    const updateActiveLink = () => {
      const visible = Array.from(activeSections.entries())
        .filter(([, entry]) => entry.isIntersecting)
        .sort((a, b) => a[1].boundingClientRect.top - b[1].boundingClientRect.top);

      if (!visible.length) return;
      const activeId = visible[0][0].id;
      navLinks.forEach((link) => {
        if (link.getAttribute("href") === `#${activeId}`) {
          link.setAttribute("aria-current", "true");
        } else {
          link.removeAttribute("aria-current");
        }
      });
    };

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => activeSections.set(entry.target, entry));
        updateActiveLink();
      },
      { rootMargin: "-12% 0px -72% 0px", threshold: [0, 1] }
    );

    sectionTargets.forEach((target) => observer.observe(target));
  }

  const chartRoot = document.getElementById("commit-activity-chart");
  if (!chartRoot) return;

  const svg = chartRoot.querySelector("svg");
  const detail = chartRoot.querySelector(".commit-chart__summary");
  const data = [
    ["2026-05-21", 7], ["2026-05-22", 0], ["2026-05-23", 0],
    ["2026-05-24", 10], ["2026-05-25", 10], ["2026-05-26", 6],
    ["2026-05-27", 1], ["2026-05-28", 0], ["2026-05-29", 0],
    ["2026-05-30", 5], ["2026-05-31", 0], ["2026-06-01", 0],
    ["2026-06-02", 0], ["2026-06-03", 0], ["2026-06-04", 0],
    ["2026-06-05", 1], ["2026-06-06", 0], ["2026-06-07", 0],
    ["2026-06-08", 0], ["2026-06-09", 0], ["2026-06-10", 0],
    ["2026-06-11", 0], ["2026-06-12", 0], ["2026-06-13", 0],
    ["2026-06-14", 0], ["2026-06-15", 1], ["2026-06-16", 1],
    ["2026-06-17", 11], ["2026-06-18", 2], ["2026-06-19", 0],
    ["2026-06-20", 7], ["2026-06-21", 2], ["2026-06-22", 0],
    ["2026-06-23", 0], ["2026-06-24", 0], ["2026-06-25", 0],
    ["2026-06-26", 0], ["2026-06-27", 0], ["2026-06-28", 0],
    ["2026-06-29", 0], ["2026-06-30", 0], ["2026-07-01", 0],
    ["2026-07-02", 0], ["2026-07-03", 0], ["2026-07-04", 0],
    ["2026-07-05", 0], ["2026-07-06", 0], ["2026-07-07", 4],
    ["2026-07-08", 0], ["2026-07-09", 2], ["2026-07-10", 0],
    ["2026-07-11", 0], ["2026-07-12", 0], ["2026-07-13", 9],
    ["2026-07-14", 0], ["2026-07-15", 2], ["2026-07-16", 4],
    ["2026-07-17", 0], ["2026-07-18", 0], ["2026-07-19", 2],
    ["2026-07-20", 0], ["2026-07-21", 0], ["2026-07-22", 1],
    ["2026-07-23", 2], ["2026-07-24", 2], ["2026-07-25", 0],
    ["2026-07-26", 0]
  ].map(([date, count]) => ({ date, count }));

  const width = 736;
  const height = 285;
  const margin = { top: 24, right: 12, bottom: 44, left: 34 };
  const plotWidth = width - margin.left - margin.right;
  const plotHeight = height - margin.top - margin.bottom;
  const sigma = 2.8;
  const radius = 9;
  const maxValue = 6;
  const step = plotWidth / data.length;
  const namespace = "http://www.w3.org/2000/svg";
  const summary = "92 commits across 22 active days · May 21–July 26, 2026 · default branch";

  const smoothed = data.map((entry, index) => {
    let weightedCount = 0;
    let totalWeight = 0;
    for (let offset = -radius; offset <= radius; offset += 1) {
      const neighbor = index + offset;
      if (neighbor < 0 || neighbor >= data.length) continue;
      const weight = Math.exp(-(offset * offset) / (2 * sigma * sigma));
      weightedCount += data[neighbor].count * weight;
      totalWeight += weight;
    }
    return { ...entry, smoothedCount: weightedCount / totalWeight };
  });

  const add = (tag, attributes, text) => {
    const element = document.createElementNS(namespace, tag);
    Object.entries(attributes || {}).forEach(([key, value]) => {
      element.setAttribute(key, value);
    });
    if (text !== undefined) element.textContent = text;
    svg.appendChild(element);
    return element;
  };

  const y = (value) => margin.top + plotHeight - (value / maxValue) * plotHeight;
  const dateLabel = (value) => new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    timeZone: "UTC"
  }).format(new Date(`${value}T00:00:00Z`));

  [0, 2, 4, 6].forEach((value) => {
    const yy = y(value);
    add("line", {
      x1: margin.left,
      x2: width - margin.right,
      y1: yy,
      y2: yy,
      class: "grid-line"
    });
    add("text", {
      x: margin.left - 7,
      y: yy + 4,
      "text-anchor": "end",
      class: "axis-label"
    }, String(value));
  });

  data.forEach((entry, index) => {
    if (entry.date.endsWith("-01")) {
      const x = margin.left + index * step + step / 2;
      add("line", {
        x1: x,
        x2: x,
        y1: margin.top,
        y2: margin.top + plotHeight,
        class: "month-line"
      });
    }
  });

  const baseline = margin.top + plotHeight;
  const points = smoothed.map((entry, index) => ({
    x: margin.left + index * step + step / 2,
    y: y(entry.smoothedCount)
  }));
  const clampY = (value) => Math.max(margin.top, Math.min(baseline, value));
  let wavePath = `M ${points[0].x} ${points[0].y}`;

  for (let index = 0; index < points.length - 1; index += 1) {
    const previous = points[Math.max(0, index - 1)];
    const current = points[index];
    const next = points[index + 1];
    const following = points[Math.min(points.length - 1, index + 2)];
    const controlOneX = current.x + (next.x - previous.x) / 6;
    const controlOneY = clampY(current.y + (next.y - previous.y) / 6);
    const controlTwoX = next.x - (following.x - current.x) / 6;
    const controlTwoY = clampY(next.y - (following.y - current.y) / 6);
    wavePath += ` C ${controlOneX} ${controlOneY}, ${controlTwoX} ${controlTwoY}, ${next.x} ${next.y}`;
  }

  const firstCurve = wavePath.indexOf(" C");
  const areaPath = `M ${points[0].x} ${baseline} L ${points[0].x} ${points[0].y}${wavePath.slice(firstCurve)} L ${points[points.length - 1].x} ${baseline} Z`;
  add("path", { d: areaPath, class: "commit-area" });
  add("path", { d: wavePath, class: "commit-wave" });
  add("line", {
    x1: margin.left,
    x2: width - margin.right,
    y1: baseline,
    y2: baseline,
    class: "axis-line"
  });

  const hoverGuide = add("line", {
    x1: points[0].x,
    x2: points[0].x,
    y1: margin.top,
    y2: baseline,
    class: "hover-guide"
  });

  data.forEach((entry, index) => {
    const zone = add("rect", {
      x: margin.left + index * step,
      y: margin.top,
      width: step,
      height: plotHeight,
      class: "hover-zone",
      "aria-label": `${dateLabel(entry.date)}: ${entry.count} ${entry.count === 1 ? "commit" : "commits"}`
    });
    zone.addEventListener("mouseenter", () => {
      const x = points[index].x;
      hoverGuide.setAttribute("x1", x);
      hoverGuide.setAttribute("x2", x);
      hoverGuide.style.opacity = "0.55";
      detail.textContent = `${dateLabel(entry.date)} · ${entry.count} ${entry.count === 1 ? "commit" : "commits"} · smoothed trend ${smoothed[index].smoothedCount.toFixed(1)}/day`;
    });
    zone.addEventListener("mouseleave", () => {
      hoverGuide.style.opacity = "0";
      detail.textContent = summary;
    });
  });

  ["2026-05-21", "2026-06-01", "2026-06-15", "2026-07-01", "2026-07-15", "2026-07-26"]
    .forEach((tickDate, tickIndex, ticks) => {
      const index = data.findIndex((entry) => entry.date === tickDate);
      const x = margin.left + index * step + step / 2;
      add("text", {
        x,
        y: height - 16,
        "text-anchor": tickIndex === 0 ? "start" : tickIndex === ticks.length - 1 ? "end" : "middle",
        class: "date-label"
      }, dateLabel(tickDate));
    });

  const peak = smoothed.reduce((best, entry) => (
    entry.smoothedCount > best.smoothedCount ? entry : best
  ), smoothed[0]);
  const peakIndex = smoothed.findIndex((entry) => entry.date === peak.date);
  add("text", {
    x: margin.left + peakIndex * step + step / 2,
    y: y(peak.smoothedCount) - 8,
    "text-anchor": "middle",
    class: "peak-label"
  }, `${peak.smoothedCount.toFixed(1)} commits/day`);

  const projectChartRoot = document.getElementById("commit-project-chart");
  if (!projectChartRoot) return;

  const projectSvg = projectChartRoot.querySelector("svg");
  const projectWidth = 736;
  const projectLeft = 48;
  const projectRight = 716;
  const projectPlotWidth = projectRight - projectLeft;
  const spanTop = 61;
  const spanGap = 15;
  const projectWaveTop = 204;
  const projectWaveBottom = 328;
  const projectTicks = [
    ["2026-05-21", "May 21"],
    ["2026-06-01", "Jun 1"],
    ["2026-06-15", "Jun 15"],
    ["2026-07-01", "Jul 1"],
    ["2026-07-15", "Jul 15"],
    ["2026-07-26", "Jul 26"]
  ];
  const projects = [
    { number: 1, start: "2026-05-21", end: "2026-07-26" },
    { number: 4, start: "2026-05-21", end: "2026-07-26" },
    { number: 6, start: "2026-06-08", end: "2026-06-30" },
    { number: 7, start: "2026-06-15", end: "2026-06-30" },
    { number: 3, start: "2026-06-18", end: "2026-07-18" },
    { number: 5, start: "2026-06-18", end: "2026-07-26" },
    { number: 2, start: "2026-06-25", end: "2026-07-01" },
    { number: 8, start: "2026-07-15", end: "2026-07-26" },
    { number: 9, start: "2026-07-21", end: "2026-07-26" }
  ];

  const addProject = (tag, attributes, text) => {
    const element = document.createElementNS(namespace, tag);
    Object.entries(attributes || {}).forEach(([key, value]) => {
      element.setAttribute(key, value);
    });
    if (text !== undefined) element.textContent = text;
    projectSvg.appendChild(element);
    return element;
  };

  const projectX = (date) => {
    const index = data.findIndex((entry) => entry.date === date);
    return projectLeft + (index / (data.length - 1)) * projectPlotWidth;
  };
  const projectY = (value) => (
    projectWaveBottom
      - (value / maxValue) * (projectWaveBottom - projectWaveTop)
  );

  addProject("text", {
    x: projectLeft,
    y: 28,
    class: "project-label"
  }, "Project activity");
  addProject("text", {
    x: projectLeft + 105,
    y: 28,
    class: "project-key"
  }, "Numbers correspond to the projects in “Skills in practice”");

  projectTicks.forEach(([date, label], index) => {
    const x = projectX(date);
    if (index > 0 && index < projectTicks.length - 1) {
      addProject("line", {
        x1: x,
        x2: x,
        y1: spanTop - 10,
        y2: projectWaveBottom,
        class: "month-line"
      });
    }
    addProject("text", {
      x,
      y: 359,
      "text-anchor": index === 0
        ? "start"
        : index === projectTicks.length - 1
          ? "end"
          : "middle",
      class: "date-label"
    }, label);
  });

  projects.forEach((project, index) => {
    const y = spanTop + index * spanGap;
    const startX = projectX(project.start);
    const endX = projectX(project.end);
    const span = addProject("rect", {
      x: startX,
      y: y - 1.5,
      width: Math.max(4, endX - startX),
      height: 3,
      rx: 1.5,
      class: "project-span"
    });
    const spanTitle = document.createElementNS(namespace, "title");
    spanTitle.textContent = `Project ${project.number}: ${project.start} through ${project.end}`;
    span.appendChild(spanTitle);
    addProject("circle", {
      cx: startX,
      cy: y,
      r: 5.5,
      class: "project-number-badge"
    });
    addProject("text", {
      x: startX,
      y: y + 3,
      "text-anchor": "middle",
      class: "project-number-label"
    }, String(project.number));
  });

  [0, 2, 4, 6].forEach((value) => {
    const yy = projectY(value);
    addProject("line", {
      x1: projectLeft,
      x2: projectRight,
      y1: yy,
      y2: yy,
      class: value === 0 ? "axis-line" : "grid-line"
    });
    addProject("text", {
      x: projectLeft - 9,
      y: yy + 4,
      "text-anchor": "end",
      class: "axis-label"
    }, String(value));
  });

  const projectPoints = smoothed.map((entry, index) => ({
    x: projectLeft + (index / (smoothed.length - 1)) * projectPlotWidth,
    y: projectY(entry.smoothedCount)
  }));
  const clampProjectY = (value) => (
    Math.max(projectWaveTop, Math.min(projectWaveBottom, value))
  );
  let projectWavePath = `M ${projectPoints[0].x} ${projectPoints[0].y}`;

  for (let index = 0; index < projectPoints.length - 1; index += 1) {
    const previous = projectPoints[Math.max(0, index - 1)];
    const current = projectPoints[index];
    const next = projectPoints[index + 1];
    const following = projectPoints[Math.min(projectPoints.length - 1, index + 2)];
    const controlOneX = current.x + (next.x - previous.x) / 6;
    const controlOneY = clampProjectY(
      current.y + (next.y - previous.y) / 6
    );
    const controlTwoX = next.x - (following.x - current.x) / 6;
    const controlTwoY = clampProjectY(
      next.y - (following.y - current.y) / 6
    );
    projectWavePath += ` C ${controlOneX} ${controlOneY}, ${controlTwoX} ${controlTwoY}, ${next.x} ${next.y}`;
  }

  const projectFirstCurve = projectWavePath.indexOf(" C");
  const projectAreaPath = (
    `M ${projectPoints[0].x} ${projectWaveBottom}`
    + ` L ${projectPoints[0].x} ${projectPoints[0].y}`
    + projectWavePath.slice(projectFirstCurve)
    + ` L ${projectPoints[projectPoints.length - 1].x} ${projectWaveBottom} Z`
  );
  addProject("path", { d: projectAreaPath, class: "commit-area" });
  addProject("path", { d: projectWavePath, class: "commit-wave" });

  const projectPeakIndex = smoothed.findIndex(
    (entry) => entry.date === peak.date
  );
  addProject("text", {
    x: projectPoints[projectPeakIndex].x,
    y: projectPoints[projectPeakIndex].y - 8,
    "text-anchor": "middle",
    class: "peak-label"
  }, `${peak.smoothedCount.toFixed(1)}/day`);
})();
