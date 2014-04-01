App.BaseModel = DS.Model.extend
  createdAt: DS.attr "date"
  updatedAt: DS.attr "date"

App.Team = App.BaseModel.extend
  name: DS.attr "string"
  squads: DS.hasMany "squad", async: true

App.Squad = App.BaseModel.extend
  name: DS.attr "string"
  players: DS.hasMany "player", async: true
  team: DS.belongsTo "team", nested: true

App.Player = App.BaseModel.extend
  name: DS.attr "string"
  squad: DS.belongsTo "squad"
  medals: DS.hasMany "medal", async: false
  weapons: DS.hasMany "weapon", async: false

App.Medal = App.BaseModel.extend
  name: DS.attr "string"
  players: DS.hasMany "player", async: true

App.Weapon = App.BaseModel.extend
  name: DS.attr "string"
  players: DS.hasMany "player", async: true
  attachments: DS.hasMany "attachment", async: false

App.Attachment = App.BaseModel.extend
  name: DS.attr "string"
