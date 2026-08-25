import argparse
import json
import sys
from datetime import datetime, timezone

from botocore.exceptions import ClientError, BotoCoreError

from aws_utils import get_s3_client


def result(check, status, details):
    """Create a standard audit result."""

    return {
        "check": check,
        "status": status,
        "details": details,
    }


def check_bucket_exists(s3, bucket):
    """Check whether the S3 bucket exists and is accessible."""

    try:
        s3.head_bucket(Bucket=bucket)

        return result(
            "Bucket Exists",
            "PASS",
            "Bucket exists and is accessible.",
        )

    except ClientError as error:
        return result(
            "Bucket Exists",
            "FAIL",
            str(error),
        )


def check_encryption(s3, bucket):
    """Verify that default bucket encryption uses SSE-KMS."""

    try:
        response = s3.get_bucket_encryption(
            Bucket=bucket
        )

        rules = response[
            "ServerSideEncryptionConfiguration"
        ]["Rules"]

        for rule in rules:
            default = rule.get(
                "ApplyServerSideEncryptionByDefault",
                {},
            )

            algorithm = default.get("SSEAlgorithm")
            kms_key = default.get("KMSMasterKeyID")

            if algorithm == "aws:kms":
                return result(
                    "SSE-KMS Encryption",
                    "PASS",
                    f"Bucket uses SSE-KMS. KMS key: {kms_key}",
                )

        return result(
            "SSE-KMS Encryption",
            "FAIL",
            "Bucket does not use SSE-KMS.",
        )

    except ClientError as error:
        return result(
            "SSE-KMS Encryption",
            "FAIL",
            str(error),
        )


def check_public_access(s3, bucket):
    """Verify all S3 public access block settings."""

    try:
        response = s3.get_public_access_block(
            Bucket=bucket
        )

        config = response[
            "PublicAccessBlockConfiguration"
        ]

        required_controls = [
            "BlockPublicAcls",
            "IgnorePublicAcls",
            "BlockPublicPolicy",
            "RestrictPublicBuckets",
        ]

        failed_controls = [
            control
            for control in required_controls
            if not config.get(control, False)
        ]

        if not failed_controls:
            return result(
                "Public Access Block",
                "PASS",
                "All public access block controls are enabled.",
            )

        return result(
            "Public Access Block",
            "FAIL",
            "Disabled controls: "
            + ", ".join(failed_controls),
        )

    except ClientError as error:
        return result(
            "Public Access Block",
            "FAIL",
            str(error),
        )


def check_ownership(s3, bucket):
    """Verify BucketOwnerEnforced object ownership."""

    try:
        response = s3.get_bucket_ownership_controls(
            Bucket=bucket
        )

        rules = response[
            "OwnershipControls"
        ]["Rules"]

        ownership = rules[0]["ObjectOwnership"]

        if ownership == "BucketOwnerEnforced":
            return result(
                "Object Ownership",
                "PASS",
                "BucketOwnerEnforced is enabled.",
            )

        return result(
            "Object Ownership",
            "FAIL",
            f"Object ownership is {ownership}.",
        )

    except ClientError as error:
        return result(
            "Object Ownership",
            "FAIL",
            str(error),
        )


def check_versioning(s3, bucket):
    """Verify S3 versioning is enabled."""

    try:
        response = s3.get_bucket_versioning(
            Bucket=bucket
        )

        status = response.get("Status")

        if status == "Enabled":
            return result(
                "Versioning",
                "PASS",
                "Bucket versioning is enabled.",
            )

        return result(
            "Versioning",
            "FAIL",
            f"Versioning status: {status}",
        )

    except ClientError as error:
        return result(
            "Versioning",
            "FAIL",
            str(error),
        )


def check_bucket_policy(s3, bucket):
    """Verify a bucket policy exists."""

    try:
        response = s3.get_bucket_policy(
            Bucket=bucket
        )

        policy = response.get("Policy")

        if policy:
            return result(
                "Bucket Policy",
                "PASS",
                "Bucket policy is configured.",
            )

        return result(
            "Bucket Policy",
            "FAIL",
            "Bucket policy is empty.",
        )

    except ClientError as error:
        return result(
            "Bucket Policy",
            "FAIL",
            str(error),
        )


def check_logging(s3, bucket):
    """Verify S3 server access logging is enabled."""

    try:
        response = s3.get_bucket_logging(
            Bucket=bucket
        )

        logging_enabled = response.get(
            "LoggingEnabled"
        )

        if logging_enabled:
            target = logging_enabled.get(
                "TargetBucket"
            )
            prefix = logging_enabled.get(
                "TargetPrefix",
                "",
            )

            return result(
                "Access Logging",
                "PASS",
                f"Logs delivered to {target} "
                f"with prefix '{prefix}'.",
            )

        return result(
            "Access Logging",
            "FAIL",
            "S3 access logging is not enabled.",
        )

    except ClientError as error:
        return result(
            "Access Logging",
            "FAIL",
            str(error),
        )


def check_lifecycle(s3, bucket):
    """Verify that a lifecycle configuration exists."""

    try:
        response = s3.get_bucket_lifecycle_configuration(
            Bucket=bucket
        )

        rules = response.get("Rules", [])

        enabled_rules = [
            rule
            for rule in rules
            if rule.get("Status") == "Enabled"
        ]

        if enabled_rules:
            return result(
                "Lifecycle Configuration",
                "PASS",
                f"{len(enabled_rules)} enabled lifecycle rule(s) found.",
            )

        return result(
            "Lifecycle Configuration",
            "FAIL",
            "No enabled lifecycle rules found.",
        )

    except ClientError as error:
        return result(
            "Lifecycle Configuration",
            "FAIL",
            str(error),
        )


def audit_bucket(bucket):
    """Run all S3 security checks."""

    s3 = get_s3_client()

    checks = [
        check_bucket_exists,
        check_encryption,
        check_public_access,
        check_ownership,
        check_versioning,
        check_bucket_policy,
        check_logging,
        check_lifecycle,
    ]

    results = []

    for check in checks:
        results.append(check(s3, bucket))

    return results


def save_results(bucket, results, output_file):
    """Save audit results as structured JSON."""

    report = {
        "bucket": bucket,
        "generated_at": datetime.now(
            timezone.utc
        ).isoformat(),
        "results": results,
    }

    with open(
        output_file,
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            report,
            file,
            indent=4,
        )


def main():
    parser = argparse.ArgumentParser(
        description="Audit the security configuration of an S3 bucket."
    )

    parser.add_argument(
        "--bucket",
        required=True,
        help="S3 bucket to audit.",
    )

    parser.add_argument(
        "--output",
        default="audit_results.json",
        help="JSON output file.",
    )

    args = parser.parse_args()

    try:
        results = audit_bucket(
            args.bucket
        )

        save_results(
            args.bucket,
            results,
            args.output,
        )

        print(
            f"\nS3 Security Audit: {args.bucket}\n"
        )

        for item in results:
            print(
                f"[{item['status']}] "
                f"{item['check']}: "
                f"{item['details']}"
            )

        passed = sum(
            item["status"] == "PASS"
            for item in results
        )

        failed = sum(
            item["status"] == "FAIL"
            for item in results
        )

        print("\nSummary")
        print("-------")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"Total : {len(results)}")

        print(
            f"\nResults saved to: {args.output}"
        )

        # Exit with failure if a security control failed.
        if failed > 0:
            sys.exit(2)

    except (
        ClientError,
        BotoCoreError,
        RuntimeError,
    ) as error:
        print(
            f"Audit failed: {error}",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()