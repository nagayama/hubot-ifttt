# Description:
#  IFTTT xmlrpc
#
# Dependencies:
#   xml2js
#
# Configuration:
#   None
#
# Commands:
#   None
#
# URLS:
#   /hubot/ifttt/xmlrpc.php

Xml2js = require('xml2js')

module.exports = (robot) ->
  robot.router.post "/hubot/ifttt/xmlrpc.php", (req, res) ->

    rawBody = ""

    req.on 'data', (chunk) ->
      rawBody += chunk

    req.on 'end', () ->
      Xml2js.parseString rawBody, (err, result) ->
        methodName = result.methodCall.methodName.shift()
        params     = result.methodCall.params.shift().param
        methodCallArgs = []

        for param in params
          for obj in param.value
            for key, val of obj
              methodCallArgs.push val.shift()

        value = ""

        switch methodName
          when "mt.supportedMethods"
            value = 'metaWeblog.getRecentPosts'
          when "metaWeblog.getRecentPosts"
            value = array: data: {}
          when "metaWeblog.newPost"
            params = methodCallArgs[3].member
            room    = ""
            message = ""
            for param in params
              for key, val of param
                k = val.shift() if key == "name"
                v = val.shift().string.shift() if key == "value"
                room    = v if k == "title"
                message = v if k == "description"
            robot.messageRoom room, message
            value = array: data: {}
          else
            res.writeHead 401, 'Content-Type': 'text/xml; charset=utf-8'
            res.end()
            return

        res.writeHead 200, 'Content-Type': 'text/xml; charset=utf-8'
        xmlBuilder = new Xml2js.Builder()
        res_str = xmlBuilder.buildObject(
          methodResponse: params: param: value: value
        )
        res.end(res_str)
