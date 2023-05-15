======
 What
======

The *Letterspace* module for ConTeXt MkIV allows for defining letterspacing
macros.

==============
 Installation
==============

Copy the program tree into your local ConTeXt tree, i.e. if you have the
minimals installed inside ``$HOME/context/``, issue the following command from
the module root: ::

    cp -r tex/ ~/context/tex/texmf-local/

Optionally do the same for the documentation tree: ::

    cp -r doc/ ~/context/tex/texmf-local/

Next, update the ConTeXt filename database so that the module can be found: ::

    context --generate

Congratulations, the *Letterspace* module is now ready to use. As a test, chdir
into the documentation directory and build the manual: ::

    cd doc/context/third/letterspace/
    context letterspace.tex

===============
 Documentation
===============

If you don’t want to build the documentation yourself, there should always be an
uptodate version at the BitBucket repository_.


=====
 Who
=====

Written by Philipp Gesang, Heidelberg.
Email me (``megas.kapaneus`` at ``gmail`` dot ``com``)
or file a tracker item at BitBucket_ if something doesn’t seem right.

=========
 License
=========

The *Letterspace* module is licensed under the terms of the BSD license with two
clauses. See the file ``COPYING`` or the *License* chapter in the manual for
details.

.. _repository: https://bitbucket.org/phg/t-letterspace/downloads
.. _BitBucket:  https://bitbucket.org/phg/t-letterspace
