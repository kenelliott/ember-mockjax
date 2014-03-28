App.Team = DS.Model.extend
  name: DS.attr "string"
  archivedAt: DS.attr "date",   defaultValue: null
  squads: DS.hasMany "squad",   async: true

App.Squad = DS.Model.extend
  name: DS.attr "string"
  archivedAt: DS.attr "date"
  players: DS.hasMany "player", async: true
  team: DS.belongsTo "team",    nested: true

App.Player = DS.Model.extend
  name: DS.attr "string"
  squad: DS.belongsTo "squad"
  archivedAt: DS.attr "date"
  medals: DS.hasMany "medal",   async: true #async: false
  weapons: DS.hasMany "weapon", async: true #async: false

App.Medal = DS.Model.extend
  name: DS.attr "string"
  archivedAt: DS.attr "date"
  players: DS.hasMany "player", async: true

App.Weapon = DS.Model.extend
  name: DS.attr "string"
  archivedAt: DS.attr "date"
  players: DS.hasMany "player", async: true
  attachments: DS.hasMany "attachment", async: true #async: false

App.Attachment = DS.Model.extend
  name: DS.attr "string"
  archivedAt: DS.attr "date"