import argparse
import os
import sys

from botocore.exceptions import ClientError, BotoCoreError

from aws_utils import get_s3_client


def validate_destination(destination):
    """Validate that the destination can be written to."""

    parent_directory = os.path.dirname(
        os.path.abspath(destination)
    )

    if not os.path.exists(parent_directory):
        raise FileNotFoundError(
            f"Destination directory does not exist: "
            f"{parent_directory}"
        )

    if os.path.exists(destination):
        raise FileExistsError(
            f"Destination file already exists: {destination}"
        )

    if not os.access(parent_directory, os.W_OK):
        raise PermissionError(
            f"Destination directory is not writable: "
            f"{parent_directory}"
        )


def download_file(bucket, object_key, destination):
    """
    Download an S3 object only if it is encrypted with SSE-KMS.
    """

    validate_destination(destination)

    s3 = get_s3_client()

    try:
        # Check the object before downloading it.
        metadata = s3.head_object(
            Bucket=bucket,
            Key=object_key,
        )

        encryption = metadata.get(
            "ServerSideEncryption"
        )

        if encryption != "aws:kms":
            raise RuntimeError(
                "Download refused: object is not using "
                f"SSE-KMS. Detected encryption: {encryption}"
            )

        s3.download_file(
            Bucket=bucket,
            Key=object_key,
            Filename=destination,
        )

        print("Download successful.")
        print(f"S3 object  : s3://{bucket}/{object_key}")
        print(f"Local file : {destination}")
        print("Encryption : SSE-KMS")

    except ClientError as error:
        print(
            f"AWS error during download: {error}",
            file=sys.stderr,
        )
        raise

    except BotoCoreError as error:
        print(
            f"Boto3 error during download: {error}",
            file=sys.stderr,
        )
        raise


def main():
    parser = argparse.ArgumentParser(
        description="Securely download an SSE-KMS encrypted S3 object."
    )

    parser.add_argument(
        "--bucket",
        required=True,
        help="Source S3 bucket.",
    )

    parser.add_argument(
        "--key",
        required=True,
        help="S3 object key.",
    )

    parser.add_argument(
        "--output",
        required=True,
        help="Local destination path.",
    )

    args = parser.parse_args()

    try:
        download_file(
            bucket=args.bucket,
            object_key=args.key,
            destination=args.output,
        )

    except (
        FileNotFoundError,
        FileExistsError,
        PermissionError,
        RuntimeError,
    ) as error:
        print(
            f"Validation/security error: {error}",
            file=sys.stderr,
        )
        sys.exit(1)

    except (ClientError, BotoCoreError) as error:
        print(
            f"Download failed: {error}",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()