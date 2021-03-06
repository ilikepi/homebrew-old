Homebrew-old
============
Based on [Homebrew/homebrew-versions][orig] these formulae provide older
versions of certain packages.

How do I install these formulae?
--------------------------------
Just `brew tap ilikepi/old` and then `brew install <formula>`.

If the formula conflicts with one from Homebrew/homebrew-core or another tap,
you can `brew install ilikepi/old/<formula>`.

You can also install via URL:

```
brew install https://raw.github.com/ilikepi/homebrew-old/master/<formula>.rb
```

Known Issues
------------
* The postgresql@8.4 formula does not have the latest patch release of 8.4
* The postgis@1.4 formula is a work-in-progress and as of yet untested

Docs
----
`brew help`, `man brew`, or the Homebrew [documentation][docs].

[docs]:https://docs.brew.sh
[orig]:https://github.com/Homebrew/homebrew-versions

