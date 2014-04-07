App.Factories = {}

App.Factories.Teams =
  name:
    validation:
      required: true
      matches: /^[\w\s]+$/
  createdAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
  updatedAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true

App.Factories.Squads =
  name:
    validation:
      required: true
      matches: /^[\w\s]+$/
  createdAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
  updatedAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true

App.Factories.Players =
  createdAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
  updatedAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true

App.Factories.Medals =
  createdAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
  updatedAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true

App.Factories.Weapons =
  createdAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
  updatedAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true

App.Factories.Attachments =
  createdAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
  updatedAt:
    default: "2014-03-29T11:34:34.000-04:00"
    ignore: true
