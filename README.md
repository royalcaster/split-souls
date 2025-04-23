# Split Souls

## How to create a release

A GitHub action workflow is set up for automatic release creation. Whenever a commit with a version tag (e.g. v1.0.0) gets pushed, an executable build will be created.

To do this you have do 
* tag your commit
`git tag v<version>`

* then commit
`git commit`

* then push specific tag to remote repository
`git push origin v<version>`

`<version>` has to be replaced with a [semantic versioning](https://semver.org/) string like `1.0.0`