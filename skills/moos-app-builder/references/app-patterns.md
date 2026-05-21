# MOOS App Implementation Patterns

## AppCasting Skeleton

Prefer `AppCastingMOOSApp` for new user apps. The standard overloads are:

- `OnNewMail(MOOSMSG_LIST &NewMail)`
- `Iterate()`
- `OnConnectToServer()`
- `OnStartUp()`
- `buildReport()`
- `registerVariables()`

Call superclass methods:

```cpp
bool MyApp::OnNewMail(MOOSMSG_LIST &NewMail)
{
  AppCastingMOOSApp::OnNewMail(NewMail);
  ...
}

bool MyApp::Iterate()
{
  AppCastingMOOSApp::Iterate();
  ...
  AppCastingMOOSApp::PostReport();
  return true;
}

void MyApp::registerVariables()
{
  AppCastingMOOSApp::RegisterVariables();
  Register("NAV_X", 0);
}
```

## Mail Handling

Use `OnNewMail()` as the ingestion boundary:

```cpp
if(key == "NAV_X")
  handled = handleMailNavX(msg);
else if(key == "NAV_Y")
  handled = handleMailNavY(msg);
else if(key != "APPCAST_REQ")
  reportRunWarning("Unhandled Mail: " + key);
```

Handler methods should validate type and update state:

```cpp
bool MyApp::handleMailNavX(const CMOOSMsg& msg)
{
  if(!msg.IsDouble())
    return false;
  m_nav_x = msg.GetDouble();
  m_nav_x_set = true;
  return true;
}
```

Use `OnNewMail()` to update state, not as the main business-logic loop. Put recurring computation, summaries, timeouts, state-combining work, and state-derived publications in `Iterate()`. Publish directly from `OnNewMail()` only for trivial acknowledgments, validation feedback, or explicitly requested immediate reactions.

## Config Handling

`OnStartUp()` should parse config lines and keep original lines for warnings:

```cpp
STRING_LIST sParams;
m_MissionReader.EnableVerbatimQuoting(false);
if(!m_MissionReader.GetConfiguration(GetAppName(), sParams))
  reportConfigWarning("No config block found for " + GetAppName());

for(auto p=sParams.begin(); p!=sParams.end(); ++p) {
  string orig = *p;
  string line = *p;
  string param = tolower(biteStringX(line, '='));
  string value = line;

  bool handled = false;
  if(param == "report_interval")
    handled = setDoubleOnString(m_report_interval, value);

  if(!handled)
    reportUnhandledConfigWarning(orig);
}
```

For structured config strings, make `handleConfig*` helpers and return false for malformed input.

## Iterate Pattern

Use `Iterate()` to derive outputs from state:

```cpp
if(m_nav_x_set && m_nav_y_set) {
  double dist = hypot(m_nav_x - m_prev_x, m_nav_y - m_prev_y);
  ...
  Notify("ODOMETRY_DIST", m_total_dist);
}
```

Make first-reading, stale-data, and unset-state behavior explicit.

## AppCast Report

`buildReport()` should be compact and diagnostic:

- current config
- latest important inputs
- counters
- recent warnings or state summaries

Do not hide application logic in `buildReport()`.
