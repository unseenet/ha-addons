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

## Finding other nodes: nothing to do

A new node **peers by itself**. It announces itself in the network and pulls
from a few other announced nodes (`auto_peers`, 3 by default, chosen at random
and changed daily), so it gets the network's posts without anyone agreeing to
anything. Most operators never need to name a peer.

## Peering with particular nodes

Name a peer when you have agreed with another operator to exchange posts both
ways - a friend's node, your own second node, a node that carries a hierarchy
you care about. Each needs the other's **onion address** and **node key**
(both in the log). Under **peers** in the Configuration tab, add:

| Field | |
|---|---|
| `name` | Your label for the peer, used in the log. |
| `address` | The peer's onion address, e.g. `abc...xyz.onion` (port 119 unless you add one). |
| `key` | The peer's node key, `ed25519:...`. Needed for new peerings. |
| `groups` | Which groups to **send** to it, a [wildmat](#wildmats). Empty: everything. |
| `pull` | Which groups to **catch up on** from it. Empty: everything. |
| `accept` | Which groups to **take** from it, pushed or pulled. Empty: everything. |

The other operator adds your node the same way. In YAML mode:

```yaml
peers:
  - name: friend
    address: abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx.onion
    key: ed25519:bjhcf6tbf2yt37vn7iomsdg5o4xlvdvudjndnm4prrveiur3cukq
    groups: "dk.*"
```

Set `auto_peers` to 0 to exchange with your named peers only.

## Choosing what the node carries

You decide what your node stores and passes on. From the broadest to the
finest:

- **`carries`** - the hierarchies, e.g. only `alt.*` and `dk.*`. `*` is
  everything. The network's own groups (node lists, names, the project's
  groups) are always carried, so nobody can hide who carries what.
- **`excludes`** - groups you leave out within those, a wildmat such as
  `alt.binaries.*`. The node tells users what it leaves out.
- **`new_groups`** - `accept` new groups, only those whose owner is in
  `trusted_owners`, or `manual` (none).
- **Pictures and more** - `files` (pictures and small files in posts),
  `profile_pictures` (and `emoji` for groups' emoji), `sites`, `profiles`.
  Files, pictures and sites are off until you turn them on. Turning `files`
  on is recommended: without it users see missing pictures.
- **Per peer** - `groups`, `pull` and `accept` above.
- **Spam reports** - under `follow_reports`, name the issuers whose reports
  your node follows, and for each what it does: `posts` `hide` (kept, not
  served) or `delete`; `keys` `refuse` new posts, `surcharge` (more postage)
  or `ignore`. Your node follows nobody unless you name an issuer.

When you change what the node carries, it notices at the next start: it
forgets what it refused under the old setting and catches up with its peers.

### Wildmats

Comma-separated patterns; `!` leaves out, and the last match wins.
`*` is everything, `dk.*,unseenet*` is groups starting with `dk.` or
`unseenet`, `*,!alt.*` is everything except `alt.*`.

## All settings

Every setting of the node's `node.toml` is an option of the add-on. The
everyday ones are always shown; the rest appear when you turn on **Show unused
optional configuration options** at the bottom of the Configuration tab. An
option left out keeps the node's own default. The [configuration
reference](https://unseenet.org/node/configuration/) tells more about each.

| Option | Default | What it does |
|---|---|---|
| `node_name` | `ha-unseenet` | How the node introduces itself to its peers. |
| `passphrase` | | Seals the node's keys. |
| `auto_peers` | `3` | Pull from this many announced nodes too (0-16; 0 = only `peers`). |
| `peers` | none | Particular peers, see above. |
| `carries` | `*` | The hierarchies carried. |
| `announce` | on | Announce the node, so people and nodes can find it. |
| `retention_days` | `90` | How long posts are kept. |
| `files` | off | Carry pictures and small files in posts. |
| `profile_pictures` | off | Carry profile pictures. |
| `sites` | off | Carry sites of pages. |
| `follow_reports` | none | Spam-report issuers the node follows, see above. |
| `excludes` | | Groups left out, a wildmat. |
| `new_groups` | `accept` | `accept`, `trusted` or `manual`. |
| `trusted_owners` | | Owner keys whose new groups are accepted with `trusted`. |
| `profiles` | on | Carry identities' public profiles. |
| `emoji` | as `profile_pictures` | Carry groups' emoji. |
| `honour_blocks` | off | Refuse posts by identities a hierarchy's maintainer has blocked. |
| `fetch` | on | Fetch posts of groups not carried, when a user asks for them. |
| `min_pow` | `18` | The least postage (proof-of-work bits) a post must carry. |
| `min_ripe` | `0` | The lowest key-ripening level accepted, 0-4, or `-` for none. |
| `max_size` | `65536` | The largest post, 32768-65536 bytes. |
| `encrypted_files` | off | Also carry files of closed groups and private posts. |
| `files_max_size` | `1` | The largest file, 1-4 MiB. |
| `files_retention_days` | `30` | Files go after this; the post stays. |
| `files_groups` | `*` | Which groups' files are carried, a wildmat. |
| `files_daily_per_key` | `32` | MiB a day per author key. |
| `files_daily_per_group` | `256` | MiB a day per group. |
| `refusal_keys` | | Follow refusal lists of pictures and files by these keys. |
| `refusal_groups` | `*` | ... posted in these groups. |
| `ripen_to` | `1` | How far the node ripens its own key before announcing itself. |
| `pull_interval` | `3600` | Seconds between catch-up pulls from each peer. |
| `max_clients` | auto | The most client connections open at once. |
| `operator_key` | | Your identity key as the node's operator. |
| `operator_contact` | | The Group ID of your contact inbox. |
| `operator_description` | | A few words about the node, shown to users. |
| `operator_logging` | | What the node logs, shown to users. |
| `listen_internal` | off | Also listen on port 1119 of Home Assistant's internal add-on network, e.g. for a council replica beside it. No port is opened on your LAN. |
| `manage_config` | on | Write `node.toml` from these options at every start. Off: the add-on leaves `/data/node/node.toml` alone after the first start, for editing by hand. |

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
<https://github.com/unseenet/unseenet-haos-addons/issues>.
