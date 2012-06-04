Homebrew-old
============
Based on [Homebrew/homebrew-versions][orig] these formulae provide older
versions of certain packages.

How do I install these formulae?
--------------------------------
Just `brew tap ilikepi/old` and then `brew install <formula>`.

If the formula conflicts with one from mxcl/master or another tap, you
can `brew install ilikepi/old/<formula>`.

You can also install via URL:

```
brew install https://raw.github.com/ilikepi/homebrew-old/master/<formula>.rb
```

Known Issues
------------
* The mysql50 formula is known not to compile on Lion
* The postgresql84 formula does not have the latest patch release of 8.4
* The postgis14 formula is a work-in-progress and as of yet untested

Docs
----
`brew help`, `man brew`, or the Homebrew [wiki][].

[wiki]:http://wiki.github.com/mxcl/homebrew
[orig]:https://github.com/Homebrew/homebrew-versions

