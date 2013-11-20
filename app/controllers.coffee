App.SquadsNewController = Ember.ObjectController.extend
  actions:
    save: ->
      @content.save().then =>
        @transitionToRoute 'squads'

App.SquadEditController = Ember.ObjectController.extend
  actions:
    save: ->
      @content.save().then =>
        @transitionToRoute 'squads'