module.exports = (grunt) ->

  # IMPORTS
  # ------------------------------------------------------------------------------------
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-ember-handlebars"

  # GLOBAL VARS
  # ------------------------------------------------------------------------------------
  path = require("path")
  lintOptions = require("./coffeelint.json").options
  srcFolder = "./app"
  devFolder = "./dev"

  # TASKS DEFINITIONS
  # ------------------------------------------------------------------------------------
  grunt.initConfig

    # Clean
    # ----------------------------------------------------------------------------------
    clean:
      all : ["#{devFolder}/*"]

    # Connect
    # ----------------------------------------------------------------------------------
    connect:
      dev:
        options:
          port: 8000
          base: "."
          keepalive: true

    # Lint
    # ----------------------------------------------------------------------------------
    coffeelint:
      options: lintOptions
      gruntfile: ["Gruntfile.coffee"]
      sources:
        files: [
          expand: true
          cwd: "#{srcFolder}"
          src: ["**/*.coffee"]
        ]

    # Copy
    # ----------------------------------------------------------------------------------
    copy:
      all:
        files: [
          {
            expand: true
            cwd: "#{srcFolder}"
            src: ["index.html"]
            dest: "#{devFolder}"
          }
          {
            expand: true
            cwd: "#{srcFolder}"
            src: ["specs.html"]
            dest: "#{devFolder}"
          }
        ]

    # Ember Templates
    # ----------------------------------------------------------------------------------
    ember_handlebars:
      compile:
        options:
          processName: (sourceFile) ->
            return sourceFile.replace("./app/templates/", "").replace(".hbs","")
        files:
          "./compiled-templates.js": "./app/templates/**/*.hbs"

    # CoffeeScript
    # ----------------------------------------------------------------------------------
    coffee:
      all:
        options:
          sourceMap: true
          sourceRoot: ""
          bare: true
        files:
          "./jquery.ember-mockjax.js": [
            "jquery.ember-mockjax.coffee"
          ]
          "./app.js": [
            "#{srcFolder}/*.coffee"
          ]
          "./specs.js": [
            "./specs/*.coffee"
          ]

    # LESS
    # ----------------------------------------------------------------------------------
    less:
      all:
        files:
          [
            {
              src: ["./app/assets/css/main.less"]
              dest: "./app/assets/css/main.css"
            }
          ]

    # Watch
    # ----------------------------------------------------------------------------------
    watch:
      options:
        livereload: true
      templates:
        files: "./app/templates/**/*.hbs"
        tasks: ["ember_handlebars"]
        options:
          nospawn: true
      coffee:
        files: "./app/**/*.coffee"
        tasks: ["coffee"]
        options:
          sourceMap: true
          sourceRoot: ""
      less:
        files: "./app/**/*.less"
        tasks: ["less:all"]
      html:
        files: "./app/**/*.html"
        tasks:  ["copy"]

  # WATCH EVENT
  # ------------------------------------------------------------------------------------
  grunt.event.on "watch", (action, filepath) ->
    cwd = "./app"
    filepath = filepath.replace cwd, ""
    isCoffee = path.extname(filepath) == ".coffee"
    isHTML = path.extname(filepath) == ".html"
    isHBS = path.extname(filepath) == ".hbs"

    if isHTML
      grunt.config.set "copy",
        templates:
          files: [
            expand: true
            cwd: cwd
            src: filepath
            dest: devFolder
          ]
      grunt.task.run "copy:templates"

    if isCoffee
      grunt.config.set "coffee",
        options: lintOptions
        changed:
          bare: false
          expand: true
          cwd: cwd
          src: filepath
          dest: "#{devFolder}/app.js"
          options:
            sourceMap: true
            sourceRoot: ""

      grunt.config.set "coffeelint",
        options: lintOptions
        newSources:
          files: [
            expand: true
            cwd: cwd
            src: filepath
          ]

      grunt.task.run "coffeelint:newSources"
      grunt.task.run "coffee:changed"

    if isHBS
      grunt.task.run "ember_handlebars"

  # REGISTERED TASKS
  # ------------------------------------------------------------------------------------
  grunt.registerTask "default", [
    "dev"
    "connect:dev"
  ]

  grunt.registerTask "dev", [
    "coffeelint"
    "clean:all"
    "coffee:all"
    "less:all"
    "copy:all"
    "ember_handlebars"
  ]