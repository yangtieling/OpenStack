import cherrypy
import genpoem

class HelloWorld(object):
    @cherrypy.expose
    def index(self):
        return genpoem.getpe()


cherrypy.server.socket_host = '0.0.0.0'
cherrypy.quickstart(HelloWorld())
