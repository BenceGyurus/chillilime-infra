## Frist run

```sh
python -m venv .venv
```

activate on macos and linux

```sh
source .venv/bin/activate
```

```sh
pip install -r requirements.txt
```

## Run specific playbook

For example run loadbalancer:

```sh
ansible-playbook loadbalancer/*.yml -i host_vars
```