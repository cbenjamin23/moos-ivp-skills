# Behavior Implementation Patterns

## Constructor

Set descriptor/defaults, narrow the decision domain, and declare info-buffer inputs:

```cpp
BHV_Pulse::BHV_Pulse(IvPDomain domain) :
  IvPBehavior(domain)
{
  IvPBehavior::setParam("descriptor", "bhv_pulse");
  m_domain = subDomain(m_domain, "course,speed");
  addInfoVars("NAV_X, NAV_Y");
}
```

Use only the domain variables the behavior will influence. A behavior that only posts messages may not need a narrowed domain.

## setParam

Accept standard behavior parameters first unless there is a deliberate reason not to:

```cpp
bool BHV_Pulse::setParam(string param, string val)
{
  if(IvPBehavior::setParam(param, val))
    return true;

  param = tolower(param);

  if((param == "radius") && isNumber(val)) {
    m_radius = vclip_min(atof(val.c_str()), 0);
    return true;
  }
  return false;
}
```

Use `setBooleanOnString` for boolean params, `setDoubleOnString` or `isNumber` for numeric params, `strContainsWhite` for no-whitespace string params, and nearby `MBUtils` helpers for common parsing.

## onSetParamComplete

Validate required params and relationships after all mission parameters are parsed:

```cpp
void BHV_Pulse::onSetParamComplete()
{
  if(m_radius <= 0)
    postEMessage("radius must be greater than zero");
}
```

## Info Buffer Reads

Read info-buffer values with success flags:

```cpp
bool ok_x, ok_y;
double osx = getBufferDoubleVal("NAV_X", ok_x);
double osy = getBufferDoubleVal("NAV_Y", ok_y);
if(!ok_x || !ok_y) {
  postWMessage("Missing NAV_X or NAV_Y");
  return 0;
}
```

Every variable read this way should be declared with `addInfoVars()`.

## onRunState

Posting-only behavior:

```cpp
IvPFunction* BHV_Pulse::onRunState()
{
  postMessage("RANGE_PULSE", m_pulse_spec);
  return 0;
}
```

Objective-function behavior:

```cpp
IvPFunction* ipf = buildFunction();
if(ipf)
  ipf->setPWT(m_priority_wt);
else
  postEMessage("Unable to build IvP function");
return ipf;
```

## Lifecycle Hooks

Use hooks for state transitions only when needed:

- `onIdleState()`: update passive state while conditions are false.
- `onIdleToRunState()`: initialize run-specific state once.
- `onRunToIdleState()`: cleanup or post transition flags once.
- `onCompleteState()`: final posts/cleanup.
- `postConfigStatus()`: report dynamic updates.

Do not implement empty overrides unless the generator already created them and leaving them helps local style.
