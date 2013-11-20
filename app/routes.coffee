App.IndexRoute = Ember.Route.extend
  redirect: ->
    @transitionTo 'home'

App.TeamsIndexRoute = Ember.Route.extend
  model: ->
    @get('store').find('team')

App.SquadsIndexRoute = Ember.Route.extend
  model: ->
    @get('store').find('squad')

App.PlayersIndexRoute = Ember.Route.extend
  model: ->
    @get('store').find('player')

App.SquadsNewRoute = Ember.Route.extend
  model: ->
    @get('store').createRecord('squad', name: "test squad", team: @get('store').createRecord('team', name: "test team"))

App.SquadEditRoute = Ember.Route.extend
  model: ->
    @modelFor 'squad'
  renderTemplate: ->
    @render 'squads/edit'

App.PlayerIndexRoute = Ember.Route.extend
  model: (params) ->
    @modelFor 'player'
  renderTemplate: ->
    @render 'players/show'