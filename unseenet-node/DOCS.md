# Unseenet node

A node of [Unseenet](https://unseenet.org): it stores groups and exchanges them
with other nodes, like a Usenet server. Every node is a Tor onion service, so it
needs no public IP, no port forwarding and no domain - and nobody learns where
it is. Clients reach it over Tor too.

> **Pre-alpha.** Unseenet has not had a security review. Do not rely on it to
> protect anyone yet.

## First start

1. Set a **passphrase** of at least 12 characters in the Configuration tab. It
   seals the node's keys. Write it down somewhere safe: it cannot be recovered,
   and a node with a new passphrase is a new node.
2. Pick a **node name** - how the node introduces itself to peers.
3. Start the add-on and open its **Log**. You will see:

   ```
   [unseenet-node] node key: ed25519:...
   Node is reachable at ....onion
   ```

   The onion address comes once Tor is running - give it a minute or two the
   first time. These two are what other operators need to peer with you.

## Configuration

| Option | What it does |
|---|---|
| `node_name` | How the node introduces itself to its peers. |
| `passphrase` | Seals the node's keys (see above). |
| `peers` | Other nodes to exchange groups with: `name`, `address` (the peer's onion address), `key` (its node key, `ed25519:...`) and, if you like, `groups` (a wildmat such as `alt.*,dk.*`). |
| `carries` | The hierarchies this node carries, e.g. `*` for everything, or `alt.*` and `dk.*`. The network's own groups are carried whatever you choose. |
| `auto_peers` | Also exchange with this many nodes announced in the network (0-16; 0 = only `peers`). With this on, a new node needs no peers to get going. |
| `announce` | Tell the network about this node, so others can find it. |
| `retention_days` | How long posts are kept (90 is the default). |
| `min_pow` | The least proof-of-work postage a post must carry (18 is the network default). |
| `new_groups` | `accept` new groups, only from `trusted` owners, or `manual`. |
| `files` | Carry pictures and small files in posts (at most 1 MiB, kept 30 days). Recommended: without them users see missing pictures. |
| `encrypted_files` | Also carry files of closed groups and private posts. |
| `profile_pictures` | Carry profile pictures and groups' emoji. |
| `sites` | Carry small sites of pages. |
| `listen_internal` | Also listen on port 1119 of Home Assistant's internal add-on network, e.g. for a council replica beside it. No port is opened on your LAN. |
| `manage_config` | On (the default): `node.toml` is written from these options at every start. Off: the add-on leaves `/data/node/node.toml` alone after the first start, so you can edit it by hand ([all settings](https://unseenet.org/node/configuration/)); the options above are then ignored. |

An example of a peer, in YAML mode:

```yaml
peers:
  - name: friend
    address: abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx.onion
    key: ed25519:bjhcf6tbf2yt37vn7iomsdg5o4xlvdvudjndnm4prrveiur3cukq
```

## The monitor

The node comes with `unseenet-monitor`, a terminal view of traffic, peers and
Tor. Home Assistant gives add-ons no shell of their own, so reach it from the
**Advanced SSH & Web Terminal** add-on (with *Protection mode* off in its Info
tab):

```
docker exec -it addon_<id>_unseenet_node unseenet-monitor
```

`docker ps` shows the full container name. A Home Assistant integration with
sensors for the node is planned (unseenet/unseenet#24).

## Where your data is, and backups

Everything the node keeps is in the add-on's own data folder (`/data/node`):
its keys (sealed with your passphrase), its posts and `node.toml`. It is part
of Home Assistant's backups; the add-on is stopped while a backup is made, so
the database is consistent.

Be aware that Home Assistant stores add-on options - **including the
passphrase** - in plain text in the add-on's folder and in its backups. The
keys stay sealed, but the passphrase sits beside them, so keep your backups
**encrypted** (Home Assistant's default) and do not hand them to anyone.
Inside the add-on, only root reads the options; the node runs as its own user
and is handed the passphrase in a file in memory.

Restore a node's backup on one machine at a time: two copies of a node with
one key confuse its peers.

## What running a node means

A node carries what others post, and you are its operator. Read
[the node guide](https://unseenet.org/guide/node/) for what an operator can
and cannot see, and [your responsibility](https://unseenet.org/node/responsibility/).
The node reaches everyone over Tor, so your home IP address is not revealed;
your internet provider can see that you use Tor.

## Help

Ask in the group `unseenet.help` on the network, or open an issue at
<https://github.com/unseenet/ha-addons/issues>.
