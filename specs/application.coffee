module "Application"

test "application layout", ->
  visit("/").then ->
    ok find(".ember-view .btn-primary").length, "Repo button is rendered"
    ok find(".ember-view .container").length, "Main container is rendered"
  	ok find(".ember-view").length, "Qunit is ready"
