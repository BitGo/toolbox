Make sure to follow the following steps when merging:

1. Review must be approved by someone other than author
2. Merge must be done by someone other than author
3. Merge must be done with a signed commit using the command line

To review, sign, and merge securely on the CLI do:

```
git pull
git checkout master
git diff master origin/this-branch-name
git merge --no-ff origin/this-branch-name
git push origin master
```
