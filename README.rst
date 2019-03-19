==========
Divingbell
==========

|Doc Status|

Introduction
============

Divingbell is a lightweight solution for:

1. Bare metal configuration management for a few very targeted use
cases via the following modules:

- *apparmor*
- *ethtool*
- *exec* (run arbitrary scripts)
- system *limits*
- *mounts*
- permissions (*perm*)
- *sysctl* values
- basic user account management (*uamlite*)

2. Bare metal package manager orchestration using *apt* module

What problems does it solve?
----------------------------

The needs identified for Divingbell were:

1. To plug gaps in day 1 tools (e.g., `Drydock`_) for node configuration
2. To provide a day 2 solution for managing these configurations going forward
3. [Future] To provide a day 2 solution for system level host patching

.. include-marker

Documentation
=============

Find more documentation for Divingbell on `Read the Docs`_.

Further Reading
===============

`Airship`_.

.. |Doc Status| image:: https://readthedocs.org/projects/airship-divingbell/badge/?version=latest
   :target: https://airship-divingbell.readthedocs.io/
   :alt: Documentation Status
.. _Read the Docs: https://airship-divingbell.readthedocs.io
.. _Drydock: https://airship-drydock.readthedocs.io
.. _Airship: https://www.airshipit.org
