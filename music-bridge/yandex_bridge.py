"""Yandex Music app controller via Windows media sessions. No account tokens."""
import argparse
import asyncio
from concurrent.futures import TimeoutError as FutureTimeout
import json
import os
from pathlib import Path
import secrets
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlencode, urlsplit

PORT = 8975


class MediaError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.status = status


def is_yandex(source):
    name = str(source).casefold().replace(' ', '').replace('.', '').replace('-', '').replace('_', '')
    return 'yandexmusic' in name or 'яндексмузыка' in name


class WindowsMedia:
    def __init__(self, manager=None):
        self.manager = manager

    async def sessions(self):
        if self.manager is None:
            # Explicit imports register await/collection projections for PyWinRT.
            import winrt.windows.foundation
            import winrt.windows.foundation.collections
            from winrt.windows.media.control import GlobalSystemMediaTransportControlsSessionManager
            self.manager = await GlobalSystemMediaTransportControlsSessionManager.request_async()
        return [s for s in self.manager.get_sessions() if is_yandex(s.source_app_user_model_id)]

    async def select(self, source=None):
        sessions = await self.sessions()
        if source:
            sessions = [s for s in sessions if s.source_app_user_model_id == source]
        if not sessions:
            raise MediaError('Открой Яндекс Музыку, включи трек один раз и нажми Connect', 404)
        if len(sessions) != 1:
            raise MediaError('Открыто несколько плееров Яндекс Музыки. Оставь один', 409)
        return sessions[0]

    async def status(self):
        session = await self.select()
        properties = await session.try_get_media_properties_async()
        playback = session.get_playback_info()
        controls = playback.controls
        timeline = session.get_timeline_properties()
        return {'connected': True, 'source': session.source_app_user_model_id,
                'title': str(properties.title or '')[:200], 'artist': str(properties.artist or '')[:200],
                'playing': int(playback.playback_status) == 4,
                'position_ms': max(0, int(timeline.position.total_seconds() * 1000)),
                'controls': {name: bool(getattr(controls, 'is_' + name + '_enabled', False))
                             for name in ('play', 'pause', 'stop', 'next', 'previous', 'playback_position')}}

    async def control(self, action, source):
        session = await self.select(source)
        playback = session.get_playback_info()
        method = {'play': 'play', 'pause': 'pause', 'next': 'skip_next', 'previous': 'skip_previous', 'stop': 'stop'}.get(action)
        if not method:
            raise MediaError('Неизвестное действие')
        controls = playback.controls
        control_name = {'next': 'next', 'previous': 'previous'}.get(action, action)
        note = ''
        if action == 'stop' and not getattr(controls, 'is_stop_enabled', False):
            if not controls.is_pause_enabled or not await session.try_pause_async():
                raise MediaError('Приложение не поддерживает остановку сейчас', 409)
            reset = controls.is_playback_position_enabled and await session.try_change_playback_position_async(0)
            note = 'Остановлено • позиция сброшена' if reset else 'Пауза • приложение не разрешило сброс позиции'
        else:
            if not getattr(controls, 'is_' + control_name + '_enabled', False):
                raise MediaError('Эта команда сейчас недоступна в приложении', 409)
            if not await getattr(session, 'try_' + method + '_async')():
                raise MediaError('Яндекс Музыка не приняла команду. Проверь приложение', 409)
        return {'ok': True, 'message': note or {'play': 'Играет', 'pause': 'Пауза', 'stop': 'Остановлено', 'next': 'Следующий трек', 'previous': 'Предыдущий трек'}[action]}


class LocalBridge:
    def __init__(self, media=None):
        self.pair = secrets.token_urlsafe(32)
        self.media = media or WindowsMedia()
        self.loop = asyncio.new_event_loop()
        self.worker = threading.Thread(target=self.loop.run_forever, daemon=True)
        self.worker.start()
        self.lock = threading.RLock()

    def run(self, coroutine):
        future = asyncio.run_coroutine_threadsafe(coroutine, self.loop)
        try:
            return future.result(timeout=10)
        except FutureTimeout:
            future.cancel()
            raise MediaError('Windows не ответила плееру. Попробуй Connect ещё раз', 504) from None
        except MediaError:
            raise
        except ImportError:
            raise MediaError('Установи зависимости из requirements-yandex.txt', 503) from None
        except Exception:
            raise MediaError('Не удалось прочитать плеер Windows. Перезапусти локальный модуль', 503) from None

    def dispatch(self, path, data):
        with self.lock:
            if path in ('/connect', '/status'):
                return self.run(self.media.status())
            if path == '/control':
                source = data.get('source')
                if not isinstance(source, str) or not is_yandex(source) or len(source) > 500:
                    raise MediaError('Нажми Connect для выбора Яндекс Музыки')
                return self.run(self.media.control(data.get('action'), source))
            if path == '/search':
                term = data.get('query')
                if not isinstance(term, str) or not 1 <= len(term.strip()) <= 150:
                    raise MediaError('Введи исполнителя или трек')
                return {'url': 'https://music.yandex.ru/search?' + urlencode({'text': term.strip()}),
                        'message': 'Результаты поиска открываются в Яндекс Музыке'}
            raise MediaError('Неизвестный запрос', 404)

    def close(self):
        async def cancel_pending():
            tasks = [task for task in asyncio.all_tasks() if task is not asyncio.current_task()]
            for task in tasks:
                task.cancel()
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)
        try:
            asyncio.run_coroutine_threadsafe(cancel_pending(), self.loop).result(timeout=3)
        finally:
            self.loop.call_soon_threadsafe(self.loop.stop)
            self.worker.join(timeout=3)
            if not self.worker.is_alive():
                self.loop.close()


def handler_for(bridge):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def reply(self, status, data):
            body = json.dumps(data, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            self.reply(405, {'error': 'Use paired POST'})

        def do_POST(self):
            if self.headers.get('Host') != f'127.0.0.1:{self.server.server_port}' or self.headers.get('Origin') or not secrets.compare_digest(self.headers.get('X-Oktan-Pair', ''), bridge.pair):
                return self.reply(403, {'error': 'Pairing required'})
            try:
                size = int(self.headers.get('Content-Length', '0'))
                if not 0 < size <= 4096:
                    raise ValueError()
                data = json.loads(self.rfile.read(size))
                if not isinstance(data, dict):
                    raise ValueError()
                self.reply(200, bridge.dispatch(urlsplit(self.path).path, data))
            except (ValueError, TypeError):
                self.reply(400, {'error': 'Invalid request'})
            except MediaError as error:
                self.reply(error.status, {'error': str(error)})
    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', type=Path, default=Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'Xeno' / 'workspace')
    parser.add_argument('--probe', action='store_true', help='Read-only Windows media-session check; no server or playback changes')
    args = parser.parse_args()
    bridge = LocalBridge()
    if args.probe:
        try:
            print(json.dumps(bridge.dispatch('/status', {}), ensure_ascii=False))
        except MediaError as error:
            print(json.dumps({'error': str(error)}, ensure_ascii=False))
        finally:
            bridge.close()
        return
    server = None
    pairing = args.workspace / 'Oktan-yandex-bridge.json'
    try:
        server = ThreadingHTTPServer(('127.0.0.1', PORT), handler_for(bridge))
        args.workspace.mkdir(parents=True, exist_ok=True)
        pairing.write_text(json.dumps({'url': f'http://127.0.0.1:{PORT}', 'token': bridge.pair}), encoding='utf-8')
        print('OKTAN • Яндекс Музыка: модуль запущен. В клиенте Music → Yandex Music → Connect.', flush=True)
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        if server:
            server.server_close()
        bridge.close()
        try:
            if json.loads(pairing.read_text(encoding='utf-8')).get('token') == bridge.pair:
                pairing.unlink()
        except (OSError, ValueError):
            pass


if __name__ == '__main__':
    main()
