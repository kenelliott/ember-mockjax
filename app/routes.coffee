App.IndexRoute = Em.Route.extend
  redirect: ->
    @transitionTo 'home'

App.TeamsIndexRoute = Em.Route.extend
  model: ->
    @get('store').find('team')

App.SquadsIndexRoute = Em.Route.extend
  model: ->
    @get('store').find('squad')

App.PlayersIndexRoute = Em.Route.extend
  model: ->
    @get('store').find('player')

App.SquadsNewRoute = Em.Route.extend
  model: ->
    @get('store').createRecord('squad', name: "test squad", team: @get('store').createRecord('team', name: "test team"))

App.SquadEditRoute = Em.Route.extend
  model: ->
    @modelFor 'squad'
  renderTemplate: ->
    @render 'squads/edit'

App.PlayerIndexRoute = Em.Route.extend
  model: (params) ->
    @modelFor 'player'
  renderTemplate: ->
    @render 'players/show'