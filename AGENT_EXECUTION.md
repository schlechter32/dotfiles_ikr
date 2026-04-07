## Execution Policy

This environment does not allow direct remote execution from the coding agent.

You must use the brokered `job` tool for Cobra host work.

Allowed commands:
- `job run test`
- `job run lint`
- `job run train -- <command...>`
- `job run eval -- <command...>`
- `job status`
- `job tail`
- `job cancel`
- `job hosts`

Forbidden commands:
- `ssh`
- `scp`
- `sftp`
- `rsync`
- `gpu-run`
- `ish`
- `lab`

Allowed hosts:
- `cobra0`
- `cobra1`
- `cobra2`
- `cobra3`
- `cobra4`

Typical workflow:

```bash
job hosts
job run test --host cobra2
job status
job tail
```

For training or eval, pass the explicit command after `--`:

```bash
job run train --host cobra3 -- python train.py --config configs/base.yaml
```
