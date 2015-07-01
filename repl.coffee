#!/usr/bin/env coffee

colors = require 'colors'
_ = require 'lodash'
repl_lib = require './repl_lib'


################################################################################
# Current REPL environment - keeps track of verbose/quiet, using appsdk/churro/whatever
################################################################################
CURRENT_ENV = {}
ENV_PROPERTY_BLACKLIST = []
SET_ENV = (env) ->
  unless env?
    throw new Error "You shouldn't null out the ENV.  Make sure to return ENV from your task handlers"

  env = _.cloneDeep env

  # dont save the state of some properties
  for p in ENV_PROPERTY_BLACKLIST
    delete env[p]

  CURRENT_ENV = env

GET_ENV = (obj) ->
  env = _.assign {}, process.env, JAVA_HOME: process.env.JAVA8_HOME
  _.assign {}, env, obj

################################################################################
#  Process Status
#
#  TODO: what cool stuff can we show?
#  - Runtime
#  - PID
#  - Git branch?!
#  - Version #??
################################################################################
processes_running = ->
  repl_lib.print 'implement whats running!'

repl_lib.add_command
  name: 'ps'
  help: 'status of running processes'
  fn: processes_running

################################################################################
#  Repl Help
################################################################################
repl_help = (args) ->
  repl_lib.print 'available commands'.cyan.bold
  strs = for {name, help, usage, alias} in _.values(repl_lib.get_commands())
    str = "#{name.cyan}: #{help}\n"
    str += "usage: #{usage}\n" if usage
    str += "alias: #{alias}\n" if alias
    str

  repl_lib.print strs.join '\n'

repl_lib.add_command
  name: 'help'
  alias: 'h'
  help: "'help' helps you get help for commands such as 'help'"
  fn: repl_help

################################################################################
#  Kill task
################################################################################
repl_lib.add_command
  name: 'kill'
  alias: 'k'
  help:'kill a task'
  usage:'kill [TASK]'
  fn: -> repl_lib.print 'todo: implement kill!'

kill_running_tasks = ->
  repl_lib.print "Killing all tasks..."
  Q.all _(PROCS).keys().map(kill_task).value()

repl_lib.add_command
  name: 'killall'
  alias: 'ka'
  help:'kill all running processes'
  fn: -> repl_lib.print 'implement killall!'

################################################################################
# REPL ENV
#
# Print information about your environment
################################################################################
repl_lib.add_command
  name: 'env'
  alias: 'e'
  help: 'print information about your environment'
  fn: ->
    repl_lib.print 'ENV'.cyan.bold
    repl_lib.print ("#{k}".blue.bold+'='.gray+"#{v}".magenta for k, v of CURRENT_ENV).join('\n')

repl_lib.add_command
  name: 'set'
  alias: 's'
  help: 'set environment variable'
  usage: 'set [KEY] [VALUE]'
  fn: (k='', v='') ->
    unless k.length > 0 and v.length > 0
      repl_lib.print this.help.split('\n')[0]
      return

    repl_lib.print 'setting'.cyan.bold, "#{k}".blue.bold, 'to'.cyan.bold, "#{v}".magenta

    v = if v is 'false' then false else v
    v = if v is 'true'  then true  else v

    CURRENT_ENV[k] = v

################################################################################
# exit stacker
################################################################################
stacker_exit = ->
  repl_lib.print 'Exiting stacker...'.yellow
  # max timeout of 4s
  _.delay process.exit, 4000

  t = 0 ; delta = 200 ; words = "Going To Sleep Mode".split(' ')
  _.map words, (word) ->
    setTimeout (-> process.stdout.write "#{word.red.bold} "), t += delta

  _.delay process.exit, words.length * delta

################################################################################
# start
#
# Boots the stack
################################################################################
start = ->
  repl = repl_lib.start()
  repl.on 'exit', -> stacker_exit()

module.exports =
  start: start
  repl_lib: repl_lib