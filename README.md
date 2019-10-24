## Contributing

When making a change into toolbox, the following procedure is needed for review.

- Goto [core-docker-images](https://github.com/BitGo/core-docker-images) repo
- create a branch
- change `images/toolbox` submodule to PR branch
- push branch to build image
- verify image by pulling down locally and testing changes were successful
- get toolbox PR merged upon successful verification
- update `images/toolbox` submodule to point to updated commit hash in the `master` branch


