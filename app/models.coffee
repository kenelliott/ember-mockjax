App.Team = DS.Model.extend
  name: DS.attr "string"
  squads: DS.hasMany "squad", async: true

App.Squad = DS.Model.extend
  name: DS.attr "string"
  players: DS.hasMany "player", async: true
  team: DS.belongsTo "team"

App.Player = DS.Model.extend
  name: DS.attr "string"
  medals: DS.hasMany "medal", async: false
  weapons: DS.hasMany "weapon", embedded: "always"

App.Medal = DS.Model.extend
  name: DS.attr "string"
  players: DS.hasMany "player", async: true

App.Weapon = DS.Model.extend
  name: DS.attr "string"
  players: DS.hasMany "player", async: true
