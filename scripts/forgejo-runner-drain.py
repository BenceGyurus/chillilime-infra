#!/usr/bin/env python3
"""Pause new assignments using runner Declare, then wait for existing jobs.

Run on the dedicated runner VM. Never print connection credentials. A successful
--wait leaves maintenance labels in place until the daemon is restarted. Failure
restores normal labels so the existing runner cannot remain accidentally drained.
"""
import argparse
import json
from pathlib import Path
import subprocess
import signal
import time
from urllib.request import Request, urlopen
import yaml


def declare(connection, labels):
    request = Request(connection['url'].rstrip('/') + '/api/actions/runner.v1.RunnerService/Declare',
        data=json.dumps({'version': 'v13.2.0', 'labels': labels}).encode(),
        headers={'Content-Type': 'application/json', 'Connect-Protocol-Version': '1',
                 'x-runner-uuid': connection['uuid'], 'x-runner-token': connection['token']})
    with urlopen(request, timeout=30) as response:
        result = json.load(response)
    actual = result.get('runner', {}).get('labels', [])
    if actual != labels:
        raise RuntimeError('Server did not accept the requested runner labels')


def running_jobs():
    output = subprocess.check_output(['docker', 'ps', '--format', '{{.Names}}'], text=True)
    return [name for name in output.splitlines() if name != 'forgejo-runner-runner-1']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='/opt/forgejo-runner/config.yml')
    parser.add_argument('--timeout', type=int, default=21600)
    parser.add_argument('--restore', action='store_true')
    args = parser.parse_args()
    def interrupted(signum, frame):
        raise KeyboardInterrupt("Drain interrupted by signal")
    signal.signal(signal.SIGTERM, interrupted)
    config = yaml.safe_load(Path(args.config).read_text())
    connections = config['server']['connections']
    labels = [label.split(':', 1)[0] for label in config['runner']['labels']]
    if args.restore:
        for connection in connections.values():
            declare(connection, labels)
        print('Runner labels restored', flush=True)
        return
    success = False
    try:
        for connection in connections.values():
            declare(connection, ['maintenance-draining'])
        print('New assignments paused; existing jobs keep running', flush=True)
        deadline = time.monotonic() + args.timeout
        # Allow any fetch already in flight to create its job container.
        time.sleep(10)
        while True:
            busy = running_jobs()
            if not busy:
                time.sleep(5)
                if not running_jobs():
                    success = True
                    print('Runner drained: no active job/service containers', flush=True)
                    return
            if time.monotonic() >= deadline:
                raise TimeoutError('Runner did not drain before timeout')
            print(f'Waiting for {len(busy)} active job/service containers', flush=True)
            time.sleep(20)
    finally:
        if not success:
            for connection in connections.values():
                declare(connection, labels)
            print('Drain interrupted; original runner labels restored', flush=True)


if __name__ == '__main__':
    main()
