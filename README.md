# Dockerized e2e Testing
This application aims to run e2e testing with headless protractor and the fake server of Selenium inside Docker container

### How to use this application?

1. Clone this repository
  ```sh
  ```
2. Have all e2e testing cases ready under **e2e/** (postfix like *.e2e-spec.ts)

3. Make sure the docker daemon is running!
  ```sh
  $ docker info
  ```

4. Add more testing cases to **e2e/**

5. Run **do_e2e.sh** under **scripts/**, which is going to build the image first if not exist and then spin up a container to run e2e testing
  ```sh
  $ ./scripts/do_e2e.sh -u <TARGET-WEBSITE> # ./scripts/do_e2e.sh -u https://github.com/
  ```

**Reference:**

[dumb-init](https://github.com/Yelp/dumb-init/releases)

[Docker (base command)](https://docs.docker.com/engine/reference/commandline/docker/)

[Chromium in Docker](https://github.com/mark-adams/docker-chromium-xvfb)