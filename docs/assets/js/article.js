(() => {
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
  const areaPath = `M ${points[0].x} ${baseline} L ${points[0].x} ${points[0].y}${wavePath.slice(firstCurve)} L ${points.at(-1).x} ${baseline} Z`;
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
})();
