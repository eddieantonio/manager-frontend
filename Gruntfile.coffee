module.exports = (grunt) ->

  grunt.initConfig
    bower:
      target:
        rjsConfig: './static/js/config.js'

  grunt.loadNpmTasks 'grunt-bower-requirejs'

  grunt.registerTask 'default', ['bower']

