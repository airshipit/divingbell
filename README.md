Divingbell
==========

What is it?
-----------

Divingbell is a lightweight solution for:
1. Bare metal configuration management for a few very targeted use cases
2. Bare metal package manager orchestration

What problems does it solve?
----------------------------

The needs identified for Divingbell were:
1. To plug gaps in day 1 tools (e.g., drydock) for node configuration
2. To provide a day 2 solution for managing these configurations going forward
3. [Future] To provide a day 2 solution for system level host patching

Design and Implementation
-------------------------

Divingbell daemonsets run as priviledged containers which mount the host
filesystem and chroot into that filesystem to enforce configuration and package
state. (The [diving bell](http://bit.ly/2hSXlai) analogue can be thought of as something that descends
into the deeps to facilitate work done down below the surface.)

We use the daemonset construct as a way of getting a copy of each pod on every
node, but the work done by this chart's pods behaves like an event-driven job.
In practice this means that the chart internals run once on pod startup,
followed by an infinite sleep such that the pods always report a "Running"
status that k8s recognizes as the healthy (expected) result for a daemonset.

In order to keep configuration as isolated as possible from other systems that
manage common files like /etc/fstab and /etc/sysctl.conf, Divingbell daemonsets
manage all of their configuration in separate files (e.g. by writing unique
files to /etc/sysctl.d or defining unique Systemd units) to avoid potential
conflicts.

To maximize robustness and utility, the daemonsets in this chart are made to be
idempotent. In addition, they are designed to implicitly restore the original
system state after previously defined states are undefined. (e.g., removing a
previously defined mount from the yaml manifest, with no record of the original
mount in the updated manifest).

Lifecycle management
--------------------

This chart's daemonsets will be spawned by Armada. They run in an event-driven
fashion: the idempotent automation for each daemonset will only re-run when
Armada spawns/respawns the container, or if information relevant to the host
changes in the configmap.

For upgrades, a decision was taken not to use any of the built-in kubernetes
update strategies such as RollingUpdate. Instead, we are putting this on
Armada to handle the orchestration of how to do upgrades (e.g., rack by rack).

Daemonset configs
-----------------

### sysctl ###

Used to manage host level sysctl tunables. Ex:

``` yaml
conf:
  sysctl:
    net/ipv4/ip_forward: 1
    net/ipv6/conf/all/forwarding: 1
```

### mounts ###

used to manage host level mounts (outside of those in /etc/fstab). Ex:

``` yaml
conf:
  mounts:
    mnt:
      mnt_tgt: /mnt
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=1024M'
```

### ethtool ###

Used to manage host level NIC tunables. Ex:

``` yaml
conf:
  ethtool:
    ens3:
      tx-tcp-segmentation: off
      tx-checksum-ip-generic: on
```

### packages ###

Not implemented

### users ###

Not implemented

Node specific configurations
----------------------------

Although we expect these deamonsets to run indiscriminately on all nodes in the
infrastructure, we also expect that different nodes will need to be given a
different set of data depending on the node role/function. This chart supports
establishing value overrides for nodes with specific label value pairs and for
targeting nodes with specific hostnames. The overrided configuration is merged
with the normal config data, with the override data taking precedence.

The chart will then generate one daemonset for each host and label override, in
addition to a default daemonset for which no overrides are applied.
Each daemonset generated will also exclude from its scheduling criteria all
other hosts and labels defined in other overrides for the same daemonset, to
ensure that there is no overlap of daemonsets (i.e., one and only one daemonset
of a given type for each node).

Overrides example with sysctl daemonset:

``` yaml
conf:
  sysctl:
    net.ipv4.ip_forward: 1
    net.ipv6.conf.all.forwarding: 1
    fs.file-max: 9999
  overrides:
    divingbell-sysctl:
      labels:
      - label:
          key: compute_type
          values:
          - "dpdk"
          - "sriov"
        conf:
          sysctl:
            net.ipv4.ip_forward: 0
      - label:
          key: another_label
          values:
          - "another_value"
        conf:
          sysctl:
            net.ipv6.conf.all.forwarding: 0
      hosts:
      - name: superhost
        conf:
          sysctl:
            net.ipv4.ip_forward: 0
            fs.file-max: 12345
      - name: superhost2
        conf:
          sysctl:
            fs.file-max: 23456
```

Caveats:
1. For a given node, at most one override operation applies. If a node meets
override criteria for both a label and a host, then the host overrides take
precedence and are used for that node. The label overrides are not used in this
case. This is especially important to note if you are defining new host
overrides for a node that is already consuming matching label overrides, as
defining a host override would make those label overrides no longer apply.
2. Daemonsets are generated regardless of the current state of the environment.
Ex: If your environment consists of a single node that matches a host override,
the chart will still generate a default daemonset which would fail to schedule
in this example. Likewise if the host or label in the override return no
candidates, these would also fail to schedule.

Recorded Demo
-------------

A recorded demo of using divingbell can be found [here](https://asciinema.org/a/beJQZpRPdOctowW0Lxkxrhz17).


