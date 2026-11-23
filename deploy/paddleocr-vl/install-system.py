"""Run apt through Python's HTTPS transport when apt's direct transport is blocked."""
import http.server, urllib.request, urllib.error, threading, subprocess
class Proxy(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        url=self.path
        if url.startswith('http://'): url='https://'+url[7:]
        try:
            with urllib.request.urlopen(url,timeout=120) as response:
                self.send_response(response.status)
                for key in ('Content-Length','Last-Modified','Content-Type'):
                    if response.headers.get(key):self.send_header(key,response.headers[key])
                self.end_headers()
                while True:
                    data=response.read(1024*1024)
                    if not data:break
                    self.wfile.write(data)
        except urllib.error.HTTPError as error:self.send_error(error.code)
        except Exception as error:self.send_error(502,str(error))
    def log_message(self,*args):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',8787),Proxy)
threading.Thread(target=server.serve_forever,daemon=True).start()
opts=['-o','Acquire::http::Proxy=http://127.0.0.1:8787','-o','Acquire::Retries=3']
subprocess.run(['apt-get',*opts,'update'],check=True)
subprocess.run(['apt-get',*opts,'install','-y','--no-install-recommends','libgl1','libglib2.0-0','libgomp1'],check=True)
