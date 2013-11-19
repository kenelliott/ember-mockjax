App.IndexRoute = Ember.Route.extend
  redirect: -> @transitionTo 'home'

App.TeamsIndexRoute = Ember.Route.extend
  model: ->
    @get('store').find('team')

App.SquadsIndexRoute = Ember.Route.extend
  model: ->
    @get('store').find('squad')