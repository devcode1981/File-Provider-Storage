# Object Storage (LFS, Artifacts, etc)

GitLab Enterprise Edition has Object Storage integration. In this
document we explain how to set this up in your development
environment.

## minio Setup

1. Spin up minio container https://github.com/minio/minio

    ```sh
    docker pull minio/minio
    docker run -p 9000:9000 minio/minio server /data
    ```

1. Copy AccessKey and SecretKey printed in terminal to 'gitlab.yml' as described below

    ```sh
    AccessKey: XXXXXXXXXXXXXXX
    SecretKey: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    ```

1. Visit the console on http://127.0.0.1:9000
1. Create a new bucket from the right-bottom button. Bucket name is "artifacts".

## GDK Setup

1. Configure gitlab/config/gitlab.yml

    ```yml
    development:
      <<: *base
      ## Build Artifacts
      artifacts:
        enabled: true
        # The location where build artifacts are stored (default: shared/artifacts).
        # path: shared/artifacts
        object_store:
          enabled: true
          remote_directory: artifacts # The bucket name
          background_upload: true # Temporary option to limit automatic upload (Default: true)
          connection:
            provider: AWS # Only AWS supported at the moment
            aws_access_key_id: XXXXXXXXXXXXXXX # AccessKey 
            aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX # SecretKey 
            region: eu-central-1
            host: 'localhost'
            endpoint: 'http://127.0.0.1:9000'
            path_style: true
    ```

1. Run GDK
