#!/usr/bin/env python3
"""Export an allowlisted benchmark snapshot and render the companion figures.

Without --benchmark-repo, render from the checked-in public chart data only.
No participant execution, grading, or benchmark-tree writes are performed.
See docs/benchmark-2026-sources.md for provenance and reproduction commands.
"""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "docs/assets/data/benchmark-2026.json"
FIGURES = ROOT / "docs/assets/images/benchmark-2026"
MODELS = ["luna-high", "terra-high", "sol-high", "astra-high"]
CONDITIONS = ["baseline", "skills"]
STAGES = ["original", "prior_audited", "runtime_only", "audited"]
TASKS = [
    "BatteryWatch app", "Contact-waypoint app", "Contact-intercept behavior",
    "Heading-sector behavior", "Patrol and shadow mission", "Mission + application",
    "Mission + behavior", "Self-evaluating mission", "Nine-case harness",
    "Tight-loop enumeration", "Henry/Gilda diagnosis",
]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def export_data(repo, source_ref):
    revision = subprocess.check_output(
        ["git", "-C", str(repo), "rev-parse", "--verify", f"{source_ref}^{{commit}}"], text=True).strip()
    # Read immutable Git objects, not a working tree another task may reorganize.
    # Batch mode avoids spawning a process for each input hash.
    with subprocess.Popen(["git", "-C", str(repo), "cat-file", "--batch"],
                          stdin=subprocess.PIPE, stdout=subprocess.PIPE) as git:
        def read(name, optional=False):
            git.stdin.write(f"{revision}:{name}\n".encode())
            git.stdin.flush()
            header = git.stdout.readline().split()
            if optional and len(header) == 2 and header[1] == b"missing":
                return None
            require(len(header) == 3 and header[1] == b"blob", f"Missing source blob: {name}")
            body = git.stdout.read(int(header[2]))
            require(git.stdout.read(1) == b"\n", "Invalid Git batch response")
            return body

        current = read("benchmark/evaluation/data/aggregate.json", optional=True)
        consolidated = current is not None
        source = Path("benchmark/evaluation/data" if consolidated else "benchmark/evaluation-440-v2.0")
        reports = Path("benchmark/evaluation") if consolidated else source
        historical = {"evaluation", "evaluation-440-v1.0", "evaluation-adversarial-v1.0",
                      "evaluation-alog-audit-v1.0", "evaluation-astra-v1.0",
                      "evaluation-task11-v2", "reviews", "ASTRA_EXTENSION.md"}

        def archived(name):
            path = Path(name)
            if consolidated and path.parts[0] == "benchmark" and path.parts[1] in historical:
                return Path("benchmark/archive").joinpath(*path.parts[1:])
            return path

        aggregate = json.loads(current if consolidated else read(source / "aggregate.json"))
        robustness = json.loads(read(source / "robustness.json"))
        process = json.loads(read(source / "process.json"))
        tasks = json.loads(read("benchmark/config/tasks.json"))["tasks"]
        require([t["id"] for t in tasks] == [f"Task-{i:02}" for i in range(1, 12)],
                "Expected eleven ordered task prompts")
        for name, digest in aggregate["input_sha256"].items():
            require(hashlib.sha256(read(archived(name))).hexdigest() == digest, f"Source hash mismatch: {name}")
        source_names = [str(source / f) for f in ["aggregate.json", "robustness.json", "process.json"]]
        source_names += [str(reports / f) for f in ["RESULTS.md", "ROBUSTNESS.md", "PROCESS.md"]]
        source_names += ["benchmark/PLAN.md", "benchmark/evaluation/PROTOCOL.md",
                         "benchmark/config/tasks.json",
                         str(archived("benchmark/evaluation/protocol/CONFORMANCE.md"))]
        source_names += [str(archived(f)) for f in [
            "benchmark/ASTRA_EXTENSION.md", "benchmark/reviews/README.md",
            "benchmark/evaluation-task11-v2/TASK.md",
            "benchmark/reviews/2026-09-06-astra-adversarial/TASK09_CONTACT_VERIFICATION.md",
        ]]
        source_hashes = {name: hashlib.sha256(read(name)).hexdigest() for name in source_names}
        git.stdin.close()
    records = aggregate["records"]
    expected = {(t, m, c, r) for t in range(1, 12) for m in MODELS
                for c in CONDITIONS for r in range(1, 6)}
    require(len(records) == 440, "Expected 440 participant records")
    require({(r["task"], r["model_id"], r["condition"], r["repetition"])
             for r in records} == expected, "Incomplete or duplicate study matrix")
    for stage in STAGES:
        for model in MODELS:
            for condition in CONDITIONS:
                group = [r for r in records if r["model_id"] == model
                         and r["condition"] == condition]
                count = sum(all(v == "met" for v in r[stage]["functionality"].values())
                            for r in group)
                require(count == aggregate["versions"][stage]["by_model"][model]
                        [condition]["completion_count"], "Completion labels disagree")

    def summary(group):
        return {
            c: {
                "runs": group[c]["runs"],
                "complete": group[c]["completion_count"],
                "conformance": group[c]["conformance_met_resolved_applicable"]["mean"],
                "conformance_half_credit": group[c]["conformance_half_credit_resolved_applicable"]["mean"],
                "conformance_labels": group[c]["conformance_labels"],
                "median_minutes": group[c]["metrics"]["elapsed_seconds"]["median"] / 60,
                "median_cost_usd": group[c]["metrics"]["estimated_cost_usd"]["median"],
                "cost_observed": group[c]["metrics"]["estimated_cost_usd"]["observed"],
            } for c in CONDITIONS
        }

    audited = aggregate["versions"]["audited"]
    data = {
        "schema_version": 2,
        "source_revision": revision,
        "source_repository": "cbenjamin23/moos-ivp-skills-benchmark-private",
        "evaluation": "evaluation-440-v2.0",
        "source_layout": "consolidated" if consolidated else "versioned",
        "source_sha256": source_hashes,
        "verified_input_hashes": len(aggregate["input_sha256"]),
        "models": MODELS,
        "task_names": TASKS,
        "task_prompts": [{"id": t["id"], "prompt": t["prompt"]} for t in tasks],
        "overall": summary(audited["overall"]),
        "by_model": {m: summary(audited["by_model"][m]) for m in MODELS},
        "by_task": {t: summary(g) for t, g in audited["by_task"].items()},
        "by_task_model": {t: {c: {"complete": g[c]["completion_count"],
                                  "runs": g[c]["runs"],
                                  "conformance": g[c]["conformance_met_resolved_applicable"]["mean"]}
                              for c in CONDITIONS}
                          for t, g in audited["by_task_model"].items()},
        "mission_case_criteria": {
            c: {criterion: {label: sum(r["audited"]["conformance"].get(criterion) == label for r in records
                                      if r["task"] == 5 and r["model_id"] == "astra-high" and r["condition"] == c)
                             for label in ["met", "partially_met", "not_met", "insufficient_evidence", "not_applicable"]}
                for criterion in ["mission.community-sublaunchers", "mission.port-overrides",
                                  "mission.operator-visible-stack", "mission.documentation"]}
            for c in CONDITIONS
        },
        "application_case_criteria": {
            c: {criterion: {label: sum(r["audited"]["conformance"].get(criterion) == label for r in records
                                      if r["task"] == 1 and r["model_id"] == "astra-high" and r["condition"] == c)
                             for label in ["met", "partially_met", "not_met", "insufficient_evidence", "not_applicable"]}
                for criterion in ["app.startup-configuration", "app.iterate-ownership",
                                  "app.mail-registration", "app.appcasting-diagnostics"]}
            for c in CONDITIONS
        },
        "stages": {s: {"overall": robustness["versions"][s]["overall"],
                       "bootstrap": robustness["versions"][s]["stratified_bootstrap"]}
                   for s in STAGES},
        "robustness": robustness["versions"]["audited"],
        "process": {m: {c: {
            "runs": process[m][c]["runs"],
            "primary_route": process[m][c]["observed_primary_route"],
            "full_route": process[m][c]["observed_full_prescribed_route"],
            "live_validation": process[m][c]["validation_categories"].get("live_run", 0),
            "skill_first": process[m][c]["trajectory"]["Initial orientation"].get("skill_first", 0),
        } for c in CONDITIONS} for m in MODELS},
        "notes": [
            "Accepted post-hoc Task 11 interpretation; earlier stages retained.",
            "Conformance is mean per-run met / resolved applicable criteria, no partial credit.",
            "Costs are frozen standard API-equivalent estimates, not invoices or current prices.",
            "One Astra skills run lacks a usage receipt; its cost is unknown, not zero.",
            "Astra is a later extension with a different CLI; cross-model comparisons are descriptive.",
            "Only numeric summaries, task prompts, and source identifiers are exported; no raw transcripts.",
        ],
    }
    DATA.parent.mkdir(parents=True, exist_ok=True)
    DATA.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print(f"Verified {len(records)} records and {data['verified_input_hashes']} source hashes.")
    return data


