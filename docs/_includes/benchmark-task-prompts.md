#### Task 01: BatteryWatch app

Build a MOOS application named `pBatteryWatch` that monitors `BATTERY_PERCENT` and publishes an `OK`, `LOW`, or `CRITICAL` battery state. Make its thresholds configurable, prevent state flickering near threshold boundaries, and handle invalid readings safely. While the battery is `LOW` or `CRITICAL`, publish periodic alerts until acknowledged through `BATTERY_ACK`; begin alerting again if the condition worsens.

#### Task 02: Contact-waypoint app

Build a MOOS application named `pContactWaypoint` that uses a configured contact’s reported position to update the vehicle’s active waypoint so it travels toward that contact. Make the contact identity and waypoint output configurable, update the destination as the contact moves, and handle missing or invalid contact data without publishing an invalid waypoint. Provide clear operator-facing status for the selected contact and current waypoint.

#### Task 03: Contact-intercept behavior

Build an IvP contact behavior named `BHV_ContactIntercept` that guides the vehicle toward a predicted intercept point ahead of a configured contact. Make the lead distance and activation state configurable, and handle missing or unusable contact data without producing an objective.

#### Task 04: Heading-sector behavior

Build an IvP helm behavior named `BHV_HeadingExclusion` that applies a soft penalty to a configurable heading sector while an activation MOOS variable is true. Make the excluded sector, penalty strength, and activation state configurable, and keep the behavior inactive when no sector is configured.

#### Task 05: Patrol and shadow mission

Build a standalone two-vehicle MOOS-IvP mission for `alpha` and `bravo`. Alpha should patrol a roughly rectangular route for three cycles by default, pausing at the northeast corner. Bravo should begin at its starting position, wait until released by the operator, then shadow Alpha for 20 MOOS seconds before returning directly home. Add operator buttons to deploy and return Alpha individually, deploy and return Bravo individually, and hold either vehicle in place.

#### Task 06: Mission + application

Build a standalone two-vehicle MOOS-IvP mission for `alpha` and `bravo`, and include a MOOS application named `pContactWaypoint`. Alpha should patrol a 280 meter rectangular route while Bravo runs the application and updates its active waypoint from Alpha’s reported position. The vehicles should use collision avoidance.

#### Task 07: Mission + behavior

Build a standalone two-vehicle MOOS-IvP mission for `alpha` and `bravo`, including an IvP behavior named `BHV_ContactIntercept`. Alpha should patrol a 210 meter triangular route while Bravo uses the behavior to guide toward a predicted intercept point ahead of Alpha. The vehicles should use collision avoidance.

#### Task 08: Self-evaluating mission

Build a self-evaluating MOOS-IvP mission in which a vehicle completes a 210 meter triangular route with a perfect octagon obstacle of side length 4 placed in the second leg. Use obstacle avoidance and pass/fail based on whether the vehicle hits the obstacle.

#### Task 09: Nine-case harness

Build a self-contained MOOS-IvP harness with its own self-evaluating mission in which a vehicle completes a 210 meter triangular route with a perfect octagon obstacle placed in the second leg. Use obstacle avoidance and run all nine combinations of obstacle side length (3, 6, 9) and vehicle speed (2, 4, 6). Report pass/fail for each case based on whether the vehicle hits the obstacle.

#### Task 10: Tight-loop enumeration

Analyze the mission logs and identify every instance of a tight loop for both vehicles. Report each loop with the vehicle name and start and end timestamps.

#### Task 11: Henry/Gilda diagnosis

Analyze the mission log files to determine why Henry appears to make excessive tight maneuvers near waypoints compared with Gilda.
