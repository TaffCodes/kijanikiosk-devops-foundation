# IAM Least Privilege Design

## Use Case: Application Image Uploads
The KijaniKiosk web application needs to upload and read product images stored in an S3 bucket named `kijanikiosk-product-images-prod`.

## Security Reasoning
Instead of granting the application broad `s3:*` access, we map a dedicated IAM Role to the application's compute instances. This policy strictly limits actions to `PutObject` and `GetObject` on a specific resource ARN. If the application is compromised, the attacker cannot delete the bucket or access other company data.

## IAM Policy Document (JSON)
```json
{
  "Version": "2026-09-26",
  "Statement": [
    {
      "Sid": "AllowAppToReadWriteProductImages",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::kijanikiosk-product-images-prod/images/*"
    }
  ]
}
