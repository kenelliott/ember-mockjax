App.rootElement = "#ember-test"
App.setupForTesting()
App.injectTestHelpers()

QUnit.testStart (details) ->
  Ember.run ->
    App.reset()
  Ember.testing = true

QUnit.testDone ->
  Ember.run ->
    App.Notifications.clear()
  Ember.testing = false