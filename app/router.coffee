App.Router.map ->
  @route "home"
  @resource "teams", ->
    @route "new"
    @resource "team", path: "/:team_id", ->
      @route "edit"
  @resource "squads", ->
    @route "new"
    @resource "squad", path: "/:squad_id", ->
      @route "edit"
  @resource "players", ->
    @route "new"
    @resource "player", path: "/:player_id", ->
      @route "edit"
  @resource "medals", ->
    @route "new"
    @resource "medal", path: "/:medal_id", ->
      @route "edit"
  @resource "weapons", ->
    @route "new"
    @resource "weapon", path: "/:weapon_id", ->
      @route "edit"
