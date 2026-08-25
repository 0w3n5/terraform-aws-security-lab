import argparse
import os
import sys

from botocore.exceptions import ClientError, BotoCoreError

from aws_utils import get_s3_client


def validate_file(file_path):
    """Validate that the requested local file exists and is readable."""

    if not os.path.exists(file_path):
        raise FileNotFoundError(
            f"File does not exist: {file_path}"
        )

    if not os.path.isfile(file_path):
        raise ValueError(
            f"Path is not a file: {file_path}"
        )

    if not os.access(file_path, os.R_OK):
        raise PermissionError(
            f"File cannot be read: {file_path}"
        )


def upload_file(file_path, bucket, object_key, kms_key_id):
    """Securely upload a local file to S3 using SSE-KMS."""

    validate_file(file_path)

    s3 = get_s3_client()

    try:
        s3.upload_file(
            Filename=file_path,
            Bucket=bucket,
            Key=object_key,
            ExtraArgs={
                "ServerSideEncryption": "aws:kms",
                "SSEKMSKeyId": kms_key_id,
            },
        )

        print("Upload successful.")
        print(f"Local file : {file_path}")
        print(f"S3 bucket  : {bucket}")
        print(f"S3 object  : {object_key}")
        print("Encryption : SSE-KMS")

    except ClientError as error:
        print(
            f"AWS error during upload: {error}",
            file=sys.stderr,
        )
        raise

    except BotoCoreError as error:
        print(
            f"Boto3 error during upload: {error}",
            file=sys.stderr,
        )
        raise


def main():
    parser = argparse.ArgumentParser(
        description="Securely upload a file to the S3 file drop."
    )

    parser.add_argument(
        "file",
        help="Path to the local file.",
    )

    parser.add_argument(
        "--bucket",
        required=True,
        help="Destination S3 bucket.",
    )

    parser.add_argument(
        "--key",
        required=True,
        help="Destination S3 object key.",
    )

    parser.add_argument(
        "--kms-key",
        required=True,
        help="KMS key ARN or ID used to encrypt the object.",
    )

    args = parser.parse_args()

    try:
        upload_file(
            file_path=args.file,
            bucket=args.bucket,
            object_key=args.key,
            kms_key_id=args.kms_key,
        )

    except (FileNotFoundError, PermissionError, ValueError) as error:
        print(f"Validation error: {error}", file=sys.stderr)
        sys.exit(1)

    except (ClientError, BotoCoreError, RuntimeError) as error:
        print(f"Upload failed: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()