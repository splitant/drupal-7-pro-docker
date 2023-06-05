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
   git clone git@github.com:splitant/drupal-7-pro-docker.git
   cd drupal-7-pro-docker
   make create-setup <project> <repo-git>
   # Fill env file
   make setup
   ```

### New project

   ```sh
   git clone git@github.com:splitant/drupal-7-pro-docker.git
   cd drupal-7-pro-docker
   make create-init <project>
   # Fill env file
   make init
   ```
