# Git Approval

A git-centric approach to code approvals.

## Rationale

The rational behind this project is to remove the busywork from approving changes in large repos.

Most code approval tools are using unstable identifiers (refs, commits, pull-requests or merge-requests) in order to deal with approvals, which and fundamentally unstable — rewriting the tree will inevitable invalidate the approval.

## Problem

Code needs to be peer-reviewed in order to be SOC2 compliant, which prohibits a single developer to have enough access to merge code into a repository delivery pipeline (i.e. main branches)

## Approach

This is an attempt at evidence based approvals, where code authors are able to vet changes as _approved_ with the following guarantees:

- It is impossible to tamper the evidence given from a developer
- Tree rewrites proof
- File-level granularity (iterative approvals)

In order to achieve this, we are using the git internal `blob` objects in order to craft `approvals` manifests, which are then (potentially signed) stored as `notes`.

The result of this process is that automated tooling can use the aggregate content of these `approvals` objects to figure out if all the changes are present in the changeset (i.e. a list of commits, a branch, a pull-requests) have been approved, and by whom.

## Implementation

These are notes for myself, so read at your own risk.

### Git commands lexicon

git diff-tree: create the changeset manifest
git hash-object: write raw objects

### Manifest format


```
# This is the oid of the ref target when `diff-tree` is given a single ref, should
probably be omitted from the manifest so that it stays stable.
eda5b0d8bf277751b95c429d7b1a9a584794005b 
# should probably remove most of the crap here, as we are only interested about
# <attr> <blob-oid> <op> <path>
:000000 100644 0000000000000000000000000000000000000000 a454c9f908c18d98ea17ccd5c2f442e3f7f6f970 A  .envrc
:000000 100644 0000000000000000000000000000000000000000 f0c23d110b6576782e295afa8796e2904c796a83 A  1.txt
:000000 100644 0000000000000000000000000000000000000000 64df8ba8d1045abfb2994921166711178c8158fb A  2.txt
:000000 100644 0000000000000000000000000000000000000000 3d7d1a2e4c010b2a1c3e77e9db493bf2969c8759 A  3.txt
:000000 040000 0000000000000000000000000000000000000000 444439a62c746aaa3f64f05fe0bbc15109d3b5d5 A  scripts
```

It seems like `git diff-tree <refspec> | cut -d' ' -f2,4,5,6'` should do the trick.

Further investigation could be used for a additive `git diff --format=<…>` instead.
Data like `committer`, or `author` could be useful for auditing purpose.


#### Storage

As a git extension using a specific `notes` ref for this seems ideal: `refs/notes/approvals`

```
GIT_NOTES_REFS=refs/notes/approvals
GIT_NOTES_DISPLAY_REFS=refs/notes/*
```

#### Merge strategy

See git config `notes.mergeStrategy`

Git provides a way to merge notes, and `cat_sort_uniq` seems to be the best option, as it will remove any duplicates from the list.

It is unclear right now if one should use a single approval per changeset, multiple, or if the client tool should deal with this merge internally.

Regardless, there is most likely a way for git to merge the notes for the easier comsuption.

### Commands

#### git approve <commit> <refspec>

This command creates a note at HEAD

1) Create the manifest, write it to repo 
2) Create a note for the approval, with potentially a nice message (why not)
3) Attach the manifest object to the note
4) Attach the note to the <commit>, or HEAD


