module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  #WakeOnLAN -> https://github.com/agnat/node_wake_on_lan
  wol = require 'wake_on_lan'
  Promise.promisifyAll(wol)

  #WakeOnLan Plugin Class
  class WakeOnLan extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      #Device Config Schema
      deviceConfigDef = require("./device-config-schema")

      #Register WakeOnLanDevice
      @framework.deviceManager.registerDeviceClass("WakeOnLanDevice", {
        configDef: deviceConfigDef.WakeOnLanDevice, 
        createCallback: (config) => new WakeOnLanDevice(config)
      })

  #WakeOnLanDevice Class
  class WakeOnLanDevice extends env.devices.ButtonsDevice

    #Avaible Actions:
    actions:
      buttonPressed:
        params:
          buttonId:
            type: "string"

    #Initiaise ButtonsDevice and create button if not defined
    constructor: (@config) ->
      @id = config.id
      @name = @config.name        
      mac = config.mac
      @config.buttons = [{"id": @id+"-btn","text": "WakeUp"}]
      #For Debuggin
      #env.logger.debug @config
      super(config)     
    
    #WakeOnLan Main Funktion -> npm wake_on_lan
    wakeUp: (mac) ->       
      #Run Wake with MAC Adress
      return wol.wakeAsync(mac).then( =>
        #Returning Info to Console and Gui
        env.logger.info "Device with mac " + mac + " was waked Up"        
      )
    
    #Handle ButtonPressed Event
    buttonPressed: (buttonId) ->
      for b in @config.buttons
        if b.id is buttonId
          @_lastPressedButton = b.id
          @emit 'button', b.id
          #For Debuggin
          #env.logger.debug b.id
          #Run WakeUp with configured Mac
          return @wakeUp(@config.mac)

      throw new Error("No button with the id #{buttonId} found")
      
  # ###Finally
  # Create a instance of my plugin
  plugin = new WakeOnLan
  # and return it to the framework.
  return plugin
