# Unseenet council replica

A replica of an Unseenet **council registrar**
([UN-RFC 0054](https://unseenet.org/spec/un-rfc-0054/)). The lists that hold the
network together - names, known nodes, hierarchies - are kept by councils of
several keys, so that no single key, not even the project's, can take the
network over or stop it. Each member runs a replica: it reads the claims,
decides them by public rules, and signs what it decided. Replicas run by
different people on different machines are what make a council hard to stop.

> **Experimental, and pre-alpha.** The replica image is first published with
> Unseenet 0.7.0; until then this add-on cannot be installed. Unseenet has not
> had a security review.

## How a replica joins

You need no one's permission to start. A new replica begins as a **shadow**:
it decides every claim the way the council does and posts what it decided,
once a day. Its key ripens in the background (weeks on a small machine). Once
it has agreed with the council for 60 days and its key is ripe, the members'
replicas admit it; 180 days later it is a full member. See
[the replica guide](https://unseenet.org/replica/).

## First start

1. Set a **passphrase** of at least 12 characters. It seals the replica's key.
   Write it down somewhere safe: it cannot be recovered, and a new key is a new
   replica that must start over as a shadow.
2. Optionally name **nodes** (see below), then start the add-on.
3. The log shows the replica's key. Nobody learns who runs it: it reaches the
   network over Tor, like any client.

## Configuration

| Option | What it does |
|---|---|
| `passphrase` | Seals the replica's key (see above). |
| `nodes` | Nodes the replica reads and posts through - onion addresses, or a node add-on beside it (below). Empty: the network's known nodes. Name more than one, so that no single node can hide claims from your replica. |
| `hold` | Changes to the council that wait until you agree: `admission`, `promotion`, `removal`, `proposal`. Empty: the replica follows the rules alone. |
| `group` | The council registrar's group - **first start only**. Leave it empty for the network's name registrar. |

`nodes` and `hold` are applied at every start; `group` is the replica's for good.

### Beside the Unseenet node add-on

Running the node add-on on the same machine? Turn on **Open to other add-ons**
(`listen_internal`) there, and give the node's hostname with port 1119 here,
e.g. `a0d7b954-unseenet-node:1119` - the node add-on's Info tab shows its
hostname. Add other nodes' onion addresses too. The replica's posts then leave
through your node, so whoever watches that node could link the two.

## Commands

Home Assistant gives add-ons no shell of their own, so use the **Advanced SSH &
Web Terminal** add-on (with *Protection mode* off) and `docker exec`:

```
docker exec addon_<id>_unseenet_replica unseenet-replica status
docker exec addon_<id>_unseenet_replica unseenet-replica agree removal:ed25519:...
```

`status` tells in plain words how the replica is doing and what is held for you.
`docker ps` shows the full container name.

## One replica, one copy

The add-on's data folder (`/data/replica`) **is** the replica: its vault, key,
settings and state. Two replicas running with one key can split the council,
and the replica stops signing when it sees that (UN-RFC 0054 section 7).

- Never restore a backup of this add-on on a second machine while the first
  one runs. Stop and remove it on the old machine first.
- The add-on is stopped while Home Assistant makes a backup, so the copy is
  consistent.

Home Assistant stores add-on options - **including the passphrase** - in plain
text in the add-on's folder and in its backups, so keep your backups
**encrypted** (Home Assistant's default). Inside the add-on only root reads the
options; the replica runs as its own user and is handed the passphrase in a
file in memory.

## Help

Ask in the group `unseenet.help` on the network, or open an issue at
<https://github.com/unseenet/ha-addons/issues>.
