App = Ember.Application.create()

App.ApplicationAdapter = DS.ActiveModelAdapter.extend()
App.Router.map ->
  @route "app"