def write_task_prompts(data):
    """Keep the article's exact task wording tied to the public source snapshot."""
    blocks = []
    for task, name in zip(data["task_prompts"], data["task_names"], strict=True):
        blocks.append(f'#### {task["id"].replace("Task-", "Task ")}: {name}\n\n{task["prompt"]}')
    (ROOT / "docs/_includes/benchmark-task-prompts.md").write_text("\n\n".join(blocks) + "\n")


def render(data):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib import font_manager
    from matplotlib.colors import LinearSegmentedColormap
    from matplotlib.patches import Patch
    from matplotlib.lines import Line2D
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont
    import numpy as np

    FIGURES.mkdir(parents=True, exist_ok=True)
    # Embed the exact article font as SVG outlines, including offline exports.
    with tempfile.TemporaryDirectory(prefix="moos-chart-font-") as font_dir:
        for weight in (400, 700):
            font = TTFont(ROOT / "docs/assets/fonts/PlusJakartaSans.ttf")
            # SVG glyphs are cached by PostScript name. Retaining the variable
            # font's Regular name for both weights silently mixes glyph weights.
            font = instantiateVariableFont(font, {"wght": weight}, inplace=True,
                                           updateFontNames=True)
            expected_style = "Regular" if weight == 400 else "Bold"
            require(font["name"].getDebugName(6) == f"PlusJakartaSans-{expected_style}",
                    "Chart font weights must have distinct PostScript names")
            path = Path(font_dir) / f"jakarta-{weight}.ttf"
            font.save(path)
            font_manager.fontManager.addfont(str(path))
        plt.rcParams.update({
            "font.family": "Plus Jakarta Sans", "font.size": 11,
            "text.color": "#172b3c", "axes.labelcolor": "#526b7e",
            "xtick.color": "#526b7e", "ytick.color": "#172b3c",
            "axes.edgecolor": "#cdd9e2", "axes.spines.top": False,
            "axes.spines.right": False, "axes.spines.left": False,
            "axes.spines.bottom": False, "xtick.major.size": 0,
            "ytick.major.size": 0, "svg.hashsalt": "moos-benchmark-2026",
            "svg.fonttype": "path", "savefig.dpi": 180,
        })
        colors = {"baseline": "#b2c3d2", "skills": "#154871"}
        ink, muted, line = "#172b3c", "#526b7e", "#cdd9e2"

        def canvas(title, subtitle, height=5.4):
            fig = plt.figure(figsize=(10, height), facecolor="#f4f8fb")
            # The release article's pale blue-to-green chart surface.
            bg = fig.add_axes([0, 0, 1, 1], zorder=-1)
            bg.imshow(np.linspace(0, 1, 256)[None, :], aspect="auto", extent=[0, 1, 0, 1],
                      cmap=LinearSegmentedColormap.from_list("paper", ["#e7f3fa", "#edf8f5"]),
                      interpolation="bilinear")
            bg.set_axis_off()
            fig.text(.04, 1 - .38/height, title, fontsize=17, fontweight="bold", color="#0e3c65")
            fig.text(.04, 1 - .68/height, subtitle, fontsize=10, color=muted)
            fig.text(.04, .16/height, "MOOS-IvP Skills  /  440-run benchmark", fontsize=8, color=muted)
            return fig

        def axis(fig, rect, maximum=100, percent=True):
            ax = fig.add_axes(rect, facecolor="none")
            ax.set_axisbelow(True)
            ax.tick_params(axis="y", pad=10)
            ax.grid(axis="x", color=line, linewidth=.7, linestyle=(0, (3, 4)))
            ax.set_xlim(0, maximum)
            if percent:
                ax.set_xticks([0, 25, 50, 75, 100], ["0%", "25%", "50%", "75%", "100%"])
            return ax

        def legend(fig, y):
            fig.legend(handles=[Patch(facecolor=colors[c], edgecolor="#5f7486" if c == "baseline" else colors[c],
                                      linewidth=.7, label=c.capitalize()) for c in CONDITIONS],
                       loc="upper left", bbox_to_anchor=(.03, y), ncol=2,
                       frameon=False, fontsize=10, handlelength=1.1)

        def save(fig, name):
            fig.savefig(FIGURES / f"{name}.svg", metadata={"Date": None, "Title": fig.texts[0].get_text()})
            fig.savefig(FIGURES / f"{name}.png", metadata={"Software": "Matplotlib"})
            plt.close(fig)

        def grouped(name, title, subtitle, groups, labels, key, fmt, height=5.4):
            fig = canvas(title, subtitle, height)
            legend(fig, 1 - .82/height)
            left = .38 if any(len(label) > 12 for label in labels) else .15
            ax = axis(fig, [left, .65/height, .94-left, 1-2.05/height])
            y = np.arange(len(groups))
            for i, c in enumerate(CONDITIONS):
                values = [g[c][key] if key == "conformance" else g[c]["complete"]/g[c]["runs"] for g in groups]
                yy = y + (-.17 if i == 0 else .17)
                ax.barh(yy, np.array(values)*100, height=.26, color=colors[c],
                        edgecolor="#5f7486" if c == "baseline" else colors[c], linewidth=.6)
                for j, value in enumerate(values):
                    ax.text(value*100-1.3, yy[j], fmt(groups[j][c]), va="center", ha="right",
                            color=ink if c == "baseline" else "white", fontsize=10,
                            fontweight="normal")
            ax.set_yticks(y, labels)
            ax.invert_yaxis()
            save(fig, name)

        fig=canvas("Completion and conformance by model",
                   "55 attempts with and 55 without skills per model · completion and mean conformance",5.7)
        legend(fig,.86)
        for rect,field,title in [([.14,.14,.34,.55],"complete","Functional completion"),
                                 ([.60,.14,.34,.55],"conformance","Engineering conformance")]:
            ax=axis(fig,rect)
            ax.set_title(title,loc="left",fontsize=12,fontweight="bold",pad=16)
            for j,c in enumerate(CONDITIONS):
                groups=[data["by_model"][m][c] for m in MODELS]
                values=[g["complete"]/g["runs"] if field=="complete" else g["conformance"] for g in groups]
                yy=np.arange(4)+(-.17 if j==0 else .17)
                ax.barh(yy,np.array(values)*100,height=.26,color=colors[c],edgecolor="#5f7486",linewidth=.5)
                for i,v in enumerate(values):
                    label=f'{groups[i]["complete"]}/55' if field=="complete" else f'{v*100:.1f}%'
                    ax.text(v*100-2,yy[i],label,ha="right",va="center",fontsize=10,
                            color=ink if c=="baseline" else "white")
            ax.set_yticks(range(4),[m.split("-")[0].title() for m in MODELS] if field=="complete" else [])
            ax.invert_yaxis()
        save(fig,"model-completion")
        fig = canvas("Completion and conformance by task",
                     "20 attempts per task and condition · connected points compare baseline with skills", 9)
        fig.legend(handles=[Line2D([], [], marker=marker, linestyle="none", markersize=7,
                                   markerfacecolor=colors[c], markeredgecolor="#5f7486",
                                   label=c.capitalize())
                            for c, marker in zip(CONDITIONS, ["o", "D"])],
                   loc="upper left", bbox_to_anchor=(.03, .91), ncol=2,
                   frameon=False, fontsize=10)
        for left, field, title in [(.33, "complete", "Functional completion"),
                                    (.68, "conformance", "Engineering conformance")]:
            ax = axis(fig, [left, .11, .27, .68])
            ax.set_title(title, loc="left", fontsize=10.5, fontweight="bold", pad=25)
            ax.set_xticks([0, 50, 100], ["0%", "50%", "100%"])
            for i in range(11):
                group = data["by_task"][f"task-{i+1:02}"]
                values = [100 * (group[c]["complete"] / group[c]["runs"]
                                 if field == "complete" else group[c]["conformance"])
                          for c in CONDITIONS]
                ax.plot(values, [i, i], color="#849eaf", linewidth=1.6, zorder=2)
                for c, marker, value in zip(CONDITIONS, ["o", "D"], values):
                    ax.plot(value, i, marker=marker, color=colors[c],
                            markersize=8 if c == "baseline" else 6,
                            markeredgecolor="#5f7486", markeredgewidth=.6, clip_on=False)
                    label = f'{group[c]["complete"]}/20' if field == "complete" else f'{value:.1f}%'
                    ax.annotate(label, (value, i), xytext=(0, 8 if c == "baseline" else -14),
                                textcoords="offset points", ha="center", fontsize=10,
                                color=muted if c == "baseline" else colors[c])
            ax.set_yticks(range(11), [f"{i:02}  {name}" for i, name in enumerate(TASKS, 1)]
                          if field == "complete" else [])
            ax.set_ylim(10.65, -.65)
        fig.text(.04, .055, "Completion: fully complete runs / 20. Conformance: mean share of engineering criteria fully met.",
                 fontsize=9, color=muted)
        save(fig, "task-completion")
        grouped("model-conformance", "Conformance where every attempt is complete",
                "Each comparison: all five attempts complete · bars show mean conformance",
                [data["by_task_model"][key] for key in ["task-01/astra-high","task-02/sol-high","task-05/astra-high"]],
                ["Task 01 · Astra · BatteryWatch", "Task 02 · Sol · Contact waypoint", "Task 05 · Astra · Patrol / shadow"],
                "conformance", lambda g: f'{100*g["conformance"]:.1f}%')

        fig = canvas("Completion by task and model", "Completed runs out of five · B = baseline, S = skills", 8.2)
        ax = fig.add_axes([.33, .10, .63, .72])
        cells = [[data["by_task_model"][f"task-{t:02}/{m}"][c]["complete"] for m in MODELS for c in CONDITIONS]
                 for t in range(1,12)]
        cmap = LinearSegmentedColormap.from_list("moos", ["#eaf2f8", "#b2c3d2", "#154871"])
        ax.imshow(cells, vmin=0, vmax=5, cmap=cmap, aspect="auto")
        ax.set_xticks(range(8), [c for m in MODELS for c in ["B", "S"]])
        ax.xaxis.tick_top()
        ax.set_yticks(range(11), [f"{i:02}  {name}" for i,name in enumerate(TASKS,1)])
        for i,m in enumerate(MODELS):
            ax.text(i*2+.5, -1.14, m.split("-")[0].title(), ha="center", fontsize=11, fontweight="bold")
        for i,row in enumerate(cells):
            for j,v in enumerate(row):
                ax.text(j,i,str(v),ha="center",va="center",color="white" if v>=4 else ink,fontsize=12)
        for x in [1.5,3.5,5.5]:
            ax.axvline(x, color="#f4f8fb", linewidth=5)
        for y in np.arange(.5,10.6):
            ax.axhline(y, color="#f4f8fb", linewidth=2)
        save(fig, "task-model-completion")

        fig = canvas("Completion across repeated attempts",
                     "44 task–model combinations per condition · five attempts at each combination", 5.4)
        shades = ["#eaf2f8", "#cddce6", "#a9c4d4", "#75a2b9", "#427c9b", "#154871"]
        fig.legend(handles=[Patch(facecolor=shade, edgecolor="#849eaf", linewidth=.5,
                                  label=f"{n}/5 complete") for n, shade in enumerate(shades)],
                   loc="upper left", bbox_to_anchor=(.03, .84), ncol=3,
                   frameon=False, fontsize=9, handlelength=1.1)
        ax = axis(fig, [.16, .23, .78, .37], 44, False)
        ax.set_xticks([0, 11, 22, 33, 44])
        ax.set_xlabel("Number of task–model combinations", fontsize=10, labelpad=12)
        for y, c in enumerate(CONDITIONS):
            left = 0
            for n, shade in enumerate(shades):
                count = sum(g[c]["complete"] == n for g in data["by_task_model"].values())
                ax.barh(y, count, left=left, height=.42, color=shade,
                        edgecolor="#f4f8fb", linewidth=1)
                ax.text(left + count / 2, y, str(count), ha="center", va="center",
                        color="white" if n >= 4 else ink, fontsize=11)
                left += count
        ax.set_yticks([0, 1], ["Baseline", "Skills"])
        ax.set_ylim(1.65, -.65)
        save(fig, "repeated-completion")

        fig = canvas("Elapsed time and estimated cost",
                     "Middle value across measured runs · costs estimated at the recorded historical rates", 8.1)
        legend(fig, .89)
        for rect,key,maximum,title,fmt in [
            ([.16,.52,.74,.29], "median_minutes", 13, "Elapsed time per attempt (minutes)", lambda x:f"{x:.2f}"),
            ([.16,.12,.74,.29], "median_cost_usd", 3.15, "Estimated API-equivalent USD", lambda x:f"${x:.3f}"),
        ]:
            ax=axis(fig,rect,maximum,False)
            ax.set_title(title,loc="left",fontsize=11,fontweight="bold",pad=12)
            y=np.arange(4)
            for j,c in enumerate(CONDITIONS):
                values=[data["by_model"][m][c][key] for m in MODELS]
                yy=y+(-.16 if j==0 else .16)
                ax.barh(yy,values,height=.25,color=colors[c],edgecolor="#5f7486",linewidth=.5)
                for i,v in enumerate(values):
                    ax.text(v+.06,yy[i],fmt(v),va="center",fontsize=10)
            ax.set_yticks(y,[m.split("-")[0].title() for m in MODELS]); ax.invert_yaxis()
        fig.text(.16,.065,"Cost observations: 55 per group, except Astra skills (54). Missing cost is excluded.",fontsize=9,color=muted)
        save(fig,"participant-efficiency")

        fig=canvas("Completion differences across grading revisions",
                   "Skills minus baseline completion · points = difference · lines = 95% bootstrap intervals",5.6)
        ax=axis(fig,[.31,.19,.60,.55],26,False)
        ax.set_xticks([0,5,10,15,20,25],["0%","+5%","+10%","+15%","+20%","+25%"])
        ax.axvline(0,color=muted,linewidth=1)
        for i,s in enumerate(STAGES):
            g=data["stages"][s]; x=100*g["overall"]["difference"]
            lo,hi=[100*v for v in g["bootstrap"]["interval_95"]]
            ax.plot([lo,hi],[i,i],color="#2b658e",linewidth=2)
            ax.plot(x,i,"o",color=colors["skills"],markersize=8)
            ax.text(x,i-.20,f"+{x:.1f}%",ha="center",fontsize=11)
        ax.set_yticks(range(4),["Original grading", "Earlier correction", "Runtime corrections", "Final revision"])
        ax.set_ylim(3.55,-.6)
        fig.text(.04,.10,"Difference between rates · resampled attempts within the same tasks and models",fontsize=9,color=muted)
        save(fig,"grading-sensitivity")

        fig=canvas("Recorded live-validation attempts",
                   "Attempts with recorded execution checks · running a check does not establish correctness",5.4)
        legend(fig,.84)
        ax=axis(fig,[.15,.15,.77,.56],55,False)
        ax.set_xticks([0,10,20,30,40,50,55])
        for j,c in enumerate(CONDITIONS):
            values=[data["process"][m][c]["live_validation"] for m in MODELS]
            yy=np.arange(4)+(-.17 if j==0 else .17)
            ax.barh(yy,values,height=.26,color=colors[c],edgecolor="#5f7486",linewidth=.5)
            for i,v in enumerate(values):
                ax.text(v+1,yy[i],f"{v}/55",va="center",fontsize=10)
        ax.set_yticks(range(4),[m.split("-")[0].title() for m in MODELS]);ax.invert_yaxis()
        save(fig,"observed-validation")

        social = plt.figure(figsize=(12, 6.3), dpi=100, facecolor="#0e3c65")
        bg = social.add_axes([0, 0, 1, 1])
        bg.imshow(np.linspace(0, 1, 512)[None, :], aspect="auto", extent=[0, 1, 0, 1],
                  cmap=LinearSegmentedColormap.from_list("hero", ["#0a3155", "#174f77", "#16796e"]))
        bg.set_axis_off()
        social.text(.06,.61,"Benchmarking\nMOOS-IvP Skills",color="white",fontsize=42,fontweight="bold",linespacing=1.15)
        social.text(.06,.45,"Completion and engineering conformance with and without skills",color="#d9e7f0",fontsize=17)
        for x,field,title in [(.06,"complete","Functional completion"),(.54,"conformance","Engineering conformance")]:
            values=[data["overall"][c]["complete"]/data["overall"][c]["runs"]
                    if field=="complete" else data["overall"][c]["conformance"] for c in CONDITIONS]
            social.text(x,.29,title,color="#d9e7f0",fontsize=16)
            social.text(x,.17,f"{100*values[0]:.1f}% → {100*values[1]:.1f}%",color="white",fontsize=26,fontweight="bold")
            social.text(x,.09,"Baseline → skills",color="#d9e7f0",fontsize=13)
        social.savefig(FIGURES / "social.png",dpi=100,metadata={"Software":"Matplotlib"})
        plt.close(social)
    print(f"Rendered eight SVG/PNG figure pairs in {FIGURES.relative_to(ROOT)}")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--benchmark-repo",type=Path,help="Verify and export from this private source checkout")
    parser.add_argument("--source-ref",default="b471d1bb5324953f3b0151c725a70a9b2b51bc7a",
                        help="Committed benchmark snapshot; working-tree changes are ignored")
    parser.add_argument("--data-only",action="store_true",help="Skip plotting (standard library only)")
    args=parser.parse_args()
    data=export_data(args.benchmark_repo.resolve(), args.source_ref) if args.benchmark_repo else json.loads(DATA.read_text())
    write_task_prompts(data)
    if not args.data_only:
        render(data)


if __name__ == "__main__":
    main()
