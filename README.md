# Drupal 7 pro docker

## About The Project

The goal is to set up fastly a local Drupal 7 project with docker environment for professional uses.

### Built With

* [Official Drupal Docker Image](https://hub.docker.com/_/drupal)
* [Official MySQL Docker Image](https://hub.docker.com/_/mysql)
* [Official Node Docker Image](https://hub.docker.com/_/node)
* [Official phpMyAdmin Docker Image](https://hub.docker.com/_/phpmyadmin)
* [Official traefik Docker Image](https://hub.docker.com/_/traefik)
* [Mailhog Docker Image](https://hub.docker.com/r/mailhog/mailhog)

## Getting Started

### Installation

   ```sh
   make create-setup <project> <repo-git>
   cd ../<project>-docker
   make copy-env-file
   # Fill env file
   make setup
   ```

### New project

   ```sh
   make create-init <project>
   cd ../<project>-docker
   make copy-env-file
   # Fill env file
   make init
   ```
