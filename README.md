# sc5xx_yocto_docker
Docker image for building ADSP-SC5xx Yocto Linux

## Building the image
To build the image:
  docker build --tag <tagname> .

To run the image and build the Linux components:
  docker run -u bob -v `pwd`/docker_artefacts:/linux/build/tmp/deploy/images <tagname> ./buildOnDocker.sh -r **repo** -b -**branch** -m **machine** **bitbake_args**

  Where machine is one of sc594-som-ezit sc589-sam sc589-ezkit sc584-ezkit sc573-ezkit and bitbake_args are the bitbake commands to execute
