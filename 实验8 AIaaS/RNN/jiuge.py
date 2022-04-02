#-*-coding:utf-8 -*-
import cherrypy
import webbrowser
import os
import json
import sys
import genpoem

MEDIA_DIR = os.path.join(os.path.abspath("."), u"media")
 
class AjaxApp(object):
    @cherrypy.expose 
    def index(self):
        return open(os.path.join(MEDIA_DIR, u'index.html'))
 
    @cherrypy.expose
    def submit(self, wish):
        cherrypy.response.headers['Content-Type'] = 'application/json'
        print wish
        poem = genpoem.getpe()
        print poem
        return json.dumps(dict(wish="%s" % poem))
 

config = {'/media':
                {'tools.staticdir.on': True,
                 'tools.staticdir.dir': MEDIA_DIR,
                }
         }
    
cherrypy.server.socket_host = '0.0.0.0'
cherrypy.tree.mount(AjaxApp(), '/', config=config)
cherrypy.engine.start() 
