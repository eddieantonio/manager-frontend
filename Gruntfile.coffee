# Gruntfile!

STATIC_DIR = 'static'
JS_DIR = "#{STATIC_DIR}/js"

module.exports = (grunt) ->
  
  utils = require('./gruntutils')(grunt)

  grunt.initConfig
    #pkg: grunt.file.readJSON 'package.json'
    bowerrc: grunt.file.readJSON '.bowerrc'

    requirejsconfig:
      dev:
        src: "#{JS_DIR}/app.configless.js"
        dest: "#{JS_DIR}/app.js"
        options:
          shim: utils.requireShim
          paths: utils.createVendorPaths '../vendor'

    shell:
      # Make hard links to Bootstrap icon sprites.
      'copy-icons':
        command: 'ln <%= bowerrc.directory %>/bootstrap/img/*.png static/img/'

  grunt.loadNpmTasks 'grunt-requirejs-config'
  grunt.loadNpmTasks 'grunt-shell'

  # TASKS
  grunt.registerTask 'default', ['test-grunt']
  grunt.registerTask 'test-grunt', []
  grunt.registerTask 'setup', ['requirejsconfig:dev']
  #grunt.registerTask 'production', ['bower']


