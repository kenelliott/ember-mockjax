module "Teams"

test "index [hasMany]", ->
  visit("/teams").then ->
    equal find(".team").length, 2, "Two teams found."
    equal find(".team:nth(0) .squad li").length, 2, "Team one has two squads"
    equal find(".team:nth(1) .squad li").length, 2, "Team two has two squads"