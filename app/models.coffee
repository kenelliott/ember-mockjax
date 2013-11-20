App.Team = DS.Model.extend
  name: DS.attr "string"
  active: DS.attr "boolean", defaultValue: true
  squads: DS.hasMany "squad",   async: true

App.Squad = DS.Model.extend
  name: DS.attr "string"
  active: DS.attr "boolean", defaultValue: true
  players: DS.hasMany "player", async: true
  team: DS.belongsTo "team",    nested: true

App.Player = DS.Model.extend
  name: DS.attr "string"
  squad: DS.belongsTo "squad"
  active: DS.attr "boolean", defaultValue: true
  medals: DS.hasMany "medal",   async: false
  weapons: DS.hasMany "weapon", async: false

App.Medal = DS.Model.extend
  name: DS.attr "string"
  active: DS.attr "boolean", defaultValue: true
  players: DS.hasMany "player", async: true

App.Weapon = DS.Model.extend
  name: DS.attr "string"
  active: DS.attr "boolean", defaultValue: true
  players: DS.hasMany "player", async: true
