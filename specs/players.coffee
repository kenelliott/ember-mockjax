module "Players"

test "index [sideloading]", ->
  visit("/players").then ->
    equal find(".player").length, 12, "Eight players are rendered."
    equal find(".player:nth(0) .weapons li").length, 2, "Two weapons are rendered."
    equal find(".player:nth(0) .medals li").length, 2, "Two medals are rendered."
    equal find(".player:nth(7) .weapons li").length, 1, "One weapon is rendered for player 8."
    equal find(".player:nth(7) .medals li").length, 3, "Three medals are rendered for player 8"

test "show [singleRecord]", ->
  visit("/players/1").then ->
    equal find(".player").length, 1, "One player is rendered."
    equal find(".player .weapons li").length, 2, "Two weapons are rendered."
    equal find(".player .medals li").length, 2, "Two medals are rendered."