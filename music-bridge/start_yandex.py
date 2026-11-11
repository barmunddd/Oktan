"""Run with Python or double-click. Keeps a dedicated dependency environment."""
from pathlib import Path
import subprocess
import sys


def main():
    directory = Path(__file__).resolve().parent
    environment = directory.parent / 'work' / 'music-venv'
    executable = environment / 'Scripts' / 'python.exe'
    if sys.platform != 'win32' or sys.version_info < (3, 11):
        raise RuntimeError('Нужен Windows 10/11 и Python 3.11 или новее')
    if not executable.exists():
        subprocess.run([sys.executable, '-m', 'venv', str(environment)], check=True)
    check = subprocess.run([str(executable), '-c', 'import winrt.windows.media.control; import winrt.windows.foundation.collections'], capture_output=True)
    if check.returncode:
        subprocess.run([str(executable), '-m', 'pip', 'install', '-r', str(directory / 'requirements-yandex.txt')], check=True)
    subprocess.run([str(executable), '-X', 'utf8', str(directory / 'yandex_bridge.py'), *sys.argv[1:]], check=True)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
    except Exception as error:
        print('Не удалось запустить Яндекс Музыку:', error)
        input('Нажми Enter, чтобы закрыть окно…')
        raise SystemExit(1)
