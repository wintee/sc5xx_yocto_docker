# sc5xx_yocto_docker
Docker image for building ADSP-SC5xx Yocto Linux

## Building the image
To build the image:
  docker build --tag \<image name> .

To run the image and build the Linux components:
  docker run -u bob -v `pwd`/docker_artefacts:/linux/build/tmp/deploy/images \<image name> ./buildOnDocker.sh -r **repo** -b -**branch** -m **machine** [-gu \<github user> -gp \<github password>][-f \<manifest file>][-mu \<mirror url>][-mr] **bitbake_args**

  Where **machine** is one of sc594-som-ezit sc589-mini sc589-ezkit sc584-ezkit sc573-ezkit and bitbake_args are the bitbake commands to execute. **repo** is the https address of the manifest containing username and password (or personal access token) in the form https://username:personalaccesstoken@github.com/username/reponame.git. If -mu is provided with a mirror url then it will build from that local mirror and throw an error if trying to fetch sources from anywhere else. Use the -mr switch for building a mirror (bitbake args should be given as "adsp-sc5xx-full --runonly=fetch").
