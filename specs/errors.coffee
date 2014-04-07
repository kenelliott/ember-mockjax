module "Errors"

test "Errors Handling", ->
  originalName = App.Fixtures.Teams[0].name
  originalSquad = App.Fixtures.Squads[0].name
  visit("/squads/1/edit").then ->
    fillIn "#name", "Test Squad ^"
    fillIn "#team-name", "Test Team 2"
    click(".btn-primary").then ->
      equal find(".alert").length, 1, "alert section is visible"
      ok find(".alert").text().indexOf("is invalid") >= 0, "test team should be invalid"
      App.Fixtures.Teams[0].name = originalName
      App.Fixtures.Squads[0].name = originalSquad