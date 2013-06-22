module.exports = (grunt) ->

  grunt.initConfig
    bower:
      options:
        baseUrl: '/static/'
      target:
        rjsConfig: './static/js/config.js'

  grunt.loadNpmTasks 'grunt-bower-requirejs'

  grunt.registerTask 'default', ['bower']

