App.Router.map ->
  @route "home"
  @resource "teams", ->
    @resource "team", path: "/:team_id", ->
  @resource "squads", ->
    @route "new"
    @resource "squad", path: "/:squad_id", ->
      @route "edit"
  @resource "players", ->
    @resource "player", path: "/:player_id", ->
  @resource "medals", ->
    @resource "medal", path: "/:medal_id", ->
  @resource "weapons", ->
    @resource "weapon", path: "/:weapon_id", ->
