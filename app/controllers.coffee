App.SquadsNewController = Em.ObjectController.extend
  actions:
    save: ->
      @content.save().then =>
        @transitionToRoute 'squads'

App.SquadEditController = Em.ObjectController.extend
  actions:
    save: ->
      @content.save().then =>
        @transitionToRoute 'squads'
      ,
      ->
        #save error