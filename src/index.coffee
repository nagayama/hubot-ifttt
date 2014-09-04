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
        searchParams = (obj, ret) ->
          if typeof obj == "object"
            for k,v of obj
              searchParams v, ret
          else if typeof obj == "array"
            for o in obj
              searchParams o, ret
          else
            ret.push obj
            return ret

        params = searchParams result, []
        methodName = params[0]
        rooms      = params[5]
        body       = params[7]
        resValue   = ""

        switch methodName
          when "mt.supportedMethods"
            resValue = 'metaWeblog.getRecentPosts'
          when "metaWeblog.getRecentPosts"
            resValue = array: data: {}
          when "metaWeblog.newPost"
            for room in rooms.split(/,/)
              robot.messageRoom room.trim(), body
            resValue = array: data: {}
          else
            res.writeHead 401, 'Content-Type': 'text/xml; charset=utf-8'
            res.end()
            return

        xmlBuilder = new Xml2js.Builder()
        resBody = xmlBuilder.buildObject( methodResponse: params: param: value: resValue )
        res.writeHead 200, 'Content-Type': 'text/xml; charset=utf-8', 'Content-Length': resBody.length
        res.end(resBody)
