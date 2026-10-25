# Remote state in the bucket created by terraform/bootstrap. Native S3
# locking (use_lockfile) instead of a DynamoDB table — the dynamodb_table
# backend argument is deprecated as of Terraform ~1.10/1.11 in favor of this
# conditional-write-based locking directly in the state bucket.
terraform {
  backend "s3" {
    bucket       = "tft-devsecops-tfstate-921049725767"
    key          = "tft-devsecops/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
