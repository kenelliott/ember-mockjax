App.rootElement = "#ember-test"
App.setupForTesting()
App.injectTestHelpers()

QUnit.testStart (details) ->
  Ember.run ->
    App.reset()
  Ember.testing = true

QUnit.testDone ->
  Ember.testing = false