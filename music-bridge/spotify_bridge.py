"""Private Spotify Connect controller. Standard library, loopback only, PKCE OAuth.

Spotify access/refresh tokens stay in this process, never in Roblox or its workspace.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlsplit
from urllib.request import Request, urlopen

PORT = 8974
REDIRECT = f'http://127.0.0.1:{PORT}/callback'
SCOPES = 'user-read-playback-state user-read-currently-playing user-modify-playback-state'


class BridgeError(Exception):
    def __init__(self, message, status=400, retry_after=None):
        super().__init__(message)
        self.status, self.retry_after = status, retry_after


def remote(url, method='GET', data=None, headers=None):
    try:
        with urlopen(Request(url, data=data, headers=headers or {}, method=method), timeout=12) as response:
            body = response.read(2_000_000)
            return json.loads(body) if body else {}
    except HTTPError as error:
        messages = {401: 'Spotify: подключи аккаунт заново', 403: 'Spotify: проверь Premium, доступ приложения и разрешения',
                    404: 'Открой Spotify на выбранном ПК и включи трек один раз', 429: 'Spotify: лимит запросов, подожди'}
        delay = error.headers.get('Retry-After', '30')
        raise BridgeError(messages.get(error.code, 'Spotify временно недоступен'), error.code,
                          min(3600, max(1, int(delay))) if error.code == 429 and delay.isdigit() else None) from None
    except (URLError, TimeoutError, OSError, ValueError):
        raise BridgeError('Нет ответа от Spotify. Проверь подключение', 502) from None


def track_view(item):
    if not isinstance(item, dict) or item.get('type', 'track') != 'track':
        return None
    uri = item.get('uri', '')
    if not re.fullmatch(r'spotify:track:[A-Za-z0-9]{22}', uri):
        return None
    album = item.get('album') or {}
    images = album.get('images') or []
    return {'uri': uri, 'title': str(item.get('name', ''))[:200],
            'artist': ', '.join(str(a.get('name', '')) for a in item.get('artists', []))[:200],
            'album': str(album.get('name', ''))[:200],
            'image': images[-1].get('url', '') if images else '',
            'url': (item.get('external_urls') or {}).get('spotify', '')}


class Spotify:
    def __init__(self, client_id):
        if not re.fullmatch(r'[a-fA-F0-9]{32}', client_id):
            raise ValueError('Нужен Client ID приложения Spotify: 32 символа. Не Client Secret.')
        self.client_id = client_id
        self.pair = secrets.token_urlsafe(32)
        self.access, self.refresh, self.expires = None, None, 0
        self.pending = None
        self.lock = threading.RLock()
        self.cache = {}
        self.retry_until = 0

    def begin(self):
        verifier, state = secrets.token_urlsafe(64), secrets.token_urlsafe(32)
        challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b'=').decode()
        with self.lock:
            self.pending = (state, verifier, time.monotonic())
        return 'https://accounts.spotify.com/authorize?' + urlencode({
            'client_id': self.client_id, 'response_type': 'code', 'redirect_uri': REDIRECT,
            'scope': SCOPES, 'state': state, 'code_challenge_method': 'S256', 'code_challenge': challenge})

    def exchange(self, state, code, denied=False):
        with self.lock:
            pending = self.pending
            if not pending or time.monotonic() - pending[2] > 600 or not secrets.compare_digest(state, pending[0]):
                raise BridgeError('Ссылка входа устарела. Нажми Connect в клиенте заново')
            self.pending = None
            if denied or not code:
                raise BridgeError('Доступ Spotify не предоставлен')
            self.token({'grant_type': 'authorization_code', 'code': code,
                        'redirect_uri': REDIRECT, 'code_verifier': pending[1]})

    def token(self, data):
        result = remote('https://accounts.spotify.com/api/token', 'POST',
                        urlencode({**data, 'client_id': self.client_id}).encode(),
                        {'Content-Type': 'application/x-www-form-urlencoded'})
        if not isinstance(result.get('access_token'), str):
            raise BridgeError('Spotify не выдал доступ', 401)
        self.access = result['access_token']
        self.refresh = result.get('refresh_token', self.refresh)
        self.expires = time.monotonic() + max(1, int(result.get('expires_in', 3600))) - 30
        self.cache.clear()

    def api(self, path, method='GET', data=None):
        with self.lock:
            if time.monotonic() < self.retry_until:
                raise BridgeError('Spotify: подожди после лимита запросов', 429, max(1, int(self.retry_until - time.monotonic())))
            if not self.access:
                raise BridgeError('Нажми Connect и разреши доступ Spotify в браузере', 401)
            if time.monotonic() >= self.expires and self.refresh:
                self.token({'grant_type': 'refresh_token', 'refresh_token': self.refresh})
            payload = json.dumps(data).encode() if data is not None else (b'' if method != 'GET' else None)
            for attempt in range(2):
                try:
                    return remote('https://api.spotify.com/v1' + path, method, payload,
                                  {'Authorization': 'Bearer ' + self.access, 'Content-Type': 'application/json'})
                except BridgeError as error:
                    if error.status == 401 and self.refresh and attempt == 0:
                        self.token({'grant_type': 'refresh_token', 'refresh_token': self.refresh})
                        continue
                    if error.status == 429:
                        self.retry_until = time.monotonic() + (error.retry_after or 30)
                    raise

    def cached(self, name, seconds, fn):
        with self.lock:
            prior = self.cache.get(name)
            if prior and time.monotonic() - prior[0] < seconds:
                return prior[1]
            value = fn()
            if len(self.cache) >= 32:
                self.cache.pop(next(iter(self.cache)))
            self.cache[name] = (time.monotonic(), value)
            return value

    def devices(self):
        return self.cached('devices', 5, lambda: [
            {'id': d['id'], 'name': str(d.get('name', 'PC'))[:100], 'active': d.get('is_active', False)}
            for d in self.api('/me/player/devices').get('devices', [])
            if d.get('id') and d.get('type') == 'Computer' and not d.get('is_restricted')])

    def dispatch(self, path, data):
        if path == '/connect':
            return {'authorize_url': self.begin()}
        if path == '/status':
            def read():
                state = self.api('/me/player')
                return {'connected': True, 'playing': state.get('is_playing', False),
                        'track': track_view(state.get('item')), 'progress_ms': state.get('progress_ms', 0),
                        'device': str((state.get('device') or {}).get('name', ''))[:100]}
            return self.cached('status', 5, read)
        if path == '/search':
            query = data.get('query')
            if not isinstance(query, str) or not 1 <= len(query.strip()) <= 150:
                raise BridgeError('Введи исполнителя, группу или трек')
            query = query.strip()
            return {'tracks': self.cached('search:' + query, 60, lambda: [
                view for item in self.api('/search?' + urlencode({'q': query, 'type': 'track', 'limit': 10})).get('tracks', {}).get('items', [])
                if (view := track_view(item))])}
        if path == '/devices':
            return {'devices': self.devices()}
        if path == '/control':
            action, device = data.get('action'), data.get('device_id')
            if not isinstance(device, str) or not any(d['id'] == device for d in self.devices()):
                raise BridgeError('Нажми Devices и выбери свой компьютер')
            suffix = '?' + urlencode({'device_id': device})
            if action == 'play':
                uri = data.get('uri')
                if uri is not None and (not isinstance(uri, str) or not re.fullmatch(r'spotify:track:[A-Za-z0-9]{22}', uri)):
                    raise BridgeError('Некорректный трек')
                self.api('/me/player/play' + suffix, 'PUT', {'uris': [uri]} if uri else {})
            elif action in ('pause', 'stop'):
                self.api('/me/player/pause' + suffix, 'PUT')
                if action == 'stop':
                    self.api('/me/player/seek' + suffix + '&position_ms=0', 'PUT')
            else:
                raise BridgeError('Неизвестное действие')
            self.cache.pop('status', None)
            return {'ok': True}
        raise BridgeError('Неизвестный запрос', 404)


def handler_for(spotify):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # Never log authorization codes, tokens or music searches.

        def reply(self, status, data, html=False):
            body = data.encode('utf-8') if html else json.dumps(data, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', 'text/html; charset=utf-8' if html else 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Referrer-Policy', 'no-referrer')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'")
            self.end_headers()
            self.wfile.write(body)

        def trusted_host(self):
            return self.headers.get('Host') == f'127.0.0.1:{self.server.server_port}'

        def do_GET(self):
            if not self.trusted_host():
                return self.reply(403, {'error': 'Invalid host'})
            parsed = urlsplit(self.path)
            if parsed.path != '/callback':
                return self.reply(404, {'error': 'Not found'})
            query = parse_qs(parsed.query)
            try:
                spotify.exchange(query.get('state', [''])[0], query.get('code', [''])[0], 'error' in query)
                self.reply(200, '<meta charset="utf-8"><title>OKTAN • Spotify</title><body style="background:#101315;color:#d8fa99;font:20px system-ui;padding:60px">Spotify подключён. Вернись в OKTAN и выбери свой ПК через Devices.</body>', True)
            except BridgeError as error:
                self.reply(error.status, {'error': str(error)})

        def do_POST(self):
            supplied = self.headers.get('X-Oktan-Pair', '')
            if not self.trusted_host() or not secrets.compare_digest(supplied, spotify.pair) or self.headers.get('Origin'):
                return self.reply(403, {'error': 'Pairing required'})
            try:
                size = int(self.headers.get('Content-Length', '0'))
                if not 0 < size <= 4096:
                    raise ValueError()
                data = json.loads(self.rfile.read(size))
                if not isinstance(data, dict):
                    raise ValueError()
                with spotify.lock:
                    result = spotify.dispatch(urlsplit(self.path).path, data)
                self.reply(200, result)
            except (ValueError, TypeError):
                self.reply(400, {'error': 'Invalid request'})
            except BridgeError as error:
                self.reply(error.status, {'error': str(error), 'retry_after': error.retry_after})

    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--client-id', required=True)
    parser.add_argument('--workspace', type=Path, default=Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'Xeno' / 'workspace')
    args = parser.parse_args()
    try:
        spotify = Spotify(args.client_id)
    except ValueError as error:
        parser.error(str(error))
    args.workspace.mkdir(parents=True, exist_ok=True)
    pairing = args.workspace / 'Oktan-spotify-bridge.json'
    server = ThreadingHTTPServer(('127.0.0.1', PORT), handler_for(spotify))
    pairing.write_text(json.dumps({'url': f'http://127.0.0.1:{PORT}', 'token': spotify.pair}), encoding='utf-8')
    print('OKTAN Spotify: локальный модуль запущен. Окно не закрывай. Ctrl+C — остановка.')
    print('Redirect URI приложения:', REDIRECT)
    print('В клиенте: Settings → Music → Spotify → Connect. Авторизуйся сам в браузере.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        try:
            if json.loads(pairing.read_text(encoding='utf-8')).get('token') == spotify.pair:
                pairing.unlink()
        except (OSError, ValueError):
            pass
        spotify.access = spotify.refresh = None


if __name__ == '__main__':
    main()
