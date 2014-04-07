module "Squads"

test "index [belongsTo]", ->
  visit("/squads").then ->
    equal find(".squad").length, 4, "Four squads found."
    equal find(".squad:nth(0) .team-name").text(), "Blue Team", "Squad one team name is rendered"
    equal find(".squad:nth(0) .squad-name").text(), "Squad 1", "Squad one squad name is rendered"
    equal find(".squad:nth(0) .players li").length, 3, "Squad one has three players"
    equal find(".squad:nth(1) .players li").length, 3, "Squad two has three players"
    equal find(".squad:nth(2) .players li").length, 3, "Squad three has three players"
    equal find(".squad:nth(3) .players li").length, 3, "Squad four has three players"

test "new [nested attributes]", ->
  visit("/squads/new").then ->
    fillIn "#name", "TestSquad"
    fillIn "#team-name", "TestTeam"
    click(".btn-primary").then ->
      equal find(".squad:first .team-name").text(), "TestTeam", "New squad team name is rendered"
      equal find(".squad:first .squad-name").text(), "TestSquad", "New squad name is rendered"
      App.Fixtures.Squads.pop()
      App.Fixtures.Teams.pop()

test "update [nested attributes]", ->
  originalName = App.Fixtures.Teams[0].name
  visit("/squads/1/edit").then ->
    fillIn "#name", "TestSquad"
    fillIn "#team-name", "TestTeam"
    click(".btn-primary").then ->
      equal find(".squad:last .team-name").text(), "TestTeam", "Updated squad team name is rendered"
      equal find(".squad:last .squad-name").text(), "TestSquad", "Updated squad name is rendered"
      App.Fixtures.Teams[0].name = originalName