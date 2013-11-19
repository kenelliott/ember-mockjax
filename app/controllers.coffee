App.SquadsNewController = Ember.ObjectController.extend
  actions:
    save: ->
      @content.save()