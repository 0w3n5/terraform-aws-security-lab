import boto3


def get_s3_client():
    """
    Create an S3 client using the standard AWS credential chain.

    Credentials can therefore come from:
    - AWS CLI configuration
    - Environment variables
    - IAM roles
    - EC2 instance profiles
    - Other supported AWS credential providers
    """

    session = boto3.Session()

    if session.get_credentials() is None:
        raise RuntimeError(
            "No AWS credentials were found. "
            "Configure AWS credentials before running this script."
        )

    return session.client("s3")