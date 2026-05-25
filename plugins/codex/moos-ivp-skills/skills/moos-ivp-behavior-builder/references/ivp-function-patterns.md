# IvP Function Patterns

## Choose the Builder

- Use ZAIC tools for one decision variable such as `speed`, `course`, or `depth`. This is the default for simple objective-producing behaviors.
- For heading/course objectives, normalize configured headings and enable `setValueWrap(true)` on the ZAIC.
- Use Coupler when combining two independent one-variable functions.
- Use AOF plus Reflector only for coupled objectives over two or more variables.
- Return `0` when the behavior only posts state/flags and should not influence the helm decision.

## ZAIC_PEAK Example

```cpp
#include "ZAIC_PEAK.h"

IvPFunction* BHV_MySpeed::onRunState()
{
  if(!m_domain.hasDomain("speed")) {
    postEMessage("No speed variable in the helm domain");
    return 0;
  }

  ZAIC_PEAK zaic(m_domain, "speed");
  zaic.setSummit(m_desired_speed);
  zaic.setBaseWidth(m_basewidth);
  zaic.setPeakWidth(m_peakwidth);
  zaic.setSummitDelta(m_summitdelta);

  IvPFunction* ipf = zaic.extractIvPFunction();
  if(ipf)
    ipf->setPWT(m_priority_wt);
  else
    postEMessage("Unable to generate speed IvP function");

  string warnings = zaic.getWarnings();
  if(warnings != "")
    postWMessage(warnings);

  return ipf;
}
```

For course/heading objectives, prefer angle-aware helpers and wrapped ZAIC values:

```cpp
#include "AngleUtils.h"

m_desired_heading = angle360(atof(val.c_str()));

ZAIC_PEAK zaic(m_domain, "course");
zaic.setSummit(m_desired_heading);
zaic.setBaseWidth(180);
zaic.setPeakWidth(0);
zaic.setValueWrap(true);
```

When publishing heading error, use an angle-aware difference such as `angleDiff()` instead of raw subtraction across the 0/360 boundary.

## AOF/Reflector

Use this path when utility depends on coupled variables, for example course and speed together. Inspect existing behaviors before writing a new AOF:

- `BHV_Waypoint` and related AOF/helper classes for navigation objectives.
- `BHV_AvoidCollision` or obstacle behaviors for CPA-style objectives.

Keep the AOF fast; Reflector repeatedly samples it.

## Common Pitfalls

- Returning an IPF without `setPWT(m_priority_wt)`.
- Building over `course,speed` when the behavior only affects one variable.
- Reading `NAV_X`/`NAV_Y` without declaring them in `addInfoVars()`.
- Treating missing info-buffer data as zero instead of warning and returning no IPF.
- Creating too many pieces in a Reflector path without profiling mission impact.
