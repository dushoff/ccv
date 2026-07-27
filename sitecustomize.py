
import ssl
try:
    ssl._create_default_https_context = ssl._create_unverified_context
except AttributeError:
    pass

try:
    import urllib3
    urllib3.disable_warnings()
    from urllib3.util import ssl_ as _ssl_
    _ssl_.DEFAULT_CERT_REQS = ssl.CERT_NONE
except ImportError:
    pass

try:
    import requests
    _orig_request = requests.Session.request
    def _patched_request(self, *args, **kwargs):
        kwargs.setdefault('verify', False)
        return _orig_request(self, *args, **kwargs)
    requests.Session.request = _patched_request
except ImportError:
    pass
