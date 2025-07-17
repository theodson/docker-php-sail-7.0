# Laravel Sail Php 7.0 - `php-sail-7.0`

- Based on [Laravel Sail Docker 8.0](https://github.com/laravel/sail/blob/v1.38.0/runtimes/8.0/Dockerfile) image
- Specifically uses the last ubuntu:20.04 Sail build release 1.38.0 - https://github.com/laravel/sail/tree/v1.38.0
- Modified to use Php 7.0

This image is not directly compatible with Laravel Sail.

An image is available at [Docker Hub - theodson/php-sail-7.0](https://hub.docker.com/r/theodson/php-sail-7.0/tags)

> !! As of 2025-07-01 Ubuntu 20 and Php ppa_ondrej Repo have reached EOL and been archived. 
> It is no longer viable to build this Docker image. You should use the Image at Docker Hub.
> 

This was published using the following commands
```bash
# Authenticate for your DockerHub account
docker login

# Prepare and Tag local image for the DockerHub repository.
docker tag php-sail-7.0 theodson/php-sail-7.0:1.0

# Push to Docker Hub
docker push theodson/php-sail-7.0:1.0
```
