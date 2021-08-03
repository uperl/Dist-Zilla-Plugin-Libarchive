# Dist::Zilla::Plugin::Libarchive ![static](https://github.com/uperl/Dist-Zilla-Plugin-Libarchive/workflows/static/badge.svg) ![linux](https://github.com/uperl/Dist-Zilla-Plugin-Libarchive/workflows/linux/badge.svg)

Create dist archives using Archive::Libarchive

# SYNOPSIS

In your `dist.ini`

```
[Libarchive]
```

# DESCRIPTION

This [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin overrides the built in archive builder and uses `libarchive` via [Archive::Libarchive](https://metacpan.org/pod/Archive::Libarchive)
instead.  It is different from the built in version in these ways:

- Predictable

    The built in behavior will sometimes use [Archive::Tar](https://metacpan.org/pod/Archive::Tar) or [Archive::Tar::Wrapper](https://metacpan.org/pod/Archive::Tar::Wrapper).  The problem with [Archive::Tar::Wrapper](https://metacpan.org/pod/Archive::Tar::Wrapper)
    is that it depends on the system implementation of tar, which in some cases can produce archives that are not readable by older
    implementations of tar.  In particular GNU tar which is typically the default on Linux systems includes unnecessary features that
    break tar on HP-UX.  (You should probably be getting off HP-UX if you are still using it in 2021 as I write this).

- Sorted by name

    The contents of the archive are sorted by name instead of being sorted by filename length.  While sorting by length makes for
    a pretty display when they are unpacked, I find it harder to find stuff when the content is listed.

- Additional formats

    Because `libarchive` supports a large number of formats, this plugin can be extended to support them as well.  Currently
    there is an interface to produce `.tar`, `.tar.gz` and `.zip`.  Other formats may be added in the future.

# PROPERTIES

## format

```
[Libarchive]
format = tar.gz
```

Sets the output format.  The default, most common and easiest to unpack for cpan clients is `tar.gz`.  You should consider
carefully before not using the default.  Supported formats:

- `tar.gz`
- `tar`
- `zip`

# SEE ALSO

- [Archive::Libarchive](https://metacpan.org/pod/Archive::Libarchive)
- [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)
- [Dist::Zilla::Plugin::ArchiveTar](https://metacpan.org/pod/Dist::Zilla::Plugin::ArchiveTar)
- [Dist::Zilla::Role::ArchiveBuilder](https://metacpan.org/pod/Dist::Zilla::Role::ArchiveBuilder)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